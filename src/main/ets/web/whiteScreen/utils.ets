//白屏采样参数定义
import image from '@ohos.multimedia.image';

declare class CheckParam {
  //白屏采样图片
  imageMap: image.PixelMap
  //采样图片压缩倍数
  compressRatio: number;
  //白屏采样阈值，单位：百分比
  threshold: number;
  //白屏采样比例，单位：百分比
  density: number;
  //采样区域大小
  regionSize: number;
  //采样对比颜色
  color: number;
}

function checkWhiteScreen(param: CheckParam): Promise<boolean> {
  const time = Date.now();
  //压缩图片
  return param.imageMap.scale(1 / param.compressRatio, 1 / param.compressRatio)
    .then(() => {
      return param.imageMap.getImageInfo();
    })
    .then(info => {
      let width = info.size.width;
      let height = info.size.height;
      let size = param.regionSize;
      // 根据采样比例计算采样图片 X 轴的采样点数量
      let pointNumX = Math.floor(width * param.density / 100 / size);
      // 根据采样比例计算采样图片 Y 轴的采样点数量
      let pointNumY = Math.floor(height * param.density / 100 / size);
      // 根据采样点数量计算采样图片 X 轴的采样步长
      let xStep = Math.floor(width / pointNumX);
      // 根据采样点数量计算采样图片 Y 轴的采样步长
      let yStep = Math.floor(height / pointNumY);
      console.info("采样点数量：pointNumX =" + pointNumX + "pointNumY=" + pointNumY + "total=" + pointNumX * pointNumY);
      console.info("采样步长：" + xStep + "," + yStep);

      let promiseArr = [] as Promise<ArrayBuffer>[];
      for (let i = 0; i < pointNumX; i++) {
        for (let j = 0; j < pointNumY; j++) {
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

      return Promise.all(promiseArr);
    })
    .then(buffers => {
      let whitePointNum = 0;
      let cr = param.color >> 16 & 0xff;
      let cg = param.color >> 8 & 0xff;
      let cb = param.color & 0xff;
      let ca = param.color >> 24 & 0xff;
      for (let i = 0; i < buffers.length; i++) {
        let buffer = buffers[i];
        let dataView = new DataView(buffer);
        for (let j = 0; j < buffer.byteLength; j += 4) {
          let r = dataView.getUint8(j);
          let g = dataView.getUint8(j + 1);
          let b = dataView.getUint8(j + 2);
          let a = dataView.getUint8(j + 3);
          if (r === cr && g === cg && b === cb && a === ca) {
            whitePointNum++;
          }
        }
      }
      let whitePointPercent = Math.floor(whitePointNum / (buffers.length * param.regionSize * param.regionSize) * 100);
      console.info("白屏检测耗时：" + (Date.now() - time) + "ms");
      if (whitePointPercent >= param.threshold) {
        console.info("白屏" + whitePointPercent + "%");
        return true;
      } else {
        console.info("非白屏" + whitePointPercent + "%");
        return false;
      }
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