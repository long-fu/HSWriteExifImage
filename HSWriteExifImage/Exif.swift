//
//  Exif.swift
//  HSWriteExifImage
//
//  Created by hao shuai on 2019/8/6.
//  Copyright © 2019 onelcat. All rights reserved.
//

import Foundation
import CoreLocation
import ImageIO
import UIKit
import Photos

public func writeExifImageDataToSavedPhotosAlbum(_ imageData: Data, location:CLLocation? ,creationDate: Date? ,completionHandler: @escaping (_ result: Result<String,Error>)->Void) {
    var localIdentifier: String!
    PHPhotoLibrary.shared().performChanges({
        let creationRequest = PHAssetCreationRequest.forAsset()
        creationRequest.location = location
        creationRequest.creationDate = creationDate
        creationRequest.addResource(with: .photo, data: imageData, options: nil)
        let assetPlaceholder = creationRequest.placeholderForCreatedAsset
        //保存标识符
        localIdentifier = assetPlaceholder?.localIdentifier
    }) { (succ, error) in
        if succ {
            completionHandler(.success(localIdentifier))
        } else {
            completionHandler(.failure(error!))
        }
    }
}

public func readImageExif(file path: URL ) -> [String:Any] {
    guard let cImage = CIImage(contentsOf: path) else {
        return [:]
    }
    return cImage.properties
}

public extension UIImage {
    
    func writeExif(mediaMetadata: NSDictionary,location: CLLocation?, heading: CLHeading? = nil) -> Data? {
        
        guard let imageData = self.jpegData(compressionQuality: 1), let imgSource = CGImageSourceCreateWithData(imageData as CFData, nil) else {
            return nil
        }
        
        let metadataAsMutable = NSMutableDictionary(dictionary: mediaMetadata)
        metadataAsMutable[kCGImagePropertyOrientation] = self.imageOrientation
        if let location = location {
            let GPSDictionary = location.exifMetadata()
            metadataAsMutable[kCGImagePropertyGPSDictionary] = GPSDictionary
        }
        guard let UTI = CGImageSourceGetType(imgSource) else { return nil }; //this is the type of image (e.g., public.jpeg)
        
        let newImageData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(newImageData, UTI, 1, nil) else { return nil }
        
        //add the image contained in the image source to the destination, overidding the old metadata with our modified metadata
        CGImageDestinationAddImageFromSource(destination, imgSource, 0, metadataAsMutable);
        //tell the destination to write the image data and metadata into our data object.
        //It will return false if something goes wrong
        guard CGImageDestinationFinalize(destination) else { return nil }
        return newImageData as Data
    }
    
}

extension CLLocation {
    
    func exifMetadata(heading: CLHeading? = nil) -> NSMutableDictionary {
        
        let GPSMetadata = NSMutableDictionary()
        
        let altitudeRef = Int(self.altitude < 0.0 ? 1 : 0)
        let latitudeRef = self.coordinate.latitude < 0.0 ? "S" : "N"
        let longitudeRef = self.coordinate.longitude < 0.0 ? "W" : "E"
        
        // GPS metadata
        GPSMetadata[(kCGImagePropertyGPSLatitude as String)] = abs(self.coordinate.latitude)
        GPSMetadata[(kCGImagePropertyGPSLongitude as String)] = abs(self.coordinate.longitude)
        GPSMetadata[(kCGImagePropertyGPSLatitudeRef as String)] = latitudeRef
        GPSMetadata[(kCGImagePropertyGPSLongitudeRef as String)] = longitudeRef
        GPSMetadata[(kCGImagePropertyGPSAltitude as String)] = Int(abs(self.altitude))
        GPSMetadata[(kCGImagePropertyGPSAltitudeRef as String)] = altitudeRef
        GPSMetadata[(kCGImagePropertyGPSTimeStamp as String)] = self.timestamp.isoTime()
        GPSMetadata[(kCGImagePropertyGPSDateStamp as String)] = self.timestamp.isoDate()
        GPSMetadata[(kCGImagePropertyGPSVersion as String)] = "2.2.0.0"
        
        if self.speed >= 0 {
            GPSMetadata[kCGImagePropertyGPSSpeedRef as String] = "K"
            GPSMetadata[kCGImagePropertyGPSSpeed as String] = speed * 3.6
        }
        
        // Heading
        if self.course >= 0 {
            GPSMetadata[kCGImagePropertyGPSTrackRef as String] = "T"
            GPSMetadata[kCGImagePropertyGPSTrack as String] = course
        }
        
        if let heading = heading {
            GPSMetadata[(kCGImagePropertyGPSImgDirection as String)] = heading.trueHeading
            GPSMetadata[(kCGImagePropertyGPSImgDirectionRef as String)] = "T"
        }
        
        return GPSMetadata
    }
}

extension Date {
    func isoDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = "yyyy:MM:dd"
        return dateFormatter.string(from: self)
    }
    
    func isoTime() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = "HH:mm:ss.SSSSSS"
        return dateFormatter.string(from: self)
    }
}
