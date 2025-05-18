import { Elm } from './tmp/frontend.mjs';

document.addEventListener('DOMContentLoaded', () => {
    const node = document.body;
    const dataScriptTag = document.getElementById('injected-data');
    let flags = null

    if (dataScriptTag) {
        try {
            flags = JSON.parse(dataScriptTag.textContent);
        } catch (error) {
            console.error("Failed to parse injected data:", error);
        }
    } else {
        console.error("Injected data script tag not found.");
    }

    if (node) {
        const app =
            Elm.Frontend.init({ node: node, flags: flags })
    } else {
        console.error("Could not find the body node to mount the Elm application.");
    }
});
