/**
 * LocalPhotoService - 本地打卡照片
 *
 * 作用：从相册选图并复制到应用私有目录，供任务打卡展示（暂不上云）。
 */
import { common } from '@kit.AbilityKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo } from '@kit.CoreFileKit';

export class LocalPhotoService {
  /**
   * 选择一张图片并保存到应用目录，返回本地 file:// 路径。
   */
  static async pickCheckInPhoto(context: common.Context, taskId: string): Promise<string> {
    const picker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
    const result: photoAccessHelper.PhotoSelectResult = await picker.select({
      MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
      maxSelectNumber: 1
    });
    if (result.photoUris.length === 0) {
      return '';
    }
    const srcUri: string = result.photoUris[0];
    const dir: string = `${context.filesDir}/checkin`;
    try {
      fileIo.mkdirSync(dir);
    } catch (_err) {
      // 目录已存在
    }
    const destPath: string = `${dir}/${taskId}_${Date.now()}.jpg`;
    const srcFile: fileIo.File = fileIo.openSync(srcUri, fileIo.OpenMode.READ_ONLY);
    const destFile: fileIo.File = fileIo.openSync(destPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);
    fileIo.copyFileSync(srcFile.fd, destFile.fd);
    fileIo.closeSync(srcFile);
    fileIo.closeSync(destFile);
    return `file://${destPath}`;
  }
}
