import Want from '@ohos.app.ability.Want';
import common from '@ohos.app.ability.common';
import fs from '@ohos.file.fs';
import request from '@ohos.request';
import { BusinessError } from '@ohos.base';
import zlib from '@ohos.zlib';
import { initOffLine } from '../web/offline/offline';

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
          this.loadOfflinePackage();
        })
        .margin({top:20               })
        .width(200)
        .height(40)
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)

  }

  loadOfflinePackage() {
    //判断本地离线包是否存在
    let context = getContext(this) as common.UIAbilityContext;
    let filesDir = context.filesDir + '/offlineWeb';
    if (fs.accessSync(filesDir)) {
      //如果离线包存在直接初始化
      console.info('offline package is exist');
      initOffLine(filesDir);
    } else {
      //不存在就去下载离线包
      console.info('offline package is not exist');
      this.downloadOfflinePackage(filesDir);
    }
  }

  downloadOfflinePackage(path: string) {
    let context = getContext(this) as common.UIAbilityContext;
    let zipDir = context.filesDir + '/offlineWeb/offline.zip';
    let filesDir = context.filesDir + '/offlineWeb';
    //判断文件夹是否存在
    if (!fs.accessSync(filesDir)) {
      fs.mkdirSync(filesDir);
    }
    //判断本地离线包是否存在
    if (fs.accessSync(zipDir)) {
      zlib.decompressFile(zipDir, path).then(() => {
        console.info('decompressFile success');
        initOffLine(path);
      }).catch((err: BusinessError) => {
        console.error(`Invoke decompressFile failed, code is ${err.code}, message is ${err.message}`);
      });
    }
    try {
      request.downloadFile(context, {
        url: 'https://chenshengyu.cn/public.zip',
        filePath: zipDir,
      }).then((downloadTask: request.DownloadTask) => {
        downloadTask.on('progress', (receivedSize: number, totalSize: number) => {
          console.info(`download progress: ${receivedSize}/${totalSize}`);
        })
        downloadTask.on('complete', () => {
          //解压缩
          zlib.decompressFile(zipDir, path).then(() => {
            console.info('decompressFile success');
            initOffLine(path);
          }).catch((err: BusinessError) => {
            console.error(`Invoke decompressFile failed, code is ${err.code}, message is ${err.message}`);
          });
        })
      }).catch((err: BusinessError) => {
        console.error(`Invoke downloadTask failed, code is ${err.code}, message is ${err.message}`);
      });
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`Invoke downloadFile failed, code is ${err.code}, message is ${err.message}`);
    }
  }
}

