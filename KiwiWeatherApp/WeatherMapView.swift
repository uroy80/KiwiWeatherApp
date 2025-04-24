import SwiftUI
import MapKit

struct WeatherMapView: View {
    let latitude: Double
    let longitude: Double
    @State private var mapType: MKMapType = .standard
    
    @State private var region: MKCoordinateRegion
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
        
        // Initialize the region
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        ))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Weather Location")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Picker("Map Type", selection: $mapType) {
                    Text("Standard").tag(MKMapType.standard)
                    Text("Satellite").tag(MKMapType.satellite)
                    Text("Hybrid").tag(MKMapType.hybrid)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            .padding(.horizontal)
            
            Map(coordinateRegion: $region,
                interactionModes: .all,
                showsUserLocation: true,
                userTrackingMode: nil,
                annotationItems: [WeatherLocation(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))]) { location in
                    MapMarker(coordinate: location.coordinate, tint: .red)
                }
                .mapStyle(mapType == .standard ? .standard : mapType == .satellite ? .imagery : .hybrid)
                .cornerRadius(20)
                .frame(height: 300)
                .padding(.horizontal)
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.15),
                        Color.white.opacity(0.05)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                ))
        )
        .padding(.horizontal)
    }
}

struct WeatherLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}
