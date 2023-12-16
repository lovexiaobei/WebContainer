//白屏采样参数定义
import image from '@ohos.multimedia.image';

declare class CheckParam {
  //白屏采样图片
  imageMap: image.PixelMap
  //采样图片压缩倍数
  compressRatio: number;
  //白屏采样阈值，单位：百分比
  threshold: number;
  //白屏采样点数
  pointNum: number;
  //采样区域大小
  regionSize: number;
}

function checkWhiteScreen(param: CheckParam) {
  const time = Date.now();
  //压缩图片
  param.imageMap.scale(1 / param.compressRatio, 1 / param.compressRatio, () => {
    //获取采样区域数组
    param.imageMap.getImageInfo().then((info) => {
      let width = info.size.width;
      let height = info.size.height;
      let size = param.regionSize;
      let xStep = Math.floor(width / param.pointNum);
      let yStep = Math.floor(height / param.pointNum);
      let promiseArr = [] as Promise<ArrayBuffer>[];
      for (let i = 0; i < param.pointNum; i++) {
        for (let j = 0; j < param.pointNum; j++) {
          let x = i * xStep;
          let y = j * yStep;
          //buffer大小，取值为：height * width *4
          const buffer = new ArrayBuffer(size * size * 4);
          promiseArr.push(param.imageMap.readPixels({ pixels: buffer,
            offset: 0,
            stride: size * 4,
            region: { x: x, y: y, size: { width: size, height: size } } }).then(() => {
            return buffer
          }));
        }
      }
      Promise.all(promiseArr).then((buffers) => {
        let whitePointNum = 0;
        for (let i = 0; i < buffers.length; i++) {
          let buffer = buffers[i];
          let dataView = new DataView(buffer);
          for (let j = 0; j < buffer.byteLength; j += 4) {
            let r = dataView.getUint8(j);
            let g = dataView.getUint8(j + 1);
            let b = dataView.getUint8(j + 2);
            let a = dataView.getUint8(j + 3);
            if (r == 255 && g == 255 && b == 255 && a == 255) {
              whitePointNum++;
            }
          }
        }
        let whitePointPercent = whitePointNum / (param.pointNum * param.pointNum * param.regionSize * param.regionSize) * 100;
        if (whitePointPercent >= param.threshold) {
          console.info("白屏" + whitePointPercent + "%");
        } else {
          console.info("非白屏" + whitePointPercent + "%");
        }
        console.info("白屏检测耗时：" + (Date.now() - time) + "ms");
      })
    })
  })
}


function logPicInfo(imageMap: image.PixelMap) {
  imageMap.getImageInfo().then((info) => {
    console.info("image info: width=" + info.size.width + ",height=" + info.size.height + ",density=" + info.density);
  })
}

export {
  checkWhiteScreen
}