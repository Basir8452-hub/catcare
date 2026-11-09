import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        return;
      }
      try {
        const win: window.Window = windowStage.getMainWindowSync();
        // 内容延伸到状态栏 / 导航条后方（网页已用 env(safe-area-inset-*) 处理安全区）
        win.setWindowLayoutFullScreen(true)
          .catch((e: BusinessError) => console.error(`setWindowLayoutFullScreen failed: ${e.code} ${e.message}`));
        // 传空数组 = 同时隐藏状态栏与底部导航条，得到完全沉浸的原生观感。
        // 若想保留顶部状态栏（时间/电量），改为：setWindowSystemBarEnable(['status'])
        win.setWindowSystemBarEnable([])
          .catch((e: BusinessError) => console.error(`setWindowSystemBarEnable failed: ${e.code} ${e.message}`));
      } catch (e) {
        console.error(`window config failed: ${JSON.stringify(e)}`);
      }
    });
  }

  onWindowStageDestroy(): void {
  }

  onForeground(): void {
  }

  onBackground(): void {
  }

  onDestroy(): void {
  }
}
