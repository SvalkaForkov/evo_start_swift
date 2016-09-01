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
        if lat != 0 && lon != 0 {
            let position = CLLocationCoordinate2DMake(lat, lon)
            marker = GMSMarker(position: position)
            marker.title = "Last Position"
            marker.map = viewMap
            camera = GMSCameraPosition.cameraWithLatitude(lat, longitude: lon, zoom: 15.0)
        }else{
            camera = GMSCameraPosition.cameraWithLatitude(48.857165, longitude: 2.354613, zoom: 8.0)
        }
        
        viewMap.camera = camera
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startUpdatingLocation()
        
        viewMap.settings.myLocationButton = true
        buttonSetLocation.layer.borderColor = UIColor.blueColor().CGColor
        buttonSetLocation.layer.cornerRadius = 15.0
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func onSetLocation(sender: UIButton) {
        marker.map = nil
        setLastLocation(currentLat, lon: currentLon)
        let position = CLLocationCoordinate2DMake(currentLat, currentLon)
        marker = GMSMarker(position: position)
        marker.title = "Last Position"
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
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        currentLat = locValue.latitude
        currentLon = locValue.longitude
    }
    
    func setLastLocation(lat: NSNumber, lon: NSNumber){
        logEvent("Set Last location")
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
