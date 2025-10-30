//
//  LoginViewController.swift
//  Foods
//
//  Created by Ege Özçelik on 20.10.2023.
//

import UIKit
import CoreLocation
import MapKit
class LoginViewController: UIViewController {

    
    @IBOutlet weak var imageGender: UIImageView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var segmentedCity: UISegmentedControl!
    @IBOutlet weak var segmentedGender: UISegmentedControl!
    
    @IBOutlet weak var segmentedPayment: UISegmentedControl!
    
    @IBOutlet weak var tfGirdi: UITextField!
    
    
    var City:String?
    var locationManager = CLLocationManager()
    let ud = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //San Jose 37.3243 - -121.870
        //Stanford 37.4177 - -122.164
        //Dublin 37.7066 - -121.938
        let IstLocation = CLLocationCoordinate2D(latitude: 37.3243, longitude: -121.870)
        let zoom = MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        let area = MKCoordinateRegion(center: IstLocation, span: zoom)
        mapView.setRegion(area, animated: true)
        ud.setValue("Credit Card", forKey: "payment")
        imageGender.image = UIImage(named: "Male")
        City = "San Jose"
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        
    }
    @IBAction func segmentedCityTrigger(_ sender: UISegmentedControl) {
        let zoom = MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta:  0.08)
        let chosenIndex = sender.selectedSegmentIndex
        let chosenCity = sender.titleForSegment(at: chosenIndex)
        City = chosenCity
        if chosenCity == "San Jose"{
            let IstLocation = CLLocationCoordinate2D(latitude: 37.3243, longitude: -121.870)
            let area = MKCoordinateRegion(center: IstLocation, span: zoom)
            mapView.setRegion(area, animated: true)
            
        }
        if chosenCity == "Stanford"{
            let IstLocation = CLLocationCoordinate2D(latitude: 37.4177, longitude: -122.164)
            let area = MKCoordinateRegion(center: IstLocation, span: zoom)
            mapView.setRegion(area, animated: true)
        }
        if chosenCity == "Dublin"{
            let IstLocation = CLLocationCoordinate2D(latitude: 37.7066, longitude: -121.938)
            let area = MKCoordinateRegion(center: IstLocation, span: zoom)
            mapView.setRegion(area, animated: true)
        }
        
    }
    
    @IBAction func segmentedPaymentTrigger(_ sender: UISegmentedControl) {
        let chosenIndex = sender.selectedSegmentIndex
        if chosenIndex == 0{
            ud.setValue("Credit Card", forKey: "payment")
        }else{
            ud.setValue("Cash", forKey: "payment")
        }
    }
    
    
    @IBAction func segmentedGenderTrigger(_ sender: UISegmentedControl) {
        let chosenIndex = sender.selectedSegmentIndex
        let chosenGender = sender.titleForSegment(at: chosenIndex)
        ud.setValue(chosenGender, forKey: "gender")
        imageGender.image = UIImage(named: chosenGender!)
        
    }
    

    @IBAction func btnLogin(_ sender: Any) {
        let username = self.tfGirdi.text!
        print(username)
        ud.setValue(username, forKey: "user1")
        ud.setValue(City, forKey: "city")
        ud.setValue("0", forKey: "ordercount")
        self.dismiss(animated: true, completion: nil)
        
    }
    

}

