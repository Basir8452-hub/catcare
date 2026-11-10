// 把仓库根目录的网页资源拷进 packaging/www/，供 Capacitor 打进 APK。
// 白名单是唯一的资源清单：少一个就报错退出，避免打包出「缺文件」的壳。
import { cp, mkdir, rm, stat } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const here = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(here, '..', '..');
const webDir = path.resolve(here, '..', 'www');

const FILES = [
  'index.html',
  'knowledge-data.js',
  'manifest.json',
  'sw.js',
  'icon.svg',
  'icon-192.png',
  'icon-512.png',
  'icon-maskable-512.png',
];

const missing = [];
for (const f of FILES) {
  try {
    const s = await stat(path.join(repoRoot, f));
    if (!s.isFile()) missing.push(f);
  } catch {
    missing.push(f);
  }
}
if (missing.length) {
  console.error('[sync-web] 源文件缺失，终止打包：' + missing.join(', '));
  process.exit(1);
}

await rm(webDir, { recursive: true, force: true });
await mkdir(webDir, { recursive: true });
for (const f of FILES) {
  await cp(path.join(repoRoot, f), path.join(webDir, f));
}

console.log(`[sync-web] 已同步 ${FILES.length} 个文件 → ${path.relative(process.cwd(), webDir)}`);
