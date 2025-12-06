# Eigo Browser API

Cloudflare Workers で動作する API サーバー

## セットアップ

```bash
cd backend
npm install
```

## ローカル開発

1. `.dev.vars` に Groq API キーを設定:
```
GROQ_API_KEY=your_actual_api_key
```

2. 開発サーバー起動:
```bash
npm run dev
```

## デプロイ

1. Cloudflare にログイン:
```bash
npx wrangler login
```

2. シークレットを設定:
```bash
npx wrangler secret put GROQ_API_KEY
```

3. デプロイ:
```bash
npm run deploy
```

## API エンドポイント

### POST /

**リクエストボディ:**

```json
{
  "text": "Hello world",
  "type": "explain" | "dictionary" | "chat",
  "messages": [...]  // chat の場合のみ
}
```

**レスポンス:**

```json
{
  "result": "解説テキスト..."
}
```
