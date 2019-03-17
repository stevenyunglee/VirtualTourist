//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Lee, Steve on 12/3/18.
//  Copyright © 2018 Lee, Steve. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {

    var dataController: DataController!
    
    var fetchedResultsController: NSFetchedResultsController<Pin>!

    @IBOutlet weak var mapView: MKMapView!
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "lat", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pins")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        mapView.delegate = self
        setupFetchedResultsController()
        longGesture()
        showPin()
        }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is AlbumViewController {
            guard let pin = sender as? Pin else {
                return
            }
            print("here")
            let controller = segue.destination as! AlbumViewController
            controller.pin = pin
            controller.dataController = dataController
        }
    }
    
    func longGesture() {
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(addPin(longGesture:)))
        longGesture.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longGesture)
    }
    
    @objc func addPin(longGesture: UIGestureRecognizer) {
        if longGesture.state == .began {
            let touchPoint = longGesture.location(in: mapView)
            let coords = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: coords.latitude, longitude: coords.longitude)
            mapView.addAnnotation(annotation)
            savePin(lat: coords.latitude, long: coords.longitude)
        }
    }
    
    // Shows pins on map from the fetchedResultsController
    
    func showPin() {
        mapView.removeAnnotations(mapView.annotations)
        var annotations = [MKPointAnnotation]()
        let pins = fetchedResultsController.fetchedObjects
        
        for pin in pins! where pin.lat != 0.0 && pin.long != 0.0 {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: pin.lat, longitude: pin.long)
            annotation.title = ""
            annotations.append(annotation)
        }
        
        mapView.addAnnotations(annotations)
        mapView.showAnnotations(mapView.annotations, animated: true)
    }
    
    // Adds a new pin to the end of the `pin` array
    
    func savePin(lat: Double, long: Double) {
        let pin = Pin(context: dataController.viewContext)
        pin.lat = lat
        pin.long = long
        try? dataController.viewContext.save()
        print("Pin saved at \(pin.lat) \(pin.long).")
    }

    private func loadPin(lat: Double, long: Double) -> Pin? {
        let predicate = NSPredicate(format: "lat == %lf AND long == %lf", lat, long)
        print(lat)
        print(long)
        var pin: Pin?
        do {
            try pin = DataController.shared().fetchPin(predicate, dc: dataController)
        } catch {
            print("error")
        }
        return pin
    }
}

extension MapViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKPinAnnotationView()
        annotationView.pinTintColor = .red
        annotationView.canShowCallout = false
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let lat: Double! = view.annotation?.coordinate.latitude
        let long: Double! = view.annotation?.coordinate.longitude
        if let pin = loadPin(lat: lat, long: long) {
            print("loaded this pin")
            performSegue(withIdentifier: "showPhotos", sender: pin)
        } else {
            print("not loaded")
        }
    }
    
//    func defaultCoords() {
//        var coord = mapView.centerCoordinate
//        UserDefaults.standard.set(coord.latitude, forKey: "defaultLat")
//        UserDefaults.standard.set(coord.longitude, forKey: "defaultLong")
//    }
}
