import web_webview from '@ohos.web.webview';
import router from '@ohos.router';
import hilog from '@ohos.hilog';
import { offLineMap } from '../offline/offline';

let storage = LocalStorage.getShared()
const TAG = 'WebPage';

@Entry(storage)
@Component
struct WebPage {
  @State title: string = '标题';
  webviewController: web_webview.WebviewController = new web_webview.WebviewController();
  @LocalStorageProp('url') url: string = '';

  build() {
    Column() {
      Row() {
        //back
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          Image($r('app.media.back')).width(30).height(30)
        }.width(30)
        .height(30)
        .margin({ left: 10 })
        .backgroundColor(0xFFFFFF)
        .onClick(() => {
         this.onBackPress();
        })
        Text(this.title) {
        }.layoutWeight(1).height(30).width("100%").textAlign(TextAlign.Center).maxLines(1).margin({right:40})
      }.height(50).width("100%").justifyContent(FlexAlign.Start)
      Web({src:this.url,controller:this.webviewController})
        .layoutWeight(1)
        .width("100%")
        .onPageBegin((event) => {
        })
        .onInterceptRequest((event) => {
          //获取请求地址
          const requestUrl = event?.request?.getRequestUrl();
          let key ="";
          //判断是不是静态资源
          if (requestUrl?.startsWith(this.url)){
            key = requestUrl.substring(this.url.length);
            // 对/结尾的资源特殊处理 追加上index.html
            if (key.endsWith("/")) {
              key += "index.html"
            }
            //判断本地离线包是否命中
            let response = offLineMap.get(key)
            if ( response != null) {
              //命中离线包资源，使用本地离线包数据
              return response
            }
          }
         return;
        }).cacheMode(CacheMode.None)
        .onProgressChange((event) => {
          hilog.info(0x0000, TAG, 'onProgressChange %{public}s', event?.newProgress??"");
        })
        .onConsole((callback) => {
          hilog.info(0x0000, TAG, 'onConsole %{public}s', callback?.message??"");
          return false;
        })
        .onTitleReceive((event) => {
          hilog.info(0x0000, TAG, 'onTitleReceive %{public}s', event?.title??"");
          if (event?.title){
            this.title = event.title;
          }
        })
        .onErrorReceive((event) => {
          hilog.info(0x0000, TAG, 'onErrorReceive');
        })
        .onHttpErrorReceive((event) => {
          hilog.info(0x0000, TAG, 'onHttpErrorReceive');
        })
        .onSslErrorEventReceive((event) => {
          hilog.info(0x0000, TAG, 'onSslErrorEventReceive');
        })
      ;
    }.width("100%").height("100%")
  }
  onBackPress() {
    if (this.webviewController.accessBackward()) {
      this.webviewController.backward();
      return true;
    }
    router.back()
    return false;
  }
}