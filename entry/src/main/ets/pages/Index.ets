import Want from '@ohos.app.ability.Want';
import common from '@ohos.app.ability.common';
import { initOffLineLib } from '../web/offline/offline';

@Entry
@Component
struct Index {
  @State message: string = 'Hello World';

  build() {
    Column() {
      Button('启动Web容器', { type: ButtonType.Normal, stateEffect: true })
        .borderRadius(8)
        .backgroundColor(0x317aff)
        .onClick(() => {
          let want: Want = {
            deviceId: '', // deviceId为空表示本设备
            bundleName: 'com.mgg.webcontainer',
            abilityName: 'WebAbility',
            parameters: { // 自定义信息
              url: "https://www.chenshengyu.cn"
            },
          }
          let context = getContext(this) as common.UIAbilityContext;
          context.startAbility(want);

        })
        .width(200)
        .height(40)

      Button('加载离线包', { type: ButtonType.Normal, stateEffect: true })
        .borderRadius(8)
        .backgroundColor(0x317aff)
        .onClick(() => {
          initOffLineLib(getContext(this) as common.UIAbilityContext);
        })
        .margin({ top: 20 })
        .width(200)
        .height(40)
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)

  }
}

