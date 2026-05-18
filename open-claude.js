const fs = require('fs');
const path = require('path');

const CACHE_FILE = path.join(__dirname, 'folder_cache.txt');
const CONFIG_FILE = path.join(__dirname, 'search_config.json');

const DEFAULT_CONFIG = {
  searchRoots: ['D:\\'],
  maxDepth: 3,
  ignoreDirs: [
    'node_modules', '.git', 'dist', 'build', '__pycache__',
    '.cache', 'AppData', '.nuget', '.vs', '.gradle',
    '.m2', '.cargo', 'venv', '.venv', 'env', 'target',
    '.idea', '.vscode', 'out', 'bin', 'obj', 'vendor',
    'cache', 'temp', 'tmp', 'logs', '.next', '.nuxt'
  ]
};

function loadConfig() {
  if (fs.existsSync(CONFIG_FILE)) {
    return JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8'));
  }
  fs.writeFileSync(CONFIG_FILE, JSON.stringify(DEFAULT_CONFIG, null, 2), 'utf8');
  return DEFAULT_CONFIG;
}

function walkDir(dir, results, depth, maxDepth, ignoreSet) {
  if (depth > maxDepth) return;
  let entries;
  try {
    entries = fs.readdirSync(dir, { withFileTypes: true });
  } catch {
    return;
  }
  for (const entry of entries) {
    if (!entry.isDirectory()) continue;
    if (ignoreSet.has(entry.name)) continue;
    const fullPath = path.join(dir, entry.name);
    results.push(fullPath);
    walkDir(fullPath, results, depth + 1, maxDepth, ignoreSet);
  }
}

function buildCache() {
  const config = loadConfig();
  const ignoreSet = new Set(config.ignoreDirs);
  const folders = [];

  for (const root of config.searchRoots) {
    if (!fs.existsSync(root)) continue;
    walkDir(root, folders, 0, config.maxDepth, ignoreSet);
  }

  folders.sort();

  // 读取 .fp_desc 合并描述
  const lines = folders.map(f => {
    const descFile = path.join(f, '.fp_desc');
    let desc = '';
    try { desc = fs.readFileSync(descFile, 'utf8').split('\n')[0]; } catch {}
    return desc ? `${f}\t${desc}` : f;
  });

  fs.writeFileSync(CACHE_FILE, lines.join('\n'), 'utf8');
  return folders.length;
}

const action = process.argv[2];

if (action === 'build') {
  const count = buildCache();
  console.error(`Cached ${count} folders`);
} else {
  console.error('Usage: node open-claude.js build');
  process.exit(1);
}
