// Cloudflare Worker "cheatsheet-proxy"
// Route: ai.lifehacker.tw/claude-code-cheatsheet-zh*  (zone lifehacker.tw)
// Serves the GitHub Pages build under ai.lifehacker.tw so search equity goes to the main site.
// GitHub Pages stays the single source of truth; the weekly upstream sync needs no changes.
// The github.io copy carries <meta http-equiv="refresh"> pointing here; this Worker strips it
// so the proxied page does not redirect to itself.

const ORIGIN = "https://raymondhou0917.github.io";
const BASE = "/claude-code-cheatsheet-zh";

export default {
  async fetch(request) {
    const url = new URL(request.url);

    if (url.pathname === BASE) {
      return Response.redirect(`${url.origin}${BASE}/${url.search}`, 301);
    }
    if (request.method !== "GET" && request.method !== "HEAD") {
      return new Response("Method Not Allowed", { status: 405, headers: { Allow: "GET, HEAD" } });
    }

    const target = new URL(url.pathname + url.search, ORIGIN);
    const upstream = await fetch(target.toString(), {
      method: request.method,
      redirect: "manual",
      cf: { cacheTtl: 300, cacheEverything: true },
    });

    if ([301, 302, 307, 308].includes(upstream.status)) {
      const location = upstream.headers.get("Location");
      if (location) {
        const next = new URL(location, target);
        if (next.origin === ORIGIN && next.pathname.startsWith(BASE)) {
          const headers = new Headers(upstream.headers);
          headers.set("Location", next.pathname + next.search);
          return new Response(null, { status: upstream.status, headers });
        }
      }
      return upstream;
    }

    const headers = new Headers(upstream.headers);
    const response = new Response(upstream.body, { status: upstream.status, headers });
    if (!(headers.get("Content-Type") || "").includes("text/html")) {
      return response;
    }
    return new HTMLRewriter()
      .on('meta[http-equiv="refresh"]', { element(el) { el.remove(); } })
      .transform(response);
  },
};
