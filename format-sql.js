const fs = require('fs');
const { format } = require('sql-formatter');

const inFile = process.argv[2];
const outFile = process.argv[3];

if (!inFile || !outFile) {
  console.error('Usage: node format-sql.js <input> <output>');
  process.exit(1);
}

function formatSql(sql) {
  // 检测 Hive/Spark 方言特征
  const isHive = /\b(lateral\s+view|explode|collect_set|collect_list|get_json_object|named_struct|udf|reflect|inline|posexplode|stack)\b/i.test(sql)
    || /\[\d+\]/.test(sql)
    || /\$\{[^}]+\}/.test(sql);

  const opts = {
    language: isHive ? 'hive' : 'sql',
    tabWidth: 2,
    keywordCase: 'upper',
    functionCase: 'upper',
    identifierCase: 'preserve',
    linesBetweenQueries: 2,
  };

  let formatted = format(sql, opts);

  // 修复逗号位置：把 "内容 -- 注释\n," 改为 "内容, -- 注释"
  formatted = formatted.replace(/^(.*\S)(\s*--[^\n]*)\n\s*,\n/gm, '$1,$2\n');

  return formatted;
}

try {
  const sql = fs.readFileSync(inFile, 'utf8');
  const formatted = formatSql(sql);
  fs.writeFileSync(outFile, formatted, 'utf8');
} catch (e) {
  // Hive 方言失败则回退到通用 SQL 重试
  try {
    const sql = fs.readFileSync(inFile, 'utf8');
    const formatted = format(sql, {
      language: 'sql',
      tabWidth: 2,
      keywordCase: 'upper',
      functionCase: 'upper',
      identifierCase: 'preserve',
      linesBetweenQueries: 2,
    });
    fs.writeFileSync(outFile, formatted, 'utf8');
  } catch (e2) {
    console.error(e2.message);
    process.exit(1);
  }
}
