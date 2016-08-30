//
//  MapViewController.swift
//  BLETool
//
//  Created by Xiaotu Zhang on 2016-08-25.
//  Copyright © 2016 fortin. All rights reserved.
//

import UIKit
import GoogleMaps

class MapViewController: UIViewController, CLLocationManagerDelegate ,GMSMapViewDelegate {
    @IBOutlet var buttonSetLocation: UIButton!
    @IBOutlet weak var viewMap: GMSMapView!
    
    var locationManager = CLLocationManager()
    var didFindMyLocation = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let camera: GMSCameraPosition = GMSCameraPosition.cameraWithLatitude(48.857165, longitude: 2.354613, zoom: 8.0)
        viewMap.camera = camera
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        viewMap.settings.myLocationButton = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func onSetLocation(sender: UIButton) {
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.AuthorizedWhenInUse {
            viewMap.myLocationEnabled = true
        }
    }
    
//    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
//        if !didFindMyLocation {
//            let myLocation: CLLocation = change[NSKeyValueChangeNewKey] as! CLLocation
//            viewMap.camera = GMSCameraPosition.cameraWithTarget(myLocation.coordinate, zoom: 10.0)
//            viewMap.settings.myLocationButton = true
//            
//            didFindMyLocation = true
//        }
//    }
}
