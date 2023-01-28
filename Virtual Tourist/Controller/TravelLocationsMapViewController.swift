//
//  ViewController.swift
//  Virtual Tourist
//  Udacity Nanodegree Project
//  Created by Andreas Kremling on 19.10.22.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate {
    //outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deleteLocationsButton: UIBarButtonItem!
    @IBOutlet weak var changeLocationsButton: UIBarButtonItem!
    @IBOutlet weak var deleteLabel: UILabel!
    @IBOutlet weak var changeLabel: UILabel!
    
    //array for existing pins
    var pins: [Pin] = []
    
    //get dataController (solved by help of https://knowledge.udacity.com/questions/865819)
    var dataController: DataController = (UIApplication.shared.delegate as! AppDelegate).dataController
    
    //some Boole-variable to save user-status
    var deleteButtonTapped = false
    var changeLocationButtonTapped = false
    
    //variable to save Pin which was tapped latest
    var latestPinClicked = Pin()
    
    //constant for UserDefaults - necessary for setting latest region when app starts
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //set up the deleteLabel
        setupDeleteLabel()
        setupChangeLabel()
        //show latest region on map
        if let mapRegion = loadLatestRegion(withKey: "latestRegion") {
            mapView.region = mapRegion
        }
        //show pins in store
        showExistingPins()
        //add gesture recognizer to be able to set new pins with holding a position
        addGestureRecognizer(gestureRecognizerType: UILongPressGestureRecognizer.self)
        //check how many pins exist and show appropriate alert and set status of buttons
        if pins.count == 0 {
            presentAlert(title: "Data successfully loaded", message: "No location found")
            deleteLocationsButton.isEnabled = false
            changeLocationsButton.isEnabled = false
        }
        if pins.count == 1 {
            presentAlert(title: "Data successfully loaded", message: "1 location found")
        } else {
            presentAlert(title: "Data successfully loaded", message: "\(pins.count) locations found")
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        //save the region visited latest
        saveLatestRegion(withKey: "latestRegion")
    }
    
    //method to setup the changeLocationButton
    func setupChangeLocationButton() {
        if pins.isEmpty == false {
            changeLocationsButton.isEnabled = true
        } else {
            changeLocationsButton.isEnabled = false
        }
    }
    
    //is called when deleteLocationsButton is tapped
    @IBAction func deleteTapped(_ sender: Any) {
        //check user status and set appropriate properties
        if deleteButtonTapped == true {
            deleteLocationsButton.title = "Delete"
            deleteButtonTapped = false
            deleteLabel.isHidden = true
            changeLocationsButton.isEnabled = true
        }
        else {
            deleteLocationsButton.title = "Done"
            deleteButtonTapped = true
            deleteLabel.isHidden = false
            changeLocationsButton.isEnabled = false
        }
    }
    
    //is called when change Locations button is tapped
    @IBAction func changeTapped(_ sender: Any) {
        //check user status and set appropriate properties
        if changeLocationButtonTapped == false {
            changeLocationButtonTapped = true
            changeLocationsButton.title = "End changes"
            changeLabel.isHidden = false
            deleteLocationsButton.isEnabled = false
        } else {
            changeLocationButtonTapped = false
            changeLocationsButton.title = "Change Locations"
            changeLabel.isHidden = true
            deleteLocationsButton.isEnabled = true
        }
    }
    
    
    //Method to show an alert
    func presentAlert(title: String, message: String) {
        let alertViewController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        present(alertViewController, animated: true)
        //show it for just 2 seconds
        let when = DispatchTime.now() + 2
        DispatchQueue.main.asyncAfter(deadline: when) {
            alertViewController.dismiss(animated: true, completion: nil)
        }
    }
    
    //Method to setup the delete-Label
    func setupDeleteLabel() {
        deleteLabel.backgroundColor = UIColor.red.withAlphaComponent(0.5)
        deleteLabel.textColor = .white
        if deleteButtonTapped == false {
            deleteLabel.isHidden = true
        } else {
            deleteLabel.isHidden = false
        }
    }
    
    //Method to setup the change-Label
    func setupChangeLabel() {
        changeLabel.backgroundColor = UIColor.blue.withAlphaComponent(0.5)
        changeLabel.textColor = .white
        if changeLocationButtonTapped == false {
            changeLabel.isHidden = true
        } else {
            changeLabel.isHidden = false
        }
    }
    
    //method to show pins existing in store
    func showExistingPins() {
        //remove current annotations..
        let allAnnotations = mapView.annotations
        mapView.removeAnnotations(allAnnotations)
        //..and get Pins from Persistent Store
        pins = fetchPinsFromStore()
        //go through all fetched pins...
        for pin in pins {
            //...save pin-location in a constant...
            let coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            //...and add each pin to the map using the coordinate-attributes
            addPinToMapView(coordinate)
        }
    }
    
    //method to fetch pins from store - set up with help of Mooskine-project
    func fetchPinsFromStore(predicate: NSPredicate? = nil) -> [Pin] {
        //create fetch-Request
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        //filter the request by the predicate - will be the coordinates when method is called
        if let predicate = predicate {
            fetchRequest.predicate = predicate
        }
        //sort the request by creationDate
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        //get results
        do {
            let result = try dataController.viewContext.fetch(fetchRequest)
            return result
        } catch {
            //show an error message in case
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    func addPinToMapView(_ coordinate: CLLocationCoordinate2D) {
        //create annotation and save passed coordinates
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        //add annotation to mapview
        mapView.addAnnotation(annotation)
    }
    
    //setup with help of https://stackoverflow.com/questions/28058082/swift-long-press-gesture-recognizer-detect-taps-and-long-press
    //method to add gesture recognizer
    func addGestureRecognizer<GestureRecognizer: UIGestureRecognizer>(gestureRecognizerType: GestureRecognizer.Type) {
        let gestureRecognizer = GestureRecognizer(target: self, action: #selector(longPressGestureMethod))
        mapView.addGestureRecognizer(gestureRecognizer)
    }
    
    //method for recognition of long-press-gesture
    @objc func longPressGestureMethod(gestureRecognizer: UIGestureRecognizer) {
        //create gesture recognizer to detect holding at a specific point
        if let gestureLongPressRecognizer = gestureRecognizer as? UILongPressGestureRecognizer {
            //to prevent double tapping
            if gestureRecognizer.state == UIGestureRecognizer.State.began {
                //save location of tap..
                let pinLocation = gestureLongPressRecognizer.location(in: mapView)
                //..and its coordinates..
                let coordinate = mapView.convert(pinLocation, toCoordinateFrom: mapView)
                //..and add to map and store
                addPinToMapView(coordinate)
                addPinToStore(coordinate)
                showExistingPins()
            }
        }
    }
    //method to add pin to the persistent store
    func addPinToStore(_ coordinate: CLLocationCoordinate2D) {
        //create pin...
        let pin = Pin(context: dataController.viewContext)
        //...and save coordinates
        pin.latitude = coordinate.latitude
        pin.longitude = coordinate.longitude
        //check if pin already exists to prevent double storage
        if pins.contains(where: { $0.latitude == pin.latitude && $0.longitude == pin.longitude }) {
        } else {
            //and append it to array if it´s new
            pins.append(pin)
            if pins.count > 0 {
                //enable delete-button and change-button only if there is minimum 1 pin
                deleteLocationsButton.isEnabled = true
                changeLocationsButton.isEnabled = true
            }
            //and save
            try? dataController.viewContext.save()
        }
    }
    
    //change Pin-style
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "myPin")
        //set pin color and draggable property
        annotationView.pinTintColor = .red
        annotationView.isDraggable = true
        return annotationView
    }
    
    
    //method for selection of pin
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        //save coordinates of latest tapped pin
        let coordinatesOfLatestPin = view.annotation?.coordinate
        //get pin from the store
        if let pinCoordinates = coordinatesOfLatestPin {
            //define a predicate
            let predicate = NSPredicate(format: "latitude == %@ && longitude == %@", argumentArray: [pinCoordinates.latitude, pinCoordinates.longitude])
            //get the pins from store and filter with defined predicate
            let pins = fetchPinsFromStore(predicate: predicate)
            //save latest tapped pin
            if pins.count > 0 {
                latestPinClicked = pins[0]
            }
        }
        //save annotation
        let annotation = view.annotation
        //check if changeLocationButton was tapped
        if changeLocationButtonTapped == false {
            //check if deleteButton was tapped before
            if deleteButtonTapped == false {
                //instantiate PhotoAlbumViewController
                let photoAlbumViewController = self.storyboard!.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
                let coordinatesOfPin = view.annotation?.coordinate
                //define a predicate
                if let pinCoordinates = coordinatesOfPin {
                    let predicate = NSPredicate(format: "latitude == %@ && longitude == %@", argumentArray: [pinCoordinates.latitude, pinCoordinates.longitude])
                    //get the pins from store and filter with defined predicate
                    let pins = fetchPinsFromStore(predicate: predicate)
                    //check if there are pins in the array
                    if pins.count > 0 {
                        //and save tapped pin
                        latestPinClicked = pins[0]
                        //and save tapped pin for upcoming VC
                        photoAlbumViewController.pin = pins[0]
                    }
                    photoAlbumViewController.dataController = dataController
                    //Show next VC
                    navigationController?.pushViewController(photoAlbumViewController, animated: true)
                    //deselect the annotation on mapView
                    mapView.deselectAnnotation(view.annotation, animated: false)
                }
            }
            //if delete-button was tapped, tapped pin shall be deleted
            else {
                //search for tapped pin in the array
                for pin in pins {
                    if pin.latitude == view.annotation?.coordinate.latitude && pin.longitude == view.annotation?.coordinate.longitude {
                        //and delete the pin
                        dataController.viewContext.delete(pin)
                        pins.removeAll()
                        showExistingPins()
                        //check if it was the last pin and set according properties
                        if pins.count == 0 {
                            deleteLabel.isHidden = true
                            deleteLocationsButton.title = "Delete"
                            deleteLocationsButton.isEnabled = false
                            deleteButtonTapped = false
                        }
                    }
                }
                do {
                    //save changes
                    try dataController.viewContext.save()
                } catch {
                    //present an alert in case of error
                    presentAlert(title: "Error", message: "There was an error during deletion")
                }
                //and annotation shall be removed
                mapView.removeAnnotation(annotation!)
                return
            }
        }
        //if changeLocations-Button was tapped
        else {
            //as prevention for double-tapping - do nothing when exisiting pin is tapped
            if pins.contains(where: { $0.latitude == annotation?.coordinate.latitude && $0.longitude == annotation?.coordinate.longitude }) {
            }
            else {
                //delete original location
                dataController.viewContext.delete(latestPinClicked)
                //and add new pin to the store
                addPinToStore(annotation!.coordinate)
                
                do {
                    //save changes
                    try dataController.viewContext.save()
                    showExistingPins()
                    
                } catch {
                    presentAlert(title: "Error", message: "There was an error during location change")
                }
            }
        }
    }
}



extension TravelLocationsMapViewController {
    //following two methods created by help of https://stackoverflow.com/questions/39214923/using-nsuserdefaults-to-save-region-of-an-mkmapview
    //method to save the latest region before app is stopped
    func saveLatestRegion(withKey key:String) {
        let latestLocationData = [mapView.region.center.latitude, mapView.region.center.longitude,
                                  mapView.region.span.latitudeDelta, mapView.region.span.longitudeDelta]
        defaults.set(latestLocationData, forKey: key)
    }
    //method to load latest region after app start
    func loadLatestRegion(withKey key:String) -> MKCoordinateRegion? {
        guard let region = defaults.object(forKey: key) as? [Double] else { return nil }
        let center = CLLocationCoordinate2D(latitude: region[0], longitude: region[1])
        let span = MKCoordinateSpan(latitudeDelta: region[2], longitudeDelta: region[3])
        return MKCoordinateRegion(center: center, span: span)
    }
}

