import SwiftUI
import MapKit

struct RouteMap: UIViewRepresentable {
    var segments: [RouteSegment]
    var isLive = false
    var fitToken = UUID()

    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.pointOfInterestFilter = .excludingAll
        map.showsCompass = true
        map.showsScale = true
        map.isRotateEnabled = true
        map.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.16, longitude: 10.45), span: MKCoordinateSpan(latitudeDelta: 8, longitudeDelta: 8)), animated: false)
        return map
    }
    func updateUIView(_ map: MKMapView, context: Context) {
        map.showsUserLocation = isLive
        let signature = segments.map { "\($0.id)-\($0.points.count)" }.joined(separator: ";")
        let shouldFit = context.coordinator.fitToken != fitToken
        let changed = context.coordinator.signature != signature
        if changed {
            context.coordinator.signature = signature
            map.removeOverlays(map.overlays)
            map.removeAnnotations(map.annotations.filter { !($0 is MKUserLocation) })
            for segment in segments where segment.points.count > 1 {
                let coordinates = segment.points.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
                map.addOverlay(MKPolyline(coordinates: coordinates, count: coordinates.count))
            }
            if let point = segments.flatMap(\.points).first {
                let start = MKPointAnnotation()
                start.title = "Start"
                start.coordinate = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
                map.addAnnotation(start)
            }
            if !isLive, let point = segments.flatMap(\.points).last {
                let end = MKPointAnnotation()
                end.title = "Ende"
                end.coordinate = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
                map.addAnnotation(end)
            }
        }
        if shouldFit || (changed && context.coordinator.hasFit == false) {
            context.coordinator.fitToken = fitToken
            let points = segments.flatMap(\.points)
            if !points.isEmpty {
                var bounds = MKMapRect.null
                for point in points {
                    let value = MKMapPoint(CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude))
                    bounds = bounds.union(MKMapRect(x: value.x, y: value.y, width: 1, height: 1))
                }
                let minimum = 400.0 / MKMetersPerMapPointAtLatitude(points[0].latitude)
                if bounds.width < minimum { bounds = bounds.insetBy(dx: -(minimum - bounds.width) / 2, dy: 0) }
                if bounds.height < minimum { bounds = bounds.insetBy(dx: 0, dy: -(minimum - bounds.height) / 2) }
                map.setVisibleMapRect(bounds, edgePadding: UIEdgeInsets(top: 45, left: 35, bottom: 45, right: 35), animated: context.coordinator.hasFit)
                context.coordinator.hasFit = true
            }
        }
    }
    final class Coordinator: NSObject, MKMapViewDelegate {
        var signature = ""
        var fitToken: UUID?
        var hasFit = false
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let line = overlay as? MKPolyline else { return MKOverlayRenderer(overlay: overlay) }
            let renderer = MKPolylineRenderer(polyline: line)
            renderer.strokeColor = UIColor(Color.walkGreen)
            renderer.lineWidth = 5
            renderer.lineCap = .round
            renderer.lineJoin = .round
            return renderer
        }
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }
            let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: nil)
            view.markerTintColor = annotation.title == "Start" ? UIColor(Color.walkGreen) : UIColor(Color.walkOrange)
            view.glyphImage = UIImage(systemName: annotation.title == "Start" ? "figure.walk" : "flag.fill")
            view.canShowCallout = true
            return view
        }
    }
}
