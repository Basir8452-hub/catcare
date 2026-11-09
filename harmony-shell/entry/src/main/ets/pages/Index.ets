import { webview } from '@kit.ArkWeb';

// 壳加载的线上地址：与网页版是同一份代码，之后改网页无需重装 App。
const SITE_URL: string = 'https://basir8452-hub.github.io/catcare/';

@Entry
@Component
struct Index {
  controller: webview.WebviewController = new webview.WebviewController();

  build() {
    Column() {
      Web({ src: SITE_URL, controller: this.controller })
        .javaScriptAccess(true)        // 默认即 true，显式写出更清晰
        .domStorageAccess(true)        // 必须显式开：否则 localStorage / IndexedDB 失效
        .databaseAccess(true)          // 保守兜底：兼容 IndexedDB 的历史依赖
        .cacheMode(CacheMode.Default)  // 断网时优先回退到上次缓存内容
        .width('100%')
        .height('100%')
    }
    .width('100%')
    .height('100%')
    // 页面加载完成前露出的底色，对齐网页浅色主题 --bg。
    // 若你主要用深色模式，可改成 '#171412'。
    .backgroundColor('#FBF3E8')
  }

  // 系统返回键：网页能后退就后退，否则交回系统（退出应用）
  onBackPress(): boolean {
    if (this.controller.accessBackward()) {
      this.controller.backward();
      return true;
    }
    return false;
  }
}
