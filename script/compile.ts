import { $, type BuildArtifact } from "bun";
import elmConfig from "../elm.json";
import { cpSync, watch } from "fs";
import { readdirSync } from "fs";
import * as Path from "path";

const backendJs = Path.join("tmp", "backend.js")
const backendMjs = Path.join("tmp", "backend.mjs")
const frontendJs = Path.join("tmp", "frontend.js")
const tmpFrontend = Path.join("tmp", "frontend")
const dist = "dist"
const frontendEntrypoint = "frontend.ts"
const backendEntrypoint = "backend.ts"

if (!elmConfig["source-directories"] || !Array.isArray(elmConfig["source-directories"]))
    crash("Error: 'source-directories' not found or not an array in elm.json");

if (elmConfig["source-directories"].length === 0)
    crash("Warning: 'source-directories' in elm.json is empty");

console.log("Using Elm source directories:", elmConfig["source-directories"].join(", "));

const isDebug = process.argv.includes("--debug");
const isDev = process.argv.includes("--dev");


//Build Function

async function runBuild() {

    console.log(`Starting${isDebug ? " debug " : " "}build...`);

    try {

        await $`rm -fr tmp dist`
        await $`mkdir -p tmp/frontend/ dist/`
        await $`cp public/* dist`

        for (const dir of elmConfig["source-directories"]) {

            const toCopy: string[] =

                readdirSync(dir, { recursive: true }) as string[]

            for (const file of toCopy) {
                const filePath = Path.join(dir, file)
                const fd = Bun.file(filePath)
                const stat = await fd.stat()
                if (!stat.isFile() || !file.endsWith(".elm")) continue

                let src = await fd.text()

                if (src.startsWith("module View exposing")) {
                    src = newView
                } else {
                    src = src
                        .replace("import Html.String as Html", "import Html")
                        .replace("import Html.String.Events", "import Html.Events")
                        .replace("import Html.String.Attributes", "import Html.Attributes")
                }

                await Bun.write(Path.join(tmpFrontend, filePath), src)
            }
        }

        delete elmConfig.dependencies.direct["zwilias/elm-html-string"]

        await Bun.write("tmp/frontend/elm.json", JSON.stringify(elmConfig, null, 4))


        if (isDebug) {
            await $`elm make src/Frontend.elm --debug --output=../frontend.js`.cwd("tmp/frontend");
        } else {
            await $`bun run elm-optimize-level-2 make src/Frontend.elm --optimize-speed --output=../frontend.js`.cwd("tmp/frontend");
        }

        const frontendRawSource: string =
            await Bun.file(frontendJs).text()

        await Bun.write("tmp/frontend.mjs", toEsModule(frontendRawSource))

        const buildOutput = await Bun.build({
            entrypoints: [frontendEntrypoint],
            outdir: dist,
            minify: !isDebug,
            naming: '[dir]/[name]-[hash].[ext]',
        })

        const fileName: string =
            Path.basename(
                (buildOutput.outputs[0] as BuildArtifact).path
            )


        // Compile Elm


        if (isDebug) {
            await $`elm make src/Backend.elm --debug --output=${backendJs}`;
        } else {
            await $`bun run elm-optimize-level-2 make src/Backend.elm --optimize-speed --output=${backendJs}`;
        }

        // Transform to ES Module

        const rawSource: string =
            await Bun.file(backendJs).text();

        await Bun.write(backendMjs, toEsModule(rawSource));

        // Build the worker

        const _ = await Bun.build({
            entrypoints: [backendEntrypoint],
            outdir: "functions",
            naming: '[dir]/[[[main]].js',
            external: ["cloudflare:workers"],
            minify: !isDebug,
            define: { FRONTEND_MODULE: JSON.stringify(fileName) }
        })


    } catch (error) {

        console.log(error)

        // In dev mode, we log the error but don't exit the process, so watching can continue.

        if (!isDev) process.exit(1)
    }
}

// ES Module Transformation

function toEsModule(source: string): string {
    const matches: string[] | null = source.match(
        /^\s*_Platform_export\(([^]*)\);\n?}\(this\)\);/m
    );

    if (matches === null) {
        crash("Failed to transform to ES Module: _Platform_export pattern not found. Elm output might have changed or be empty.");
    }
    if (!(1 in matches)) {
        crash(`Failed to transform to ES Module: _Platform_export pattern matched, but capture group is missing. Matches found: ${matches.length}`);
    }

    const elmExports: string = matches[1];

    // Replace specific patterns to make it an ES module
    const result: string = source
        .replace(/\(function\s*\(scope\)\s*\{$/m, "// -- $& (Original IIFE start)")
        .replace(/['"]use strict['"];$/m, "// -- $& (Original 'use strict')")
        .replace(/function _Platform_export([^]*?)\}\n/g, "/* -- Commented out original _Platform_export --\n$&\n*/")
        .replace(/function _Platform_mergeExports([^]*?)\}\n\s*}/g, "/* -- Commented out original _Platform_mergeExports --\n$&\n*/")
        .replace(/^\s*_Platform_export\(([^]*)\);\n?}\(this\)\);/m, "/* -- Commented out original _Platform_export call --\n$&\n*/")
        .concat(`\n// --- Exported Elm App --- \nexport const Elm = ${elmExports};\n`);

    return result;
}

// --- Helper Functions ---

function crash(message: string): never {
    Bun.write(Bun.stderr, `\nCritical Error: ${message}\n`);
    process.exit(1);
}

// --- Main Execution Logic ---

async function main() {
    if (isDev) {
        console.log("Running in Development Mode.");
        console.log("An initial build will be performed.");

        // Perform an initial build
        await runBuild();

        // Watch for file changes in specified Elm source directories
        console.log("Starting file watcher for directories:", elmConfig["source-directories"].join(", "));

        let buildTimeout: Timer | null = null; // For debouncing

        for (const dir of elmConfig["source-directories"]) {
            try {
                const watcher = watch(dir, { recursive: true }, (eventType, filename) => {
                    // filename might be null or not the exact file path on some systems/events
                    const changedPath = filename ? `${dir}/${filename}` : dir;
                    console.log(`[${new Date().toLocaleTimeString()}] Detected ${eventType} in ${changedPath}`);

                    // Debounce the build function
                    if (buildTimeout) {
                        clearTimeout(buildTimeout);
                    }
                    buildTimeout = setTimeout(async () => {
                        console.log("Change detected. Rebuilding...");
                        await runBuild();
                        // If your dev server needs a signal to reload, send it here.
                        // e.g., if using WebSockets for live reload.
                    }, 300); // 300ms debounce window
                });

                watcher.on('error', (error) => {
                    console.error(`Error watching directory ${dir}:`, error);
                });
                console.log(`Successfully watching directory: ${dir}`);

            } catch (watchError) {
                console.error(`Failed to initialize watcher for directory ${dir}:`, watchError);
                // Depending on severity, you might want to crash or just warn
                // crash(`Could not watch directory: ${dir}. ${watchError.message}`);
            }
        }
        console.log("File watching is active. Press Ctrl+C to stop.");
        // In dev mode, the process will stay alive due to active watchers
        // and any running dev server.

    } else {
        console.log("Running in Production/Build Mode.");
        await runBuild();
        console.log("Build complete. Exiting.");
    }
}

// Start the script
main().catch(err => {
    console.error("Unhandled error during script execution:", err);
    process.exit(1);
});


const newView: string =
    `module View exposing (..)

import Browser exposing (Document)
import Html exposing (Html)
import Status exposing (Status)


type alias View msg =
    { title : String
    , status : Status
    , body : List (Html msg)
    }


map : (a -> b) -> View a -> View b
map f view =
    { title = view.title
    , status = view.status
    , body = List.map (Html.map f) view.body
    }


toDocument : View msg -> Document msg
toDocument view =
    { title = view.title
    , body = view.body 
    }
`
