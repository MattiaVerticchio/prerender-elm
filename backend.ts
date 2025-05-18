import { Elm } from './tmp/backend.mjs';
import { WorkerEntrypoint } from "cloudflare:workers";

export default class extends WorkerEntrypoint {
    async fetch(request: Request): Promise<Response> {

        let bodyContent: string | null = null;
        if (request.body) {
            try {
                // Example: Assuming text body. Adjust if it's JSON, etc.
                bodyContent = await request.text();
            } catch (e) {
                console.error("Failed to read request body:", e);
                return new Response("Failed to read request body", { status: 400 });
            }
        }

        const flags = {
            time: Date.now(),
            method: request.method,
            body: bodyContent, // Use the read body content
            url: request.url,
            headers: Object.fromEntries(request.headers.entries()),
            elmJs: FRONTEND_MODULE,
        };


        // Promise logic remains the same
        return new Promise((resolve, reject) => {
            try {
                const app = Elm.Backend.init({ flags });

                app.ports.sendResponse.subscribe((resp: { document: string, init: ResponseInit }) => {

                    // <html lang="it"><head>${resp.head}${FRONTEND_MODULE}</head><body>${resp.body}</body></html>

                    const response =
                        new Response(resp.document, resp.init);

                    resolve(response)

                });

            } catch (error) {
                console.error("Failed to initialize Elm application:", error);
                reject(new Response("Server error during initialization", { status: 500 }));
            }
        });
    }
}



