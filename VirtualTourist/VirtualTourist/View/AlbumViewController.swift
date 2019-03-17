//
//  AlbumViewController.swift
//  VirtualTourist
//
//  Created by Lee, Steve on 12/3/18.
//  Copyright © 2018 Lee, Steve. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class AlbumViewController: UIViewController {
    
    var dataController: DataController!
    var pin: Pin?
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    override func viewDidLoad() {
        print("viewdidload")
        super.viewDidLoad()
        topMapView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        setupFetchedResultsController() 
        showPin()
        bottomButton.setTitle("New Collection", for: .normal)
        bottomButton.backgroundColor = .white
        configureCellSize()
        
        guard let pin = pin else {
            return
        }
        
        // If there are no photos saved to this pin, fetch photos from Flickr
        if let photos = pin.photos, photos.count == 0 {
            print("No photos saved here")
            fetchPhotosFromFlickr(pin)
        }
    }
    
    @IBOutlet weak var bottomButton: UIButton!
    @IBOutlet weak var topMapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var closeButton: UIBarButtonItem!
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin == %@", argumentArray: [pin])
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
            print("setupFetchedResultsController")
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    @IBAction func bottomButtonTapped(_ sender: Any) {
        guard let pin = pin else {
            return
        }
        newCollection(pin)
    }

    @IBAction func closeButtonTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    func fetchPhotosFromFlickr(_ pin: Pin) {
        let lat = pin.lat
        let long = pin.long
        Client.shared().searchImage(lat: lat, long: long, totalPages: 20) { (photosArray, error) in
            if let photosArray = photosArray as [[String: AnyObject]]? {
                print("Fetching from FLICKR")
                self.storePhotos(photosArray: photosArray, pin: pin)
            }
        }
    }
    
    func storePhotos(photosArray: [[String: AnyObject]], pin: Pin) {
        for photoDictionary in photosArray {
            let imageURLString = photoDictionary["url_m"] as? String
            let photo = Photo(context: dataController.viewContext)
            photo.image = nil
            photo.pin = pin
            photo.imageURL = imageURLString
            print("Saved 1 imageURL from Flickr to DATA MODEL")
            try? dataController.viewContext.save()
        }
        performUIUpdatesOnMain {
            self.collectionView.reloadData()
        }
    }
    
    fileprivate func newCollection(_ pin: Pin) {
        for photos in fetchedResultsController.fetchedObjects! {
           dataController.viewContext.delete(photos)
            try? dataController.viewContext.save()
            print("newCollection deleted existing photo")
        }
        fetchPhotosFromFlickr(pin)
        try? dataController.viewContext.save()
        collectionView.reloadData()
    }
}

extension AlbumViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKPinAnnotationView()
        annotationView.pinTintColor = .red
        annotationView.canShowCallout = false
        return annotationView
    }
    
    func showPin() {
        topMapView.removeAnnotations(topMapView.annotations)
        let thisPin = pin!
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: thisPin.lat, longitude: thisPin.long)
        annotation.title = ""
        topMapView.addAnnotation(annotation)
    }
}

extension AlbumViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    }
}

extension AlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let section = self.fetchedResultsController.sections?[section] {
            return section.numberOfObjects
        }
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell = ImageCell()
        cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! ImageCell
        cell.imageView.image = nil

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let photo = fetchedResultsController.object(at: indexPath)
        let cell = cell as! ImageCell
        setImage(cell: cell, photo: photo, collectionView: collectionView, indexPath: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let objectToDelete = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(objectToDelete)
        try? dataController.viewContext.save()
    
        collectionView.reloadData()
    }
    
    func setImage(cell: ImageCell, photo: Photo, collectionView: UICollectionView, indexPath: IndexPath) {
        if let imageData = photo.image {
            cell.imageView.image = UIImage(data: imageData)
        } else {
            if let imageURL = photo.imageURL {
                cell.imageView.image = UIImage(named: "VirtualTourist_152")
                Client.shared().downloadImage(imagePath: imageURL) { (data, error) in
                    if let _ = error {
                        print("error")
                        return
                    } else if let data = data {
                        performUIUpdatesOnMain {
                            if let cell = collectionView.cellForItem(at: indexPath) as? ImageCell {
                                cell.imageView.image = UIImage(data: data)
                            }
                            photo.image = data
                            try? self.dataController.viewContext.save()
                        }
                    }
                }
            }
        }
    }
    
    fileprivate func configureCellSize() {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        let width = UIScreen.main.bounds.width
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: width / 3, height: width / 3)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView!.collectionViewLayout = layout
    }
}

