# YaruNavi API Proxy

Cloudflare Workerでホストするプロキシサーバー。
Anthropic APIキーをアプリに埋め込まずに安全にAI機能を提供する。

## セットアップ手順

1. npm install
2. npx wrangler login
3. npx wrangler kv:namespace create "RATE_LIMIT"
   → 表示されたIDをwrangler.tomlに記入
4. npx wrangler secret put ANTHROPIC_API_KEY
   → Anthropic APIキーを入力
5. npx wrangler secret put APP_TOKEN
   → ランダム文字列を入力（openssl rand -hex 32）
6. npx wrangler deploy
   → 表示されたURLをメモ

## テスト
npx wrangler dev
