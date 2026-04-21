export default {
  async fetch(request, env) {
    if (request.method !== "POST") {
      return new Response("Method not allowed", { status: 405 });
    }

    const appToken = request.headers.get("X-App-Token");
    if (appToken !== env.APP_TOKEN) {
      return new Response("Unauthorized", { status: 401 });
    }

    const clientIP = request.headers.get("CF-Connecting-IP");
    const rateLimitKey = `rate:${clientIP}`;
    let currentCount = 0;
    try {
      const stored = await env.RATE_LIMIT.get(rateLimitKey);
      currentCount = stored ? parseInt(stored) : 0;
    } catch (e) {
      // KV未設定時は制限なし
    }
    if (currentCount >= 10) {
      return new Response(JSON.stringify({ error: "Rate limit exceeded" }), {
        status: 429,
        headers: { "Content-Type": "application/json" },
      });
    }
    try {
      await env.RATE_LIMIT.put(rateLimitKey, String(currentCount + 1), {
        expirationTtl: 60,
      });
    } catch (e) {
      // KV書き込み失敗は無視
    }

    let body;
    try {
      body = await request.json();
    } catch (e) {
      return new Response(JSON.stringify({ error: "Invalid JSON" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    body.model = "claude-haiku-4-5-20251001";
    if (!body.max_tokens || body.max_tokens > 4096) {
      body.max_tokens = 4096;
    }

    const anthropicResponse = await fetch(
      "https://api.anthropic.com/v1/messages",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-api-key": env.ANTHROPIC_API_KEY,
          "anthropic-version": "2023-06-01",
        },
        body: JSON.stringify(body),
      }
    );

    const responseBody = await anthropicResponse.text();

    return new Response(responseBody, {
      status: anthropicResponse.status,
      headers: {
        "Content-Type": "application/json",
      },
    });
  },
};
