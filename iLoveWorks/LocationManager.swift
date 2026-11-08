import Foundation
import CoreLocation
import Combine

public class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    public static let shared = LocationManager()
    private let manager = CLLocationManager()
    
    @Published public var location: CLLocation?
    
    public override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    public func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    public func startUpdating() {
        manager.startUpdatingLocation()
    }
    
    public func stopUpdating() {
        manager.stopUpdatingLocation()
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.location = location
            // Could add logic to send via APIClient here or in ViewModel
        }
    }
}
