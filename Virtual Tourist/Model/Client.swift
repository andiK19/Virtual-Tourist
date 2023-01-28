//
//  Client.swift
//  Virtual Tourist
//  Udacity Nanodegree Project
//  Created by Andreas Kremling on 20.10.22.
//

import Foundation

class Client {
    //individual API-key
    static let apiKey = "84b6d21400f234a460a6cfd76b343daa"
    //Flickr baseUrl
    static let base = "https://api.flickr.com/services/rest"
    
    //Define endpoint for photo search using api-ley and latitude and longitude of pin
    enum Endpoints {
        case photoSearch(Double, Double)
        
        var stringValue: String {
            switch self {
            case .photoSearch(let lat, let lon):
                return "\(base)/?method=flickr.photos.search&api_key=\(apiKey)&lat=\(lat)&lon=\(lon)&per_page=30&page=1&format=json&nojsoncallback=1"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    //method to find appropriate on flickr - created by help of On The Map project
    class func findImages(lat: Double, lon: Double, completion: @escaping ([String], Error?) -> Void) {
        //create request with latitude and longitude
        var request = URLRequest(url: Endpoints.photoSearch(lat, lon).url)
        request.httpMethod = "GET"
        //add necessary values to request
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let findTask = URLSession.shared.dataTask(with: request) { data, response, error in
            //get back data in case of completion
            guard let data = data else {
                DispatchQueue.main.async {
                    completion([], error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
                //decode
                let response = try decoder.decode(FlickrPhotoResponse.self, from: data)
                //define array for urls
                var urlsOfPhotos: [String] = []
                
                for photo in response.photos.photo {
                    //set up by help of https://www.flickr.com/services/api/misc.urls.html
                    let url = "https://live.staticflickr.com/\(photo.server)/\(photo.id)_\(photo.secret).jpg"
                    //add urls to array
                    urlsOfPhotos.append(url)
                }
                //dispatch array
                DispatchQueue.main.async {
                    completion(urlsOfPhotos, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion([], error)
                }
            }
        }
        findTask.resume()
    }
    
    //method to download image using url
    class func downloadImage(url: String, completion: @escaping (Data) -> Void) {
        //create constant with URL
        let url = URL(string: url)
        //and get data
        if let url = url {
            let downloadTask = URLSession.shared.dataTask(with: url) {
                data, response, error in
                guard let data = data else {
                    return
                }
                DispatchQueue.main.async {
                    completion(data)
                }
            }
            downloadTask.resume()
        }
    }
}
