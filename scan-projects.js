const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const CONFIG_FILE = path.join(__dirname, 'search_config.json');
const API_URL = 'https://aep.vemic.com/qwen35_35b_online/v1/chat/completions';
const SECRET = 'Y61OfCrwiEKa5WvrW6pKQkF72eMUYOjyqt9A4xZRFKE';
const MODEL = 'Qwen3.5-35B-A3B';
const CONCURRENCY = 8;
const DESC_FILE = '.fp_desc';
const MAX_FOLDERS = 500;

function loadConfig() {
  return JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8'));
}

function walkDir(dir, results, depth, maxDepth, ignoreSet) {
  if (depth > maxDepth || results.length >= MAX_FOLDERS) return;
  let entries;
  try { entries = fs.readdirSync(dir, { withFileTypes: true }); } catch { return; }
  for (const entry of entries) {
    if (!entry.isDirectory() || ignoreSet.has(entry.name)) continue;
    const fullPath = path.join(dir, entry.name);
    results.push(fullPath);
    walkDir(fullPath, results, depth + 1, maxDepth, ignoreSet);
  }
}

function getFolderInfo(dirPath) {
  try {
    const entries = fs.readdirSync(dirPath, { withFileTypes: true });
    const files = entries.map(e => e.name + (e.isDirectory() ? '/' : ''));
    if (files.length < 2) return null;

    let content = '';
    for (const name of ['CLAUDE.md', 'README.md', 'package.json', 'pom.xml', 'requirements.txt', 'setup.py', 'go.mod']) {
      try {
        const c = fs.readFileSync(path.join(dirPath, name), 'utf8').slice(0, 800);
        content += `\n--- ${name} ---\n${c}\n`;
      } catch {}
    }
    return { path: dirPath, files, content };
  } catch { return null; }
}

function computeHash(files) {
  return crypto.createHash('md5').update(files.join(',')).digest('hex').slice(0, 8);
}

function needsUpdate(dirPath, currentHash) {
  try {
    const content = fs.readFileSync(path.join(dirPath, DESC_FILE), 'utf8');
    const hashLine = content.split('\n').find(l => l.startsWith('hash:'));
    return !hashLine || hashLine.replace('hash:', '').trim() !== currentHash;
  } catch { return true; }
}

function writeDesc(dirPath, desc, hash) {
  fs.writeFileSync(path.join(dirPath, DESC_FILE), `${desc}\nhash:${hash}\n`, 'utf8');
}

async function callQwen(info) {
  const body = {
    model: MODEL,
    messages: [
      {
        role: 'system',
        content: '根据项目的文件结构和关键文件内容，用一句简短的中文描述这个项目是做什么的。只输出描述本身，不要引号、不要多余内容。如果无法判断，输出"通用文件夹"。'
      },
      {
        role: 'user',
        content: `项目路径: ${info.path}\n文件列表: ${info.files.join(', ')}\n${info.content || '(无关键文件)'}`
      }
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

  if (!resp.ok) throw new Error(`API ${resp.status}`);
  const data = await resp.json();
  return data.choices[0].message.content.trim().replace(/^["`']|["`']$/g, '');
}

async function main() {
  const config = loadConfig();
  const ignoreSet = new Set(config.ignoreDirs);

  const folders = [];
  for (const root of config.searchRoots) {
    if (!fs.existsSync(root)) continue;
    walkDir(root, folders, 0, config.maxDepth, ignoreSet);
  }

  const infos = folders.map(f => getFolderInfo(f)).filter(Boolean);

  const toUpdate = [];
  for (const info of infos) {
    const hash = computeHash(info.files);
    if (needsUpdate(info.path, hash)) {
      toUpdate.push({ ...info, hash });
    }
  }

  console.error(`扫描: ${infos.length} 个文件夹, ${toUpdate.length} 个需要更新描述`);

  if (toUpdate.length === 0) {
    console.error('所有描述都是最新的');
    return;
  }

  let done = 0;
  let ok = 0;
  for (let i = 0; i < toUpdate.length; i += CONCURRENCY) {
    const batch = toUpdate.slice(i, i + CONCURRENCY);
    const results = await Promise.allSettled(
      batch.map(async (info) => {
        const desc = await callQwen(info);
        writeDesc(info.path, desc, info.hash);
        return { path: info.path, desc };
      })
    );

    done += batch.length;
    for (const r of results) {
      if (r.status === 'fulfilled') {
        ok++;
        console.error(`[${done}/${toUpdate.length}] ✓ ${path.basename(r.value.path)} → ${r.value.desc}`);
      } else {
        console.error(`[${done}/${toUpdate.length}] ✗ ${r.reason}`);
      }
    }
  }

  console.error(`\n完成! 成功 ${ok}/${toUpdate.length}`);
}

main().catch(e => { console.error(e); process.exit(1); });
