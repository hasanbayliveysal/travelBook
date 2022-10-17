//
//  MapViewController.swift
//  TravelBook
//
//  Created by Veysal on 12.09.22.
//

import UIKit
import MapKit
import CoreLocation
import CoreData
class MapViewController: UIViewController,MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var saveButton: UIButton!
    
    
    @IBOutlet weak var descText: UITextField!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var mapKit: MKMapView!
    var locationManager = CLLocationManager()
    var choosenLatitude = Double()
    var choosenLongitude = Double()
    var choosenPlace = ""
    var choosenID : UUID?
    var latitude = Double()
    var longitude = Double()
    
    override func viewDidLoad() {
        
        
        
        super.viewDidLoad()
       
        saveButton.isHidden = false
        saveButton.isEnabled = false
        if choosenPlace != "" {
            saveButton.isHidden = true
            let appdelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appdelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let stringUUId = choosenID?.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", stringUUId!)
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
                        if let title = result.value(forKey: "title") as? String{
                            nameText.text = title
                        }
                        if let subtitle = result.value(forKey: "subtitle") as? String {
                            descText.text = subtitle
                        }
                        if let latitude = result.value(forKey: "latitude") as? Double {
                            if let longitude = result.value(forKey: "longitude") as? Double {
                                self.latitude = latitude
                                self.longitude = longitude
                                locationManager.stopUpdatingLocation()
                                let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                                let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                let region = MKCoordinateRegion(center: location, span: span)
                                mapKit.setRegion(region, animated: true)
                                let annotation = MKPointAnnotation()
                                annotation.coordinate.longitude = longitude
                                annotation.coordinate.latitude = latitude
                                self.mapKit.addAnnotation(annotation)
                                annotation.title = nameText.text
                                annotation.subtitle = descText.text
                            }
                        
                        }
                        
                        
                    }
                }
                
            }catch{
                print("error")
            }
            
            
            
            
        }
        
        else {
            nameText.text = ""
            descText.text = "" 
            saveButton.isHidden = false
        }
        
        
        
        mapKit.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let gestureReconizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureReconizer: )))
        gestureReconizer.minimumPressDuration = 1.5
        mapKit.addGestureRecognizer(gestureReconizer)
        
    }
    
    func alertShown (message: String) {
        
        let alert = UIAlertController(title: "There is an error", message: message, preferredStyle: .alert)
        let okButton = UIAlertAction(title: "OK", style: .default)
        alert.addAction(okButton)
        self.present(alert, animated: true)
        
    }
    
    
    @objc func chooseLocation(gestureReconizer : UILongPressGestureRecognizer) {
        
        if gestureReconizer.state == .began {
         
            let touchedPoint = gestureReconizer.location(in: self.mapKit)
            let touchedCordinates = self.mapKit.convert(touchedPoint, toCoordinateFrom: self.mapKit)
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCordinates
            annotation.title = nameText.text
            annotation.subtitle = descText.text
            if nameText.text != "" && descText.text != "" {
            self.mapKit.addAnnotation(annotation)
            saveButton.isEnabled = true
            choosenLatitude = touchedCordinates.latitude
            choosenLongitude = touchedCordinates.longitude
            }
            else if nameText.text == "" && descText.text == "" {
                alertShown(message: "Please write name and description for selection")
            }
            else if nameText.text == "" {
                alertShown(message: "Please write a name for selection")
            }
            else if descText.text == "" {
                alertShown(message: "Please write a description for selection")
            }
            
          
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if nameText.text == "" {
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: location, span: span)
        mapKit.setRegion(region, animated: true)
        }else{
            //
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        let reuseID = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID)
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView?.canShowCallout = true
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        }else{
            pinView?.annotation = annotation
        }
        return pinView
        
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if nameText.text != "" {
            let requestLocation = CLLocation(latitude: latitude, longitude: longitude)
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks, error) in
                if let placemark = placemarks {
                    if placemark.count>0{
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.title
                        let launchOption = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOption)
                    }
                }
            }
        }
    }
   
    @IBAction func saveButtonClicked(_ sender: Any) {
        let appdelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appdelegate.persistentContainer.viewContext
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        newPlace.setValue(nameText.text!, forKey: "title")
        newPlace.setValue(descText.text!, forKey: "subtitle")
        newPlace.setValue(choosenLatitude, forKey: "latitude")
        newPlace.setValue(choosenLongitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        do {
            try context.save()
            print("youarebest")
        }catch{
            print("error")
        }
        
        
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "newData"), object: nil)
        
        navigationController?.popViewController(animated: true)
    }
    
        
}
