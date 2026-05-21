// YaruNavi proxy worker
// - POST  /             : Anthropic API への中継 (既存)
// - POST  /redeem-code  : VIP コード検証 → 一致なら version 返却
// - GET   /vip-version  : 現在の VIP code version
//
// 必要な KV bindings (wrangler.toml):
//   - RATE_LIMIT     : レート制限 (1 分単位)
//   - VIP_CONFIG     : code_current (current code) + code_version (int)
//
// 必要な vars:
//   - APP_TOKEN          : クライアントが送る X-App-Token
//   - ANTHROPIC_API_KEY  : Anthropic API key (secret)

const RATE_LIMIT_CHAT = 10; // チャット: 1 分 10 回
const RATE_LIMIT_VIP = 5; // VIP redeem: 1 端末 1 分 5 回

async function applyRateLimit(env, key, limit) {
  let count = 0;
  try {
    const stored = await env.RATE_LIMIT.get(key);
    count = stored ? parseInt(stored) : 0;
  } catch (_) {
    return true; // KV 未設定時は許可
  }
  if (count >= limit) return false;
  try {
    await env.RATE_LIMIT.put(key, String(count + 1), { expirationTtl: 60 });
  } catch (_) {}
  return true;
}

function jsonResponse(status, body) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

async function handleRedeemCode(request, env) {
  const appToken = request.headers.get("X-App-Token");
  if (appToken !== env.APP_TOKEN) {
    return new Response("Unauthorized", { status: 401 });
  }
  let body;
  try {
    body = await request.json();
  } catch (_) {
    return jsonResponse(400, { error: "Invalid JSON" });
  }
  const code = body.code;
  const deviceId = body.device_id;
  if (!code || !deviceId) {
    return jsonResponse(400, { error: "code と device_id は必須" });
  }
  // 端末単位レート制限
  const rateKey = `vip:${deviceId}`;
  const ok = await applyRateLimit(env, rateKey, RATE_LIMIT_VIP);
  if (!ok) {
    return jsonResponse(429, { error: "Rate limit exceeded" });
  }
  // 現在のコード取得
  let current = null;
  let version = 0;
  try {
    current = await env.VIP_CONFIG.get("code_current");
    const v = await env.VIP_CONFIG.get("code_version");
    version = v ? parseInt(v) : 0;
  } catch (_) {
    return jsonResponse(500, { error: "VIP_CONFIG 未設定" });
  }
  if (current && code === current) {
    return jsonResponse(200, { valid: true, version });
  }
  return jsonResponse(200, { valid: false });
}

async function handleVipVersion(env) {
  // KV 未バインド時は意図せず version=0 を返さない。 200 で 0 を返すと
  // Flutter 側 (本来 version>=1 で VIP 有効) が「世代不一致」と誤判定し
  // VIP を剥奪してしまうため、 明示的に 500 を返す。
  if (!env.VIP_CONFIG) {
    return jsonResponse(500, { error: "VIP_CONFIG not bound" });
  }
  try {
    const v = await env.VIP_CONFIG.get("code_version");
    const version = v ? parseInt(v) : 0;
    if (!version) {
      return jsonResponse(500, { error: "code_version not set" });
    }
    return jsonResponse(200, { version });
  } catch (_) {
    return jsonResponse(500, { error: "VIP_CONFIG read failed" });
  }
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // VIP エンドポイント
    if (url.pathname === "/redeem-code" && request.method === "POST") {
      return handleRedeemCode(request, env);
    }
    if (url.pathname === "/vip-version" && request.method === "GET") {
      return handleVipVersion(env);
    }

    // 既存の Anthropic 中継 (POST /)
    if (request.method !== "POST") {
      return new Response("Method not allowed", { status: 405 });
    }

    const appToken = request.headers.get("X-App-Token");
    if (appToken !== env.APP_TOKEN) {
      return new Response("Unauthorized", { status: 401 });
    }

    const clientIP = request.headers.get("CF-Connecting-IP");
    const ok = await applyRateLimit(env, `rate:${clientIP}`, RATE_LIMIT_CHAT);
    if (!ok) {
      return jsonResponse(429, { error: "Rate limit exceeded" });
    }

    let body;
    try {
      body = await request.json();
    } catch (e) {
      return jsonResponse(400, { error: "Invalid JSON" });
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
      headers: { "Content-Type": "application/json" },
    });
  },
};
