import CoreLocation
import SwiftUI

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()

    @Published var placemark: CLPlacemark?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation? // 互換性のため追加
    @Published var locationError: Error? // エラー情報も追加

    private var lastLocationUpdate: Date?
    private let updateInterval: TimeInterval = 300 // 5分間隔

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.distanceFilter = 1_000 // 1km以上移動した場合のみ更新
        requestLocationPermission()
    }

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        currentLocation = location // 互換性のため

        // 更新間隔チェック
        let now = Date()
        if let lastUpdate = lastLocationUpdate,
           now.timeIntervalSince(lastUpdate) < updateInterval {
            return
        }

        lastLocationUpdate = now

        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.locationError = error
                    return
                }

                if let placemark = placemarks?.first {
                    // 同じ都市の場合は更新しない
                    if self?.placemark?.locality != placemark.locality {
                        self?.placemark = placemark
                        print("📍 位置情報更新: \(placemark.locality ?? "不明")")
                    }
                }
            }
        }

        // 位置情報取得後は停止して電池を節約
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error
        print("❌ 位置情報取得エラー: \(error.localizedDescription)")
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status

        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("❌ 位置情報アクセスが拒否されました")
        case .notDetermined:
            requestLocationPermission()
        @unknown default:
            break
        }
    }

    // 手動で位置情報を更新
    func refreshLocation() {
        locationManager.startUpdatingLocation()
    }
}
