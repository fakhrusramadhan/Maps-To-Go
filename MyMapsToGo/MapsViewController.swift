//
//  ViewController.swift
//  MyMapsToGo
//
//  Created by Fakhrus Ramadhan on 26/04/18.
//  Copyright © 2018 Fakhrus Ramadhan. All rights reserved.
//

import UIKit
import GoogleMaps
import Alamofire

class MapsViewController: UIViewController {
    
    @IBOutlet weak var view_gmaps: UIView!
    @IBOutlet weak var lb_distance: UILabel!
    @IBOutlet weak var lb_duration: UILabel!
    @IBOutlet weak var bt_travel: UIButton!
    
    @IBOutlet weak var tf_from: UITextField!
    @IBOutlet weak var tf_to: UITextField!
    
        
    var dataGmaps = TheRoute()
    
    var mapView : GMSMapView?
    
    var travelMode : String?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        travelMode = "driving"
       firstGmapsDeclaration()

    }
    
    func firstGmapsDeclaration() {
        
        let camera = GMSCameraPosition.camera(withLatitude: -7.801506, longitude: 110.364759, zoom: 10)
        self.mapView = GMSMapView.map(withFrame: self.view_gmaps.bounds, camera: camera)
        
        self.mapView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        
        self.mapView?.settings.compassButton = true
        self.mapView?.isMyLocationEnabled = true
        self.mapView?.settings.myLocationButton = true
        
        nightModeMaps(mapView: mapView!)
        self.view_gmaps.insertSubview(self.mapView!, at:0)
    }

    
    
    func loadViewMap(latStart : Double, lngStart : Double, latEnd : Double, lngEnd : Double, zoom : Float) {
        // Create a GMSCameraPosition that tells the map to display the
        // coordinate -33.86,151.20 at zoom level 6.

        self.mapView?.clear()
        
        // Creates a marker in the center of the map.
        let markerStart = GMSMarker()
        markerStart.position = CLLocationCoordinate2D(latitude: latStart, longitude: lngStart)
        markerStart.title = "Start From Here"
        markerStart.snippet = travelMode
        markerStart.icon = GMSMarker.markerImage(with: UIColor.green)
        markerStart.map = mapView
        
        // Creates a marker in the center of the map.
        let markerEnd = GMSMarker()
        markerEnd.position = CLLocationCoordinate2D(latitude: latEnd, longitude: lngEnd)
        markerEnd.title = "Finish Here"
        markerEnd.snippet = travelMode
        markerEnd.map = mapView
        
        let cameraPosition = GMSCameraPosition.camera(withLatitude: latEnd, longitude: lngEnd, zoom: zoom)
        self.mapView?.animate(to: cameraPosition)
        
        loopForRoutes(mapView: mapView!)
        

    }
    
    func nightModeMaps (mapView : GMSMapView) {
        
        do {
            // Set the map style by passing the URL of the local file.
            if let styleURL = Bundle.main.url(forResource: "style", withExtension: "json") {
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            } else {
                NSLog("Unable to find style.json")
            }
        } catch {
            NSLog("One or more of the map styles failed to load. \(error)")
        }
        
        
        self.view_gmaps.insertSubview(mapView, at:0)

    }
    
    
    func callNetwork(origin : String, destination : String, mode : String) {
        
        let params : Parameters = [
            
            "key":"\(API_KEY)",
            "origin":"\(origin)",
            "destination":"\(destination)",
            "avoid":"highways",
            "mode":"\(mode)",
            "region":"ID"
        ]
        
        let urlString = "\(BASE_URL)"
        
        Alamofire.request(urlString, parameters: params).responseJSON { (response) in
            
            let result = response.data
            
            do {
                let gmapsResult = try JSONDecoder().decode(Gmaps.self, from: result!)

                print(response)
                
                if gmapsResult.routes.count != 0 {
                    self.dataGmaps = gmapsResult.routes[0].legs[0].steps
                    
                    let distance = gmapsResult.routes[0].legs[0].distance.text
                    let time = gmapsResult.routes[0].legs[0].duration.text
                    
                    let latStart = gmapsResult.routes[0].legs[0].startLocation.lat
                    let latEnd = gmapsResult.routes[0].legs[0].endLocation.lat
                    let lngStart = gmapsResult.routes[0].legs[0].startLocation.lng
                    let lngEnd = gmapsResult.routes[0].legs[0].endLocation.lng
                    
                    print("distance \(distance), duration \(time)")
                    
                    self.lb_distance.text = distance
                    self.lb_duration.text = time
                    
                    print("LATSTART \(latStart)  LNGSTART \(lngStart)")
                    self.loadViewMap(latStart: latStart, lngStart: lngStart, latEnd: latEnd, lngEnd : lngEnd, zoom: 13.0)
                } else {
                    print("EMPTY RESULT")
                    
                }
                
                
                
//                self.foodData = foodResult.hits
//                self.tableView.reloadData()
                //                    self.tableView.separatorStyle = .none
                
                //                self.dismiss(animated: true, completion: nil)
            }catch let error {
                print("error message \(error)")
                //                self.dismiss(animated: true, completion: nil)
            }
        }
    }

    
    @IBAction func bt_go(_ sender: Any) {
        
        let getFrom : String = tf_from.text!
        let getDestination : String = tf_to.text!
        
        if getFrom != nil || getDestination != nil {
            callNetwork(origin: getFrom, destination: getDestination, mode: travelMode!)
        }
        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueModalTravel" {
            let popup = segue.destination as! PopUpModalViewController
            
            popup.onSave = { (data:String) in
                self.bt_travel.setTitle(data, for: .normal)
                self.travelMode = data
            }
        }
    }
    
    
    func loopForRoutes(mapView : GMSMapView) {
        
        for i in 0...(dataGmaps.count-1)
        {
            let points = dataGmaps[i].polyline.points
            //GMS PATH convert gmaps route points to a polyline
            let path = GMSPath.init(fromEncodedPath: points)
            
            let polyline = GMSPolyline(path: path)
            polyline.strokeColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
            polyline.strokeWidth = 3.0
            polyline.map = mapView
            
        }
        
    }
    

}

