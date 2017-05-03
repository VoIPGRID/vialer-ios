//
//  HandoffViewController.swift
//  Vialer
//
//  Created by Redmer Loen on 4/7/17.
//  Copyright © 2017 VoIPGRID. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

struct PreferencesKeys {
    static let savedItems = "savedItems"
}

class HandOffViewController : UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    var handoffs: [HandOffs] = []
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        loadAllHandoffs()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addHandOffLocation" {
            let navigationController = segue.destination as! UINavigationController
            let vc = navigationController.viewControllers.first as! HandOffAddPointViewController
            vc.delegate = self
        }
    }
    
    func loadAllHandoffs() {
        handoffs = []
        guard let savedItems = UserDefaults.standard.array(forKey: PreferencesKeys.savedItems) else {
            return
        }
        
        for savedItem in savedItems {
            guard let handoff = NSKeyedUnarchiver.unarchiveObject(with: savedItem as! Data) as? HandOffs else {
                continue
            }
            add(handOff: handoff)
        }
        
    }
    
    func saveAllHandoffs() {
        var items: [Data] = []
        for handoff in handoffs {
            let item = NSKeyedArchiver.archivedData(withRootObject: handoff)
            items.append(item)
        }
        UserDefaults.standard.set(items, forKey: PreferencesKeys.savedItems)
    }
    
    func add(handOff: HandOffs) {
        handoffs.append(handOff)
        mapView.addAnnotation(handOff)
        addRadiusOverlay(forHandOff: handOff)
        updateHandOffsCount()
    }
    
    func remove(handOff: HandOffs) {
        if let indexInArray = handoffs.index(of: handOff) {
            handoffs.remove(at: indexInArray)
        }
        mapView.removeAnnotation(handOff)
        removeRadiusOverlay(forHandOff: handOff)
        updateHandOffsCount()
    }
    
    func updateHandOffsCount() {
        title = "Handoffs (\(handoffs.count))"
        navigationItem.rightBarButtonItem?.isEnabled = (handoffs.count < 20)
    }
    
    func addRadiusOverlay(forHandOff handOff: HandOffs) {
        mapView?.add(MKCircle(center: handOff.coordinate, radius: handOff.radius))
    }
    
    func removeRadiusOverlay(forHandOff handOff: HandOffs) {
        guard let overlays = mapView?.overlays else { return }
        for overlay in overlays {
            guard let circleOverlay = overlay as? MKCircle else { return }
            let coord = circleOverlay.coordinate
            if coord.latitude == handOff.coordinate.latitude && coord.longitude == handOff.coordinate.longitude && circleOverlay.radius == handOff.radius {
                mapView?.remove(circleOverlay)
                break
            }
        }
    }
    
    func region(withHandOff handoff: HandOffs) -> CLCircularRegion {
        let region = CLCircularRegion(center: handoff.coordinate, radius: handoff.radius, identifier: handoff.identifier)
        region.notifyOnEntry = (handoff.eventType == .onEntry)
        region.notifyOnExit = !region.notifyOnEntry
        return region
    }
    
    func startMonitoring(handoff: HandOffs) {
        if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            showAlert(withTitle: "Error", message: "Geofencing is not supported on this device")
        }
        
        if CLLocationManager.authorizationStatus() != .authorizedAlways {
            showAlert(withTitle: "Warning", message: "Your is saved but will only be activated once you grant Vialer permission to access the device location.")
        }
        
        let region = self.region(withHandOff: handoff)
        locationManager.startMonitoring(for: region)
    }
    
    func stopMonitoring(handoff: HandOffs) {
        for region in locationManager.monitoredRegions {
            guard let circularRegion = region as? CLCircularRegion, circularRegion.identifier == handoff.identifier else { continue }
            locationManager.stopMonitoring(for: circularRegion)
        }
    }
    
    @IBAction func zoomToCurrentLocation(_ sender: Any) {
        mapView.zoomToUserLocation()
    }
    
}

extension HandOffViewController: HandOffAddPointViewControllerDelegate {
    func handOffAddPointViewController(controller: HandOffAddPointViewController, didAddCoordinate coordinate: CLLocationCoordinate2D, radius: Double, identifier: String, note: String, eventType: EventType) {
        controller.dismiss(animated: true, completion: nil)
        let clampedRadius = min(radius, locationManager.maximumRegionMonitoringDistance)
        let handOff = HandOffs(coordinate: coordinate, radius: clampedRadius, identifier: identifier, note: note, eventType: eventType)
        add(handOff: handOff)
        startMonitoring(handoff: handOff)
        saveAllHandoffs()
    }
}

extension HandOffViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        mapView.showsUserLocation = (status == .authorizedAlways)
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Monitoring failed for region with identifier: \(region!.identifier)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager failed with the following error: \(error)")
    }
}

extension HandOffViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "myHandOff"
        if annotation is HandOffs {
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
            if annotationView == nil {
                print("annotation is nil!")
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                let removeButton = UIButton(type: .custom)
                removeButton.frame = CGRect(x: 0, y: 0, width: 23, height: 23)
                removeButton.setImage(UIImage(named: "delete-geofence")!, for: .normal)
                annotationView?.leftCalloutAccessoryView = removeButton
            } else {
                print("annotation available")
                annotationView?.annotation = annotation
            }
            return annotationView
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let circleRenderer = MKCircleRenderer(overlay: overlay)
            circleRenderer.lineWidth = 1.0
            circleRenderer.strokeColor = .purple
            circleRenderer.fillColor = UIColor.purple.withAlphaComponent(0.4)
            return circleRenderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let handOff = view.annotation as! HandOffs
        stopMonitoring(handoff: handOff)
        remove(handOff: handOff)
        saveAllHandoffs()
    }
}
