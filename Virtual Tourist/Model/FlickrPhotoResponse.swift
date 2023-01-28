//
//  FlickrPhotoResponse.swift
//  Virtual Tourist
//  Udacity Nanodegree Project
//  Created by Andreas Kremling on 20.10.22.
//

import Foundation

//created by help of https://www.flickr.com/services/api/flickr.photos.search.html
struct FlickrPhotoResponse: Codable {
    let photos: Photos
}

struct Photos: Codable {
    let page: Int
    let pages: Int
    let perpage: Int
    let total: Int
    let photo: [Model]
}

struct Model: Codable {
    let id: String
    let owner: String
    let secret: String
    let server: String
    let title: String
    let ispublic: Int
    let isfriend: Int
    let isfamily: Int
}
