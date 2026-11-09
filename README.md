# 猫事 · CatCare

零依赖、本地优先的养猫记录工具。单个 HTML 文件即可运行，数据保存在浏览器本地（IndexedDB），无需注册、无需联网。

在线使用：https://basir8452-hub.github.io/catcare/

## 功能

- 宠物档案：多只猫的基本信息与头像
- 待办事项：喂食、铲屎、疫苗、驱虫、洗澡等提醒
- 健康记录：体重、用药、就诊记录
- 记账：日常开销明细与月度统计
- 周期目标：目标设定与进度跟踪
- 知识库：内置养猫常见知识
- 照片相册：成长记录
- 数据备份：一键导出 / 导入 JSON 备份

## 使用方式

- 电脑：用浏览器直接打开 `index.html`
- 手机：浏览器打开后通过「添加到主屏幕」当作 App 使用
- 数据只保存在当前设备，换设备或重装前先在「更多 → 数据备份」导出一份

## 技术实现

- 原生 HTML / CSS / JavaScript，零依赖、零构建
- PWA：`manifest.json` + Service Worker，支持离线与主屏幕安装
- 数据存储：IndexedDB；数据模型已按「可同步」设计（`uuid` / `updatedAt` / `rev` / 软删除 `deleted` / 预留 `ownerId`、`shareIds`）

## 目录结构

| 文件 | 说明 |
| --- | --- |
| `index.html` | 应用主体（单文件，含样式与逻辑） |
| `knowledge-data.js` | 内置知识库数据 |
| `manifest.json` | PWA 清单 |
| `sw.js` | Service Worker，离线缓存 |
| `icon.svg` / `icon-192.png` / `icon-512.png` | 应用图标 |
| `tokens.css` / `tokens.json` | 设计令牌 |

## 部署

推送到 `main` 分支后自动发布到 GitHub Pages（分支部署，无需构建）。

## 路线图

- [ ] 多设备同步 + 多账号共养（云端）
- [ ] Android APK（TWA 打包）

## 隐私

数据默认只保存在访问者本机浏览器中，除加载页面本身外，不向任何服务器上传数据。
