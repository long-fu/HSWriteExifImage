//
//  ViewController.swift
//  Sampler
//
//  Created by luo fengyuan on 2019/8/6.
//  Copyright © 2019 onelcat. All rights reserved.
//

import UIKit
import CoreLocation
import MobileCoreServices
import AVFoundation
import Photos
import HSWriteExifImage

class ViewController: UIViewController {
    
    private var _locationManager: CLLocationManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        __startLocation()
        // Do any additional setup after loading the view.
    }
    
    
}

private
extension ViewController {
    
    @IBAction
    func __pushCustomCameraVC() {
        
        PHPhotoLibrary.requestAuthorization { (status) in
            
        }
        
        let pickerCamera = UIImagePickerController()
        pickerCamera.sourceType = .camera
        pickerCamera.delegate = self
        pickerCamera.cameraFlashMode = .auto
        pickerCamera.videoQuality = .typeIFrame1280x720
        pickerCamera.videoMaximumDuration = 10 * 60
        pickerCamera.showsCameraControls = true
        pickerCamera.mediaTypes = [kUTTypeImage,kUTTypeMovie] as [String]
        self.present(pickerCamera, animated: true, completion: nil)
    }
    
    func __startLocation() {
        
        
        
        _locationManager = CLLocationManager()
        
        _locationManager?.requestWhenInUseAuthorization()
        
        _locationManager?.activityType = .other
        _locationManager?.delegate = self
        _locationManager?.startUpdatingLocation()
    }
    
    func __savePhotoAndGetphoto(imageData: Data) {
        var localID: String!//标识符
        
        PHPhotoLibrary.shared().performChanges({
            let creationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: .photo, data: imageData, options: nil)
            let assetPlaceholder = creationRequest.placeholderForCreatedAsset
            //保存标识符
            localID = assetPlaceholder?.localIdentifier
        }) { (succ, error) in
            if succ {
                debugPrint("保存成功")
                //通过标识符获取对应的资源
                let assetResult = PHAsset.fetchAssets(withLocalIdentifiers: [localID], options: nil)
                let asset = assetResult[0]
                let options = PHContentEditingInputRequestOptions()
                options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
                    return true
                }
                //获取保存的图片路径
                PHImageManager.default().requestImageData(for: asset, options: nil, resultHandler: { (imageData, dataUTI, orientation, info) in
                    guard let imageData = imageData else {
                        return
                    }
                    
                })
//                asset.requestContentEditingInput(with: options, completionHandler: { (contentEditingInput: PHContentEditingInput?, info: [AnyHashable : Any]) in
//                    let file = contentEditingInput!.fullSizeImageURL!
//                    print("地址：\(file)")
//                })
                
//                //获取保存的原图
//                PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.aspectFit, options: nil, resultHandler: { (image, handle: [AnyHashable : Any]?) in
//                    print("获取原图成功：\(String(describing: image))")
//                })
//
//                //获取保存的缩略图
//                PHImageManager.default().requestImage(for: asset, targetSize: CGSize.init(width: 100, height: 100), contentMode: PHImageContentMode.aspectFit, options: nil, resultHandler: { (image, handle: [AnyHashable : Any]?) in
//                    print("获取缩略图成功：\(String(describing: image))")
//                })
                
            } else {
                print("保存失败-->\(error!.localizedDescription)")
            }
        }
    }
    

    
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }
}
import ImageIO
// MARK: UIImagePickerControllerDelate
extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) {
            picker.delegate = nil
            UIApplication.shared.isIdleTimerDisabled = true
            self.navigationController?.isNavigationBarHidden = true
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true) {
            picker.delegate = nil
            UIApplication.shared.isIdleTimerDisabled = true
            self.navigationController?.isNavigationBarHidden = true
        }
        
        guard let mediaMetadata = info[UIImagePickerController.InfoKey.mediaMetadata] as? NSDictionary else {
            return
        }
        
        guard let type = info[UIImagePickerController.InfoKey.mediaType] as? AVMediaType else {
            return
        }
        
        debugPrint("拍摄信息输出",mediaMetadata, type, type.rawValue)
        if type.rawValue == "public.image" {
            
            guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
                return
            }
            
            guard let location = _locationManager?.location else {
                return
            }
            let wImage = image.waterMarkedImage(location: location)
            guard let imageData = wImage.writeExif(mediaMetadata: mediaMetadata, location: location) else {
                return
            }
//            let ciImgae = CIImage(data: imageData)!
//            let newimage = UIImage(ciImage: ciImgae)
//            let t = UIImage(data: imageData)!
//            PHPhotoLibrary.shared().performChanges({
//                debugPrint(newimage)
//                let creationRequest = PHAssetCreationRequest.creationRequestForAsset(from: t)
//                creationRequest.location = location
//                creationRequest.creationDate = Date()
////                let assetPlaceholder = creationRequest.placeholderForCreatedAsset
//            }) { (su, ero) in
//                debugPrint("保存结果", su)
//            }
            writeExifImageDataToSavedPhotosAlbum(imageData, location: location, creationDate: Date()) { (result) in
                switch result {
                case let .success(localIdentifier):
                    let assetResult = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
                    let asset = assetResult[0]
                    let options = PHContentEditingInputRequestOptions()
                    options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
                        return true
                    }
                    //获取保存的图片路径
//                    asset.requestContentEditingInput(with: options, completionHandler: { (contentEditingInput: PHContentEditingInput?, info: [AnyHashable : Any]) in
//                        let file = contentEditingInput!.fullSizeImageURL!
//                        let info = readImageExif(file: file)
//                        debugPrint("读取到的信息", info)
//                    })
                    PHImageManager.default().requestImageData(for: asset, options: nil, resultHandler: { (imageData, dataUTI, orientation, info) in
                        guard let imageData = imageData else {
                            return
                        }
                        let cImage = CIImage(data: imageData)
                        debugPrint("读取到的信息", cImage?.properties)
                    })

                    break
                case let .failure(error):
                    break
                }
            }
            
        } else if type.rawValue == "public.movie" {
            guard let videoUrl = info[UIImagePickerController.InfoKey.mediaURL] as? URL else {
                return
            }
        } // else if
        

        
    } // func
}
