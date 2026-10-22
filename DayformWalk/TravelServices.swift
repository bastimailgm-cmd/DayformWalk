import Foundation
import MapKit
import CoreLocation
import Combine

extension TravelCoordinate {
    var cl: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }
    init(_ coordinate: CLLocationCoordinate2D) { latitude = coordinate.latitude; longitude = coordinate.longitude }
}

@MainActor
enum TravelMapService {
    static func leg(from: TravelCoordinate, to: TravelCoordinate) async throws -> TravelLeg {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: from.cl))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to.cl))
        request.transportType = .walking
        let directions = MKDirections(request: request)
        let response = try await withTaskCancellationHandler(operation: { try await directions.calculate() }, onCancel: { directions.cancel() })
        try Task.checkCancellation()
        guard let route = response.routes.first else { throw TravelError.noRoute }
        let points = (0..<route.polyline.pointCount).map { TravelCoordinate(route.polyline.points()[$0].coordinate) }
        let result = TravelLeg(points: points, meters: route.distance, seconds: max(route.expectedTravelTime, route.distance / 1.2))
        guard result.valid, result.meters >= 10, let first = points.first, let last = points.last, first.distance(to: from) <= 100, last.distance(to: to) <= 80 else { throw TravelError.noRoute }
        return result
    }
    static func discover(at origin: TravelCoordinate, blocked: Set<String>, status: (String) -> Void) async throws -> [TravelPlace] {
        status("Öffentliche Ausflugsorte suchen …")
        let request = MKLocalPointsOfInterestRequest(center: origin.cl, radius: 1800)
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: [.park, .nationalPark, .beach, .library, .museum])
        let search = MKLocalSearch(request: request)
        let response = try? await withTaskCancellationHandler(operation: { try await search.start() }, onCancel: { search.cancel() })
        var results: [TravelPlace] = []
        let sorted = (response?.mapItems ?? []).sorted { origin.distance(to: TravelCoordinate($0.placemark.coordinate)) < origin.distance(to: TravelCoordinate($1.placemark.coordinate)) }
        for item in sorted.prefix(14) {
            try Task.checkCancellation()
            let coord = TravelCoordinate(item.placemark.coordinate)
            let id = String(format: "apple/%.5f/%.5f", locale: Locale(identifier: "en_US_POSIX"), coord.latitude, coord.longitude)
            guard coord.valid, !blocked.contains(id), origin.distance(to: coord) <= 1900, !results.contains(where: { $0.coordinate.distance(to: coord) < 45 }) else { continue }
            status("Fußrouten prüfen · \(results.count) Ziele gefunden")
            guard let route = try? await leg(from: origin, to: coord), route.seconds <= 1200 else { continue }
            let material: TravelMaterial = item.pointOfInterestCategory == .beach ? .shell : item.pointOfInterestCategory == .museum || item.pointOfInterestCategory == .library ? .stone : item.pointOfInterestCategory == .nationalPark || Int(abs(coord.latitude * 100000).rounded()) % 2 == 0 ? .wood : .seed
            results.append(TravelPlace(id: id, name: String((item.name ?? "Ausflugsort").prefix(120)), coordinate: coord, material: material, source: "Apple Maps", explicitPublicAccess: false, verifiedAt: Date(), walkingMeters: route.meters, walkingSeconds: route.seconds))
            if results.count == 8 { break }
        }
        if results.count < 4 {
            status("Zusätzliche Dorfziele in OpenStreetMap suchen …")
            let osm = (try? await villagePlaces(at: origin)) ?? []
            for var place in osm {
                try Task.checkCancellation()
                guard results.count < 8, !blocked.contains(place.id), !results.contains(where: { $0.coordinate.distance(to: place.coordinate) < 60 }) else { continue }
                status("Dorf-Fußrouten prüfen · \(results.count) Ziele gefunden")
                guard let route = try? await leg(from: origin, to: place.coordinate), route.seconds <= 1200 else { continue }
                place.walkingMeters = route.meters; place.walkingSeconds = route.seconds; place.verifiedAt = Date()
                results.append(place)
            }
        }
        guard !results.isEmpty else { throw TravelError.noPlaces }
        return results
    }
    private struct OSMResponse: Decodable {
        struct Element: Decodable { var type: String; var id: Int64; var lat: Double?; var lon: Double?; var tags: [String: String]? }
        var elements: [Element]
    }
    private static func villagePlaces(at origin: TravelCoordinate) async throws -> [TravelPlace] {
        let latitude = String(format: "%.5f", locale: Locale(identifier: "en_US_POSIX"), origin.latitude)
        let longitude = String(format: "%.5f", locale: Locale(identifier: "en_US_POSIX"), origin.longitude)
        let query = "[out:json][timeout:15];(node(around:1800,\(latitude),\(longitude))[amenity~\"^(bench|shelter|drinking_water)$\"][access!~\"^(private|no|customers|permit|destination|delivery)$\"];node(around:1800,\(latitude),\(longitude))[tourism~\"^(viewpoint|picnic_site|information)$\"][access!~\"^(private|no|customers|permit|destination|delivery)$\"];);out body 40;"
        var request = URLRequest(url: URL(string: "https://overpass-api.de/api/interpreter")!); request.httpMethod = "POST"; request.timeoutInterval = 22
        request.setValue("DayformWalk/4.0", forHTTPHeaderField: "User-Agent")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var body = URLComponents(); body.queryItems = [URLQueryItem(name: "data", value: query)]; request.httpBody = body.percentEncodedQuery?.data(using: .utf8)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200, data.count <= 2_000_000 else { throw TravelError.network }
        let decoded = try JSONDecoder().decode(OSMResponse.self, from: data)
        return decoded.elements.compactMap { element -> TravelPlace? in
            guard let lat = element.lat, let lon = element.lon, let tags = element.tags else { return nil }
            let coordinate = TravelCoordinate(latitude: lat, longitude: lon)
            guard coordinate.valid, origin.distance(to: coordinate) <= 1850 else { return nil }
            let amenity = tags["amenity"], tourism = tags["tourism"]
            let name = tags["name"] ?? (amenity == "bench" ? "Sitzbank" : amenity == "shelter" ? "Unterstand" : amenity == "drinking_water" ? "Trinkwasserstelle" : tourism == "viewpoint" ? "Aussichtspunkt" : tourism == "picnic_site" ? "Picknickplatz" : "Infopunkt")
            let material: TravelMaterial = amenity == "bench" || amenity == "shelter" ? .wood : amenity == "drinking_water" ? .shell : tourism == "viewpoint" ? .stone : .seed
            return TravelPlace(id: "osm/\(element.type)/\(element.id)", name: String(name.prefix(120)), coordinate: coordinate, material: material, source: "OpenStreetMap", explicitPublicAccess: tags["access"] == "yes" || tags["access"] == "public", verifiedAt: Date(), walkingMeters: 0, walkingSeconds: 0)
        }.sorted { origin.distance(to: $0.coordinate) < origin.distance(to: $1.coordinate) }.prefix(10).map { $0 }
    }
    static func plan(from origin: TravelCoordinate, places: [TravelPlace], minutes: Int, title: String, story: String, ai: Bool) async throws -> TravelPlan {
        var stops = Array(places.prefix(3))
        while !stops.isEmpty {
            var legs: [TravelLeg] = [], current = origin
            for stop in stops { legs.append(try await leg(from: current, to: stop.coordinate)); current = stop.coordinate }
            legs.append(try await leg(from: current, to: origin))
            let result = TravelPlan(title: title, story: story, origin: origin, stops: stops, legs: legs, createdAt: Date(), minutes: minutes, ai: ai)
            if result.valid { return result }
            stops.removeLast()
        }
        throw TravelError.budget
    }
    static func navigate(_ place: TravelPlace) {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: place.coordinate.cl)); item.name = place.name
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
    }
}

@MainActor
final class TravelExplorer: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var fix: CLLocation?
    @Published var status = "Erlaube den Standort, um deine Umgebung zu entdecken."
    @Published var busy = false
    @Published var error: String?
    @Published var selected: TravelPlace?
    @Published var surpriseLeg: TravelLeg?
    private let manager = CLLocationManager()
    private var visible = false
    private var task: Task<Void, Never>?
    override init() { super.init(); manager.delegate = self; manager.desiredAccuracy = kCLLocationAccuracyBest; manager.distanceFilter = 10; manager.activityType = .fitness }
    var coordinate: TravelCoordinate? { fix.map { TravelCoordinate($0.coordinate) } }
    var fresh: Bool { guard let fix else { return false }; return (0...35).contains(fix.horizontalAccuracy) && abs(fix.timestamp.timeIntervalSinceNow) <= 20 && fix.speed <= 4.5 }
    func appear() {
        visible = true
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--preview") {
            fix = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 52.515, longitude: 13.38), altitude: 0, horizontalAccuracy: 8, verticalAccuracy: 8, timestamp: Date()); status = "Vorschau · Beispieldaten in Berlin"; return
        }
        #endif
        if manager.authorizationStatus == .notDetermined { manager.requestWhenInUseAuthorization() } else { updatePermission() }
    }
    func disappear() { visible = false; manager.stopUpdatingLocation(); task?.cancel(); task = nil; busy = false }
    private func updatePermission() {
        guard visible else { return }
        if [.authorizedWhenInUse, .authorizedAlways].contains(manager.authorizationStatus) { manager.startUpdatingLocation(); status = "Standort wird ermittelt …" }
        else { status = "Standort in den iPhone-Einstellungen erlauben. Für Belohnungen wird ein genauer Standort benötigt." }
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) { updatePermission() }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, location.horizontalAccuracy >= 0 else { return }
        fix = location; status = "GPS ±\(Int(location.horizontalAccuracy)) m · Fundstellen im Umkreis von 1,8 km"
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { status = "GPS gerade nicht verfügbar. Versuche es unter freiem Himmel erneut." }
    func run(_ action: @escaping @MainActor () async throws -> Void) {
        guard !busy else { return }; busy = true; error = nil
        task = Task { [weak self] in
            do { try await action() } catch is CancellationError {} catch { if !Task.isCancelled { self?.error = error.localizedDescription } }
            self?.busy = false
        }
    }
    func canCollect(_ place: TravelPlace) -> Bool {
        guard let fix else { return false }
        return TravelProgress.arrivalAllowed(place: place, location: TravelCoordinate(fix.coordinate), accuracy: fix.horizontalAccuracy, fixDate: fix.timestamp, now: Date(), speed: fix.speed)
    }
}
