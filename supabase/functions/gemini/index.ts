// Gemini proxy — keeps GEMINI_API_KEY server-side.
//
// The Flutter app calls this instead of generativelanguage.googleapis.com, so
// the billable API key never ships inside the APK. Gemini's JSON response is
// passed through untouched; the client parses it exactly as before.
//
// Deploy:
//   supabase secrets set GEMINI_API_KEY=<your key>
//   supabase functions deploy gemini
//
// Then set GEMINI_PROXY_URL in the app's .env to the deployed function URL:
//   https://<project-ref>.supabase.co/functions/v1/gemini
//
// JWT verification is on by default, so callers must present the Supabase anon
// key — which is what GeminiClient sends.

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");

// Only allow models this app actually uses, so a caller can't redirect the
// key at an arbitrary (or more expensive) endpoint.
const ALLOWED_MODELS = new Set(["gemini-2.5-flash"]);

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }
  if (!GEMINI_API_KEY) {
    console.error("GEMINI_API_KEY secret is not set on this project.");
    return json({ error: "Server is not configured for Gemini." }, 500);
  }

  let model: string;
  let payload: unknown;
  try {
    const body = await req.json();
    model = typeof body?.model === "string" ? body.model : "";
    payload = body?.payload;
  } catch {
    return json({ error: "Request body must be JSON." }, 400);
  }

  if (!ALLOWED_MODELS.has(model)) {
    return json({ error: `Unsupported model: ${model}` }, 400);
  }
  if (payload === null || typeof payload !== "object") {
    return json({ error: "Missing 'payload' object." }, 400);
  }

  const upstream = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": GEMINI_API_KEY,
      },
      body: JSON.stringify(payload),
    },
  );

  // Pass Gemini's response straight through, status included, so the client's
  // existing error handling keeps working.
  const text = await upstream.text();
  return new Response(text, {
    status: upstream.status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
});
