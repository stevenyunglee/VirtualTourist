//
//  Client.swift
//  VirtualTourist
//
//  Created by Lee, Steve on 12/7/18.
//  Copyright © 2018 Lee, Steve. All rights reserved.
//

import UIKit

class Client {

    var session = URLSession.shared
    
    class func shared() -> Client {
        struct Singleton {
            static var shared = Client()
        }
        return Singleton.shared
    }
    
    func searchImage(lat: Double, long: Double, totalPages: Int?, completion: @escaping (_ result: [[String : AnyObject]]?, _ error: Error?) -> Void) {
        
        let bbox = bboxString(lat: lat, long: long)
        
        var randomPage: Int {
            if let totalPages = totalPages {
                let page = min(totalPages, 4000/FlickrParameterValues.PhotosPerPage)
                return Int(arc4random_uniform(UInt32(page)) + 1)
            }
            return 1
        }
        
        let parameters = [
            FlickrParameterKeys.Method           : FlickrParameterValues.SearchMethod
            , FlickrParameterKeys.APIKey         : FlickrParameterValues.APIKey
            , FlickrParameterKeys.Format         : FlickrParameterValues.ResponseFormat
            , FlickrParameterKeys.Extras         : FlickrParameterValues.MediumURL
            , FlickrParameterKeys.NoJSONCallback : FlickrParameterValues.DisableJSONCallback
            , FlickrParameterKeys.SafeSearch     : FlickrParameterValues.UseSafeSearch
            , FlickrParameterKeys.BoundingBox    : bbox
            , FlickrParameterKeys.PhotosPerPage  : "\(FlickrParameterValues.PhotosPerPage)"
            , FlickrParameterKeys.Page           : "\(randomPage)"
        ]
        
        var request = buildURLFromParameters(parameters)
        
        _ = taskForGETMethod(request) { (result, error) in
            if let error = error {
                print("this is the error \(error)")
                completion(nil, error)
            }
            
            guard let photosDictionary = result?["\(FlickrResponseKeys.Photos)"] as? [String : AnyObject] else {
                completion(nil, error)
                return
            }
            
            guard let photosArray = photosDictionary[FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                completion(nil, error)
                return
            }
            
            if photosArray.count == 0 {
                completion(nil, error)
                return
            } else {
//
//                let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
//                let photoDictionary = photosArray[randomPhotoIndex] as [String: AnyObject]
                completion(photosArray, nil)
            }
        }
    }
    
    func downloadImage( imagePath:String, completionHandler: @escaping (_ imageData: Data?, _ errorString: String?) -> Void){
        let session = URLSession.shared
        let imgURL = NSURL(string: imagePath)
        let request: NSURLRequest = NSURLRequest(url: imgURL! as URL)
        
        let task = session.dataTask(with: request as URLRequest) {data, response, downloadError in
            
            if downloadError != nil {
                completionHandler(nil, "Could not download image \(imagePath)")
            } else {
                
                completionHandler(data, nil)
            }
        }
        
        task.resume()
    }
    
}

extension Client {
    
    func taskForGETMethod(_ url: URLRequest, completionHandlerForGET: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        
        /* 2/3. Build the URL, Configure the request */
        var request = url
        
        /* 4. Make the request */
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForGET(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                sendError("There was an error with your request: \(error!)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            /* 5/6. Parse the data and use the data (happens in completion handler) */
            self.convertDataWithCompletionHandler(data, completionHandlerForConvertData: completionHandlerForGET)
        }
        
        /* 7. Start the request */
        task.resume()
        
        return task
    }
    
    func buildURLFromParameters(_ parameters: [String:String], withPathExtension: String? = nil) -> URLRequest {
        
        var components = URLComponents()
        components.scheme = Flickr.APIScheme
        components.host = Flickr.APIHost
        components.path = Flickr.APIPath + (withPathExtension ?? "")
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return URLRequest(url: components.url!)
    }
    
    private func bboxString(lat: Double, long: Double) -> String {
        let minLon = max((long - Client.Flickr.SearchBBoxHalfHeight), Client.Flickr.SearchLonRange.0)
        let minLat = max((lat - Client.Flickr.SearchBBoxHalfWidth), Client.Flickr.SearchLatRange.0)
        let maxLon = min((long + Client.Flickr.SearchBBoxHalfHeight), Client.Flickr.SearchLonRange.1)
        let maxLat = min((lat + Client.Flickr.SearchBBoxHalfWidth), Client.Flickr.SearchLatRange.1)
            return("\(minLon),\(minLat),\(maxLon),\(maxLat)")
    }
    
    private func convertDataWithCompletionHandler(_ data: Data, completionHandlerForConvertData: (_ result: AnyObject?, _ error: NSError?) -> Void) {
        var parsedResult: AnyObject? = nil
        do {
            
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! AnyObject
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandlerForConvertData(parsedResult, nil)
    }
}
