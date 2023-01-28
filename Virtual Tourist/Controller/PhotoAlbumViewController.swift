//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//  Udacity Nanodegree Project
//  Created by Andreas Kremling on 19.10.22.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    //outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newImageCollectionButton: UIButton!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    //define variable for chosen pin
    var pin: Pin!
    
    //get dataController (solved by help of https://knowledge.udacity.com/questions/865819)
    var dataController: DataController = (UIApplication.shared.delegate as! AppDelegate).dataController
    
    //array for urls and photos
    var urlsOfPhotos: [String] = []
    var photos: [Photo] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //setup Layout
        setupFlowLayout()
        //fetch the photos from the store and save in array
        photos = fetchPhotosFromStore()
        //add pin to the mapView
        addPinToMap()
        //zoom into the region of the selected pin
        showSelectedRegion()
        //Check if there are photos in the array now
        if photos.count == 0 {
        //load new photos using pin coordinates
        Client.findImages(lat: pin.latitude, lon: pin.longitude, completion: implementLoadedPhotos(photoUrl:error:))
        }
    }
    
    @IBAction func newImageCollectionButtonTapped(_ sender: Any) {
        newImageCollectionButton.isEnabled = false
        //delete photos from store
        for (i,_) in photos.enumerated() {
            deletePhotoFromStore(index: i)
        }
        //empty the arrays
        urlsOfPhotos = []
        photos = []
        //get new photos
        Client.findImages(lat: pin.latitude, lon: pin.longitude, completion: implementLoadedPhotos(photoUrl:error:))
    }
    
    
    func setupFlowLayout() {
        //create variables for height, width and space between images
        var width = CGFloat()
        var height = CGFloat()
        let space: CGFloat = 2.0
        //set item size to have 3 items per row in portrait mode and 6 items in landscape mode + consider spaces
        if view.frame.width < view.frame.height {
            width = (view.frame.size.width - (2 * space)) / 3.0
            height = (view.frame.size.width - (2 * space)) / 3.0
        } else {
            width = (view.frame.size.width - (5 * space)) / 6.0
            height = (view.frame.size.width - (5 * space)) / 6.0
        }
        //set calculated values for width and height to flowLayout
        flowLayout.itemSize = CGSize(width: width , height: height)
    }
    
    //method to fetch photos from store - set up with help of Mooskine-project
    func fetchPhotosFromStore() -> [Photo] {
        //Create fetch-request
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        //sort the request by creationDate
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        // filter request by pin
        fetchRequest.predicate = NSPredicate(format: "pin == %@", pin)
        //and get the results
                do {
                    let result = try dataController.viewContext.fetch(fetchRequest)
                    return result
                } catch {
                    //show message in case of error
                    fatalError("The fetch could not be performed: \(error.localizedDescription)")
                }
            }

    //method to add pin to the mapView
    func addPinToMap() {
        //use coordinates of selected pin...
        let coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        //create annotation
        let annotation = MKPointAnnotation()
        //set coordinates of annotation
        annotation.coordinate = coordinate
        //and add annotation to the mapview
        mapView.addAnnotation(annotation)
    }
    
    //method to zoom into the region of the selected pin (with help of https://stackoverflow.com/questions/31040667/zoom-in-on-user-location-swift)
    func showSelectedRegion() {
        //define width and height of map
        let latSpan:CLLocationDegrees = 0.03
        let lonSpan:CLLocationDegrees = 0.03
            
        //define span using defined width and span
        let span = MKCoordinateSpan(latitudeDelta: latSpan, longitudeDelta: lonSpan)
        //define region using location and span
        let location = CLLocationCoordinate2DMake(pin.latitude, pin.longitude)
        let region = MKCoordinateRegion(center: location, span: span)
        
        //set region on the mapView
        mapView.setRegion(region, animated: false)
        }
    
    //method to handle photos from Flickr
    func implementLoadedPhotos(photoUrl: [String], error: Error?) {
        self.urlsOfPhotos = photoUrl
        collectionView.reloadData()
        //If no images for the pin are available
        if photoUrl.count == 0 {
            //create label and set it up
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
            label.text = "No images available"
            label.textAlignment = .center
            collectionView.backgroundView = label
        }
        //go through all urls
        for url in photoUrl {
            //and download the photos
            Client.downloadImage(url: url) { (data) in
                //add each photo to store
                let photo = self.addPhotoToStore(data: data)
                //insert it in the array
                self.photos.insert(photo, at: 0)
                //reload the collection view to update
                self.collectionView.reloadData()
                
            }
        }
        //Enable the button
        newImageCollectionButton.isEnabled = true
    }
    
    //method to add photo to the store
    func addPhotoToStore(data: Data) -> Photo {
        //definition of constant for the photo
        let photo = Photo(context: self.dataController.viewContext)
        //set the properties according data model
        photo.pin = self.pin
        photo.image = data
        //and save
        try? dataController.viewContext.save()
        
        return photo
    }
    
    //method to delete images from store
    func deletePhotoFromStore(index: Int) {
        //delete chosen photo
        dataController.viewContext.delete(photos[index])
        //and save
        try? dataController.viewContext.save()
    }
    
    //change Pin-style
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "something")
        //change pin color
        annotationView.pinTintColor = .red
        return annotationView
    }
    
    //appropriate number of items
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if photos.count == 0 {
            return 1
        }
        else {
            return photos.count
        }
    }
    
//set items in collectionView
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //define cell and placeholder-photo
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumCell", for: indexPath) as! PhotoAlbumCollectionViewCell
        let placeholder = UIImage(named: "VirtualTourist")
        
        // check if download is still ongoing
        if photos.count > indexPath.row {
            //show downloaded images
            if let data = photos[indexPath.row].image {
                cell.imageView.image = UIImage(data: data)
                //or placeholder in case of not finished download
            } else {
                cell.imageView.image = placeholder
            }
        } else {
            //or placeholder in case of not finished download
            cell.imageView.image = placeholder
        }
        
        return cell
    }
    
    //delete photo when selected
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //get the index of the selected photo
        let indexOfPicToDelete = indexPath.row
        //delete it from the store and array
        deletePhotoFromStore(index: indexOfPicToDelete)
        photos.remove(at: indexOfPicToDelete)
        collectionView.reloadData()
    }
}
