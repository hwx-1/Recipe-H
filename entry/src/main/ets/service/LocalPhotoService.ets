/**
 * LocalPhotoService - 本地照片：相机拍摄 / 相册选择
 */
import { common } from '@kit.AbilityKit';
import { camera, cameraPicker } from '@kit.CameraKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo } from '@kit.CoreFileKit';

export enum PhotoPickSource {
  CAMERA = 'camera',
  ALBUM = 'album'
}

export class LocalPhotoService {
  private static savePhotoFromUri(context: common.Context, folder: string, filePrefix: string,
    srcUri: string): string {
    const dir: string = `${context.filesDir}/${folder}`;
    try {
      fileIo.mkdirSync(dir);
    } catch (_err) {
      // 目录已存在
    }
    const destPath: string = `${dir}/${filePrefix}_${Date.now()}.jpg`;
    const srcFile: fileIo.File = fileIo.openSync(srcUri, fileIo.OpenMode.READ_ONLY);
    const destFile: fileIo.File = fileIo.openSync(destPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);
    fileIo.copyFileSync(srcFile.fd, destFile.fd);
    fileIo.closeSync(srcFile);
    fileIo.closeSync(destFile);
    return `file://${destPath}`;
  }

  static async pickFromAlbum(context: common.Context, folder: string, filePrefix: string): Promise<string> {
    const picker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
    const result: photoAccessHelper.PhotoSelectResult = await picker.select({
      MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
      maxSelectNumber: 1
    });
    if (result.photoUris.length === 0) {
      return '';
    }
    return LocalPhotoService.savePhotoFromUri(context, folder, filePrefix, result.photoUris[0]);
  }

  static async captureFromCamera(context: common.Context, folder: string, filePrefix: string): Promise<string> {
    const pickerProfile: cameraPicker.PickerProfile = {
      cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK
    };
    const result: cameraPicker.PickerResult = await cameraPicker.pick(context,
      [cameraPicker.PickerMediaType.PHOTO], pickerProfile);
    if (result.resultCode !== 0 || result.resultUri.length === 0) {
      return '';
    }
    return LocalPhotoService.savePhotoFromUri(context, folder, filePrefix, result.resultUri);
  }

  static async pickPhoto(context: common.Context, folder: string, filePrefix: string,
    source: PhotoPickSource): Promise<string> {
    if (source === PhotoPickSource.CAMERA) {
      return LocalPhotoService.captureFromCamera(context, folder, filePrefix);
    }
    return LocalPhotoService.pickFromAlbum(context, folder, filePrefix);
  }

  static async pickCheckInPhoto(context: common.Context, taskId: string,
    source: PhotoPickSource): Promise<string> {
    return LocalPhotoService.pickPhoto(context, 'checkin', taskId, source);
  }

  static async pickCookCompletePhoto(context: common.Context, recipeId: string,
    source: PhotoPickSource): Promise<string> {
    return LocalPhotoService.pickPhoto(context, 'cook_complete', recipeId, source);
  }
}
