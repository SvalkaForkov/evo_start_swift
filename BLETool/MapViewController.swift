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
    let DBG = true
    var locationManager = CLLocationManager()
    var didFindMyLocation = false
    let tagLat = "lastLat"
    let tagLon = "lastLon"
    var camera: GMSCameraPosition!
    var currentLat : Double!
    var currentLon : Double!
    var marker : GMSMarker!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.translucent = true
        navigationController?.navigationBar.barStyle = UIBarStyle.BlackTranslucent
        let lat = getLastSavedLat()
        let lon = getLastSavedLon()
        if lat == 0 && lon == 0 {
            camera = GMSCameraPosition.cameraWithLatitude(48.857165, longitude: 2.354613, zoom: 8.0)
        }else{
            let position = CLLocationCoordinate2DMake(lat, lon)
            marker = GMSMarker(position: position)
            marker.title = "Last Position"
            marker.icon = UIImage(named: "Parked")
            marker.map = viewMap
            camera = GMSCameraPosition.cameraWithLatitude(lat, longitude: lon, zoom: 15.0)
        }
        buttonSetLocation.layer.cornerRadius = 28.0
        buttonSetLocation.layer.shadowRadius = 2.0
        buttonSetLocation.layer.backgroundColor = UIColor.whiteColor().CGColor
        buttonSetLocation.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
        buttonSetLocation.layer.shadowColor = UIColor.grayColor().CGColor
        buttonSetLocation.layer.shadowOpacity = 0.5
        viewMap.camera = camera
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startUpdatingLocation()
        
        viewMap.settings.myLocationButton = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func onSetLocation(sender: UIButton) {
        if marker != nil {
            marker.map = nil
        }
        camera = GMSCameraPosition.cameraWithLatitude(currentLat, longitude: currentLon, zoom: 15.0)
        viewMap.camera = camera
        setLastLocation(currentLat, lon: currentLon)
        let position = CLLocationCoordinate2DMake(currentLat, currentLon)
        marker = GMSMarker(position: position)
        marker.title = "Last Position"
        marker.icon = UIImage(named: "Parked")
        marker.map = viewMap
        
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.AuthorizedWhenInUse {
            viewMap.myLocationEnabled = true
        }
    }
    
    func mapView(mapView: GMSMapView, idleAtCameraPosition position: GMSCameraPosition) {
        print("Camera finished")
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        print("Update locations : \(locValue.latitude) \(locValue.longitude)")
        if currentLat != nil && currentLon != nil{
            currentLat = locValue.latitude
            currentLon = locValue.longitude
        }else{
            currentLat = locValue.latitude
            currentLon = locValue.longitude
camera = GMSCameraPosition.cameraWithLatitude(currentLat, longitude: currentLon, zoom: 15.0)
                    viewMap.camera = camera
        }
    }
    
    func setLastLocation(lat: NSNumber, lon: NSNumber){
        logEvent("Set Last location to app default")
        NSUserDefaults.standardUserDefaults().setObject(lon, forKey: tagLon)
        NSUserDefaults.standardUserDefaults().setObject(lat, forKey: tagLat)
    }
    
    func getLastSavedLat() -> Double{
        let lastLat =
            NSUserDefaults.standardUserDefaults().objectForKey(tagLat)
                as? NSNumber
        if lastLat != nil {
            return Double(lastLat!)
        }else{
            return 0
        }
    }
    
    func getLastSavedLon() -> Double{
        let lastLon =
            NSUserDefaults.standardUserDefaults().objectForKey(tagLon)
                as? NSNumber
        if lastLon != nil {
            return Double(lastLon!)
        }else{
            return 0
        }
    }
    func logEvent(string :String){
        if DBG {
            print("\(string)")
        }
    }
}
