import HashMap from '@ohos.util.HashMap'
import common from '@ohos.app.ability.common'
import fs from '@ohos.file.fs';
import { BusinessError } from '@ohos.base';
import zlib from '@ohos.zlib';
import request from '@ohos.request';

const offLineMap: HashMap<string, WebResourceResponse> = new HashMap<string, WebResourceResponse>()

const localPathSuffix = "/public";
const downloadFilePathSuffix = "/public.zip";

const initOffLineLib = (context: common.UIAbilityContext) => {
  let path = context.filesDir + localPathSuffix;
  //判断是否存在public目录
  if (fs.accessSync(path)) {
    //存在public目录,初始化离线资源
    console.info("initOffLine 存在public目录");
    initOffLine(context.filesDir);
    return;
  }
  //不存在public目录,判断是否存在public.zip
  path = context.filesDir + downloadFilePathSuffix;
  if (fs.accessSync(path)) {
    //存在public.zip,解压public.zip
    console.info("initOffLine 存在public.zip");
    unzip(path, context.filesDir);
    return;
  }

  //不存在public目录和public.zip,下载public.zip
  try {
    request.downloadFile(context, {
      url: 'https://chenshengyu.cn/public.zip',
      filePath: path,
    }).then((downloadTask: request.DownloadTask) => {
      downloadTask.on('progress', (receivedSize: number, totalSize: number) => {
        console.info(`download progress: ${receivedSize}/${totalSize}`);
      })
      downloadTask.on('complete', () => {
        console.info('download complete');
        unzip(path, context.filesDir);
      })
    }).catch((err: BusinessError) => {
      console.error(`Invoke downloadTask failed, code is ${err.code}, message is ${err.message}`);
    });
  } catch (error) {
    let err: BusinessError = error as BusinessError;
    console.error(`Invoke downloadFile failed, code is ${err.code}, message is ${err.message}`);
  }
}
const unzip = (zipPath: string, path: string) => {
  zlib.decompressFile(zipPath, path).then(() => {
    console.info('decompressFile success');
    initOffLine(path);
  }).catch((err: BusinessError) => {
    console.error(`Invoke decompressFile failed, code is ${err.code}, message is ${err.message}`);
  });
}

const initOffLine = (path: string) => {
  offLineMap.clear();
  initOffLineList(path, path + "/public");
}

const initOffLineList = (path: string, suffix: string) => {
  let files = fs.listFileSync(path);
  files.forEach((file) => {
    let pathDir = path + "/" + file;
    fs.stat(pathDir, (err: BusinessError, stat: fs.Stat) => {
      if (err) {
        console.info("get file info failed with error message: " + err.message + ", error code: " + err.code);
      } else {
        if (stat.isDirectory()) {
          initOffLineList(pathDir, suffix)
        } else if (stat.isFile()) {
          initOffLineMap(pathDir, suffix)
        }
      }
    });
  })
}
const initOffLineMap = (path: string, suffix: string) => {
  fs.readText(path).then((data) => {
    let response = new WebResourceResponse();
    response.setResponseData(data);
    response.setResponseEncoding("utf-8");
    response.setResponseMimeType(path2MimeType(path));
    response.setResponseCode(200);
    response.setReasonMessage('OK');
    let key = path.replace(suffix, "");
    console.info("key:" + key);
    offLineMap.set(key, response);
  })
}

const path2MimeType = (path: string) => {
  let index = path.lastIndexOf(".");
  let suffix = path.substring(index + 1);
  let mimeType = "text/html";
  switch (suffix) {
    case "html":
      mimeType = "text/html";
      break;
    case "js":
      mimeType = "text/javascript";
      break;
    case "css":
      mimeType = "text/css";
      break;
    case "png":
      mimeType = "image/png";
      break;
    case "jpg":
      mimeType = "image/jpeg";
      break;
    case "gif":
      mimeType = "image/gif";
      break;
    case "svg":
      mimeType = "image/svg+xml";
      break;
    case "ico":
      mimeType = "image/x-icon";
      break;
    case "json":
      mimeType = "application/json";
      break;
    case "xml":
      mimeType = "application/xml";
      break;
    case "pdf":
      mimeType = "application/pdf";
      break;
    case "zip":
      mimeType = "application/zip";
      break;
    case "mp3":
      mimeType = "audio/mpeg";
      break;
    case "mp4":
      mimeType = "video/mp4";
      break;
    default:
      mimeType = "text/html";
      break;
  }
  return mimeType;
}


export {
  offLineMap, initOffLineLib
}