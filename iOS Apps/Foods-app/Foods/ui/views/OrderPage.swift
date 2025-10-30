//
//  OrderPage.swift
//  Foods
//
//  Created by Ege Özçelik on 21.10.2023.
//

import UIKit
import MapKit
import CoreLocation

class OrderPage: UIViewController {

    
    @IBOutlet weak var mapview: MKMapView!
    
    var locationManager = CLLocationManager()
    
    @IBOutlet weak var labelFoodPoints: UILabel!
    @IBOutlet weak var labelAmount: UILabel!
    @IBOutlet weak var labelAdress: UILabel!
    @IBOutlet weak var labelEstimatedTime: UILabel!
    
    var ud = UserDefaults.standard
    var currentLat = 0.0
    var currentLon = 0.0
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest//hassaslığını ayarlar. Eğer çok hassassa telefonun bataryasını çok fazla tüketir
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        
        if ud.string(forKey: "city") == "San Jose"{
            currentLat = 37.3243
            currentLon = -121.870
        }else if ud.string(forKey: "city") == "Stanford"{
            currentLat = 37.4177
            currentLon = -122.164
        }else{
            currentLat = 37.7066
            currentLon = -121.938
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        labelFoodPoints.text = "YOU HAVE +\(ud.string(forKey: "foodpoints")!) FOODPOINTS"
        labelAdress.text = "Adress: \(ud.string(forKey: "city")!), California"
        labelAmount.text = "\(ud.string(forKey: "itemCount")!) pieces, \(ud.string(forKey: "ordercount")!)₺. \(ud.string(forKey: "payment")!)"
        
       
    }
    

}
extension OrderPage: CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let lastLocation = locations[locations.count - 1]
        let lat = lastLocation.coordinate.latitude
        let long = lastLocation.coordinate.longitude
        
        let locationHome = CLLocation(latitude: currentLat, longitude: currentLon)
        let distance = locationHome.distance(from: CLLocation(latitude: lat, longitude: long))
        self.labelEstimatedTime.text = "Driver distance:\(Int(distance*0.000621)) miles"
        
        let location = CLLocationCoordinate2D(latitude: lat, longitude: long)
        let zoom = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        
        let area = MKCoordinateRegion(center: location, span: zoom)
        mapview.setRegion(area, animated: true)
        
        
        mapview.showsUserLocation = true
        
       
        
    }
}
