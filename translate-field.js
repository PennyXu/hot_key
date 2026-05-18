const fs = require('fs');
const crypto = require('crypto');

const inFile = process.argv[2];
const outFile = process.argv[3];

if (!inFile || !outFile) {
  console.error('Usage: node translate-field.js <input> <output>');
  process.exit(1);
}

const API_URL = 'https://aep.vemic.com/qwen35_35b_online/v1/chat/completions';
const SECRET = 'Y61OfCrwiEKa5WvrW6pKQkF72eMUYOjyqt9A4xZRFKE';
const MODEL = 'Qwen3.5-35B-A3B';

async function translate(text) {
  const body = {
    model: MODEL,
    messages: [
      {
        role: 'system',
        content: '你是一个数据库字段命名专家。用户输入中文短语，你需要将其翻译为英文 snake_case 格式的字段名。只输出字段名本身，不要任何解释、引号或其他内容。例如：成立年限标签 → establishment_year_tag，客户名称 → customer_name，订单金额 → order_amount。'
      },
      { role: 'user', content: text.trim() }
    ],
    temperature: 0.3
  };

  const resp = await fetch(API_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-AEP-CONSUMER-SECRET': SECRET,
      'X-AEP-REQUEST-ID': crypto.randomUUID()
    },
    body: JSON.stringify(body)
  });

  if (!resp.ok) throw new Error(`API error: ${resp.status}`);
  const data = await resp.json();
  let result = data.choices[0].message.content.trim();
  // 清理可能的 markdown 标记和引号
  result = result.replace(/`/g, '').replace(/^["']|["']$/g, '');
  return result;
}

(async () => {
  try {
    const text = fs.readFileSync(inFile, 'utf8');
    const field = await translate(text);
    fs.writeFileSync(outFile, field, 'utf8');
  } catch (e) {
    console.error(e.message);
    process.exit(1);
  }
})();
