const fs = require('fs');
const crypto = require('crypto');

const query = process.argv[2];
const cacheFile = process.argv[3];

if (!query || !cacheFile) {
  console.error('Usage: node ai-search.js "query" cacheFile');
  process.exit(1);
}

const API_URL = 'https://aep.vemic.com/qwen35_35b_online/v1/chat/completions';
const SECRET = 'Y61OfCrwiEKa5WvrW6pKQkF72eMUYOjyqt9A4xZRFKE';
const MODEL = 'Qwen3.5-35B-A3B';
const MAX_INPUT = 20000;

const cache = fs.readFileSync(cacheFile, 'utf8').split('\n').filter(Boolean);

// 只保留有描述的项目，过滤掉系统目录和无意义描述
const withDesc = cache.filter(line => {
  const tabPos = line.indexOf('\t');
  if (tabPos <= 0) return false;
  const path = line.slice(0, tabPos);
  const desc = line.slice(tabPos + 1);
  if (!desc || desc === '通用文件夹') return false;
  if (path.includes('\\.claude\\') || path.includes('/.claude/')) return false;
  if (path.includes('\\__MACOSX') || path.includes('/__MACOSX')) return false;
  return true;
});

// 构建带编号的项目列表，控制在字符限制内
let indexed = '';
const idx = [];
for (let i = 0; i < withDesc.length; i++) {
  const tabPos = withDesc[i].indexOf('\t');
  const path = withDesc[i].slice(0, tabPos);
  const desc = withDesc[i].slice(tabPos + 1);
  const display = `${path} | ${desc}`;
  const entry = `${i + 1}. ${display}\n`;
  if ((indexed + entry).length > MAX_INPUT) break;
  indexed += entry;
  idx.push({ path, desc, display });
}

const body = {
  model: MODEL,
  messages: [
    {
      role: 'system',
      content: '你是项目搜索助手。用户用自然语言描述想找的项目，你从列表中找出语义最相关的项目。按相关性从高到低返回最多20个，只输出序号用逗号分隔，如: 3,15,7,42。不要输出其他任何内容。'
    },
    {
      role: 'user',
      content: `项目列表：\n${indexed}\n搜索意图：${query}`
    }
  ],
  temperature: 0.3
};

fetch(API_URL, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-AEP-CONSUMER-SECRET': SECRET,
    'X-AEP-REQUEST-ID': crypto.randomUUID()
  },
  body: JSON.stringify(body)
})
  .then(r => r.json())
  .then(data => {
    const text = data.choices[0].message.content.trim();
    const nums = text.match(/\d+/g) || [];
    for (const n of nums) {
      const entry = idx[parseInt(n) - 1];
      if (entry) console.log(entry.display);
    }
  })
  .catch(e => { console.error(e.message); process.exit(1); });
