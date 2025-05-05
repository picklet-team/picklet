//
//  LocationManager.swift
//  Picklet
//
//  Created by al dente on 2025/04/25.
//

import CoreLocation
import SwiftUI

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
  private let locationManager = CLLocationManager()

  @Published var currentLocation: CLLocation?
  @Published var placemark: CLPlacemark?
  @Published var locationError: Error?

  override init() {
    super.init()
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    locationManager.requestWhenInUseAuthorization()
    locationManager.startUpdatingLocation()
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.first else { return }
    currentLocation = location

    let geocoder = CLGeocoder()
    geocoder.reverseGeocodeLocation(location) { placemarks, error in
      if let error = error {
        self.locationError = error
        return
      }
      self.placemark = placemarks?.first
    }
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    locationError = error
  }
}
