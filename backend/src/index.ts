/**
 * 🌐 Eigo Browser API - Cloudflare Workers
 * 📌 目的: Groq APIへのプロキシ（APIキーを隠蔽）
 */

export interface Env {
  GROQ_API_KEY: string;
  API_SECRET_KEY: string;  // 🔐 アプリ認証用シークレットキー
}

// 📝 リクエストボディの型定義
interface ExplainRequest {
  text: string;
  type: 'explain' | 'dictionary' | 'chat';
  messages?: ChatMessage[];
}

interface ChatMessage {
  content: string;
  isUser: boolean;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    // 🔒 CORSヘッダー
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, X-API-Key',
    };

    // 🔐 シークレットキー検証
    const apiKey = request.headers.get('X-API-Key');
    if (apiKey !== env.API_SECRET_KEY) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // プリフライトリクエスト対応
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    // POSTのみ受け付け
    if (request.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), {
        status: 405,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    try {
      const body: ExplainRequest = await request.json();
      const { text, type, messages } = body;

      if (!text && type !== 'chat') {
        return new Response(JSON.stringify({ error: 'text is required' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      let result: string;

      switch (type) {
        case 'explain':
          result = await explainText(text, env.GROQ_API_KEY);
          break;
        case 'dictionary':
          result = await getDictionaryInfo(text, env.GROQ_API_KEY);
          break;
        case 'chat':
          if (!messages) {
            return new Response(JSON.stringify({ error: 'messages required for chat' }), {
              status: 400,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            });
          }
          result = await chat(messages, env.GROQ_API_KEY);
          break;
        default:
          return new Response(JSON.stringify({ error: 'Invalid type' }), {
            status: 400,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
      }

      return new Response(JSON.stringify({ result }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    } catch (error) {
      console.error('Error:', error);
      return new Response(JSON.stringify({ error: 'Internal server error' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
  },
};

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🤖 AI解説を取得
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
async function explainText(text: string, apiKey: string): Promise<string> {
  const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'llama-3.3-70b-versatile',
      messages: [
        {
          role: 'system',
          content: `あなたは英語学習をサポートする優しい先生です。
ユーザーが英語のテキスト（単語、フレーズ、または文章）を送ってきます。

## 単語・短いフレーズの場合:(目安: 約1-3語)
【意味】日本語訳
【ポイント】文法や表現のポイント
【語源・由来】なぜこの意味なのか（納得できる説明）

## 長い文章の場合:
まず文を「意味のかたまり（チャンク）」に分割して、読み方を教えてください。
【文の分割】
英文を / で区切って、各チャンクの下に日本語訳を書く

【部分的な意味】
各チャンクごとの詳しい意味（なぜその訳になるのかも説明）

【ポイント】文法や表現のポイント（1-2文）`,
        },
        { role: 'user', content: text },
      ],
      max_tokens: 1000,
      temperature: 0.3,
    }),
  });

  const data = await response.json() as any;
  return data.choices?.[0]?.message?.content || 'Error';
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📚 辞書情報を取得
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
async function getDictionaryInfo(word: string, apiKey: string): Promise<string> {
  const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'llama-3.1-8b-instant',
      messages: [
        {
          role: 'system',
          content: `あなたは英和辞典です。
ユーザーが英単語を送ってきます。辞書形式で簡潔に回答してください。

フォーマット:
【品詞】名詞/動詞/形容詞など
【意味】① 最も一般的な意味 ② 他の意味（あれば）
【例文】短い英語例文（日本語訳付き）`,
        },
        { role: 'user', content: word },
      ],
      max_tokens: 150,
      temperature: 0.2,
    }),
  });

  const data = await response.json() as any;
  return data.choices?.[0]?.message?.content || 'Error';
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 💬 チャット
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
async function chat(messages: ChatMessage[], apiKey: string): Promise<string> {
  const apiMessages = [
    {
      role: 'system',
      content: `あなたは英語学習をサポートする優しい先生です。
ユーザーが英語について質問してきます。

- 質問には簡潔かつ分かりやすく回答してください
- 必要に応じて例文を出してください
- 文法用語は使いすぎず、初学者にもわかるように説明してください`,
    },
    ...messages.map((m) => ({
      role: m.isUser ? 'user' : 'assistant',
      content: m.content,
    })),
  ];

  const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'llama-3.3-70b-versatile',
      messages: apiMessages,
      max_tokens: 500,
      temperature: 0.4,
    }),
  });

  const data = await response.json() as any;
  return data.choices?.[0]?.message?.content || 'Error';
}
