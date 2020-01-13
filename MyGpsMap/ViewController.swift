//
//  ViewController.swift
//  MyGpsMap
//
//  Created by shinobee on 2019/11/24.
//  Copyright © 2019 shinobee. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate {
    var myLock = NSLock()
    let goldenRatio = 1.618
    
    @IBOutlet var mapView: MKMapView!
    var locationManager: CLLocationManager!
    @IBOutlet weak var locationName: UITextField!

    // https://www.finds.jp/rgeocode/index.html.ja
    let FMT_url_rev_geo = "https://www.finds.jp/ws/rgeocode.php?lat=%f&lon=%f&json"
    @IBAction func clickLocation(_ sender: Any) {
        myLock.lock()
        let latitude = mapView.region.center.latitude
        let longitude = mapView.region.center.longitude
        myLock.unlock()
        
        // https://www.finds.jp/ws/rgeocode.php?lat=35.6804725&lon=139.7661837
        //   東京都千代田区丸の内一丁目
        let url = URL(string: String(format: FMT_url_rev_geo, latitude, longitude))!
        let request = URLRequest(url: url)
        let session = URLSession.shared
        session.dataTask(with: request) {
            (data, response, error) in
            if error == nil, let data = data, let response = response as? HTTPURLResponse {
                print("statusCode: \(response.statusCode)")
                let jsonString: String = String(data: data, encoding: String.Encoding.utf8) ?? ""
                var locationData =  jsonString.data(using: String.Encoding.utf8)!
                do {
                    let items = try JSONSerialization.jsonObject(with: locationData) as! Dictionary<String, Any>
                    let result = items["result"] as! Dictionary<String, Any>
                    let prefecture = result["prefecture"] as! Dictionary<String, Any>
                    let municipality = result["municipality"] as! Dictionary<String, Any>
                    let local = result["local"] as! Array<Any>
                    let local0 = local[0] as! Dictionary<String, Any>
                    self.locationName.text = prefecture["pname"] as! String
                    self.locationName.text! += municipality["mname"] as! String
                    self.locationName.text! += local0["section"] as! String

                } catch {
                    print(error)
                }
                
            }
        }.resume()

    }
    
    @IBAction func clickZoomin(_ sender: Any) {
        print("[DBG]clickZoomin")
        myLock.lock()
        if (0.005 < mapView.region.span.latitudeDelta / goldenRatio) {
            print("[DBG]latitudeDelta-1 : " + mapView.region.span.latitudeDelta.description)
            var regionSpan:MKCoordinateSpan = MKCoordinateSpan()
            regionSpan.latitudeDelta = mapView.region.span.latitudeDelta / goldenRatio
//            regionSpan.latitudeDelta = mapView.region.span.longitudeDelta / GoldenRatio
            mapView.region.span = regionSpan
            print("[DBG]latitudeDelta-2 : " + mapView.region.span.latitudeDelta.description)
        }
        myLock.unlock()
    }
    @IBAction func clickZoomout(_ sender: Any) {
        print("[DBG]clickZoomout")
        myLock.lock()
        if (mapView.region.span.latitudeDelta * goldenRatio < 150.0) {
            print("[DBG]latitudeDelta-1 : " + mapView.region.span.latitudeDelta.description)
            var regionSpan:MKCoordinateSpan = MKCoordinateSpan()
            regionSpan.latitudeDelta = mapView.region.span.latitudeDelta * goldenRatio
//            regionSpan.latitudeDelta = mapView.region.span.longitudeDelta * GoldenRatio
            mapView.region.span = regionSpan
            print("[DBG]latitudeDelta-2 : " + mapView.region.span.latitudeDelta.description)
        }
        myLock.unlock()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        locationManager = CLLocationManager()
        locationManager.delegate = self

        locationManager.startUpdatingLocation()
        locationManager.requestWhenInUseAuthorization()

        mapView.showsUserLocation = true
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations:[CLLocation]) {
        let longitude = (locations.last?.coordinate.longitude.description)!
        let latitude = (locations.last?.coordinate.latitude.description)!
        print("[DBG]longitude : " + longitude)
        print("[DBG]latitude : " + latitude)

        myLock.lock()
        mapView.setCenter((locations.last?.coordinate)!, animated: true)
        myLock.unlock()
    }
}
