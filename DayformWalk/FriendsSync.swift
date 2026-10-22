import Foundation
import Combine
import CryptoKit
import MultipeerConnectivity

struct TeamEnvelope: Codable {
    var version = 1
    var code: String
    var contributions: [String: Int]
}

@MainActor
final class FriendsSync: NSObject, ObservableObject {
    @Published private(set) var status = "Nicht verbunden"
    @Published private(set) var connected = 0
    @Published private(set) var running = false
    var onReceive: ((TeamEnvelope) -> Void)?
    private let service = "dayform-team"
    private var peer: MCPeerID?
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var envelope: TeamEnvelope?
    private var pending: Set<String> = []
    private func roomTag(_ code: String) -> String { SHA256.hash(data: Data(code.utf8)).map { String(format: "%02x", $0) }.joined().prefix(16).description }

    func start(code: String, contributions: [String: Int]) {
        stop()
        let id = MCPeerID(displayName: String(UUID().uuidString.prefix(12)))
        peer = id
        let session = MCSession(peer: id, securityIdentity: nil, encryptionPreference: .required)
        self.session = session; session.delegate = self
        envelope = TeamEnvelope(code: code, contributions: contributions)
        advertiser = MCNearbyServiceAdvertiser(peer: id, discoveryInfo: ["room": roomTag(code)], serviceType: service)
        advertiser?.delegate = self
        browser = MCNearbyServiceBrowser(peer: id, serviceType: service)
        browser?.delegate = self
        advertiser?.startAdvertisingPeer(); browser?.startBrowsingForPeers()
        running = true; status = "Suche nach Freunden in der Nähe …"
    }
    func update(_ project: TeamProject?) {
        guard let project, envelope?.code == project.code else { return }
        envelope?.contributions = project.contributions
        send()
    }
    func stop() {
        advertiser?.stopAdvertisingPeer(); browser?.stopBrowsingForPeers(); session?.disconnect()
        advertiser = nil; browser = nil; session = nil; peer = nil; envelope = nil; pending = []
        running = false; connected = 0; status = "Nicht verbunden"
    }
    private func send() {
        guard let session, !session.connectedPeers.isEmpty, let envelope, let data = try? JSONEncoder().encode(envelope), data.count < 16_384 else { return }
        do { try session.send(data, toPeers: session.connectedPeers, with: .reliable) }
        catch { status = "Übertragung unterbrochen. Erneut verbinden." }
    }
    fileprivate func found(_ remote: MCPeerID, info: [String: String]?) {
        guard let session, let peer, let envelope, info?["room"] == roomTag(envelope.code), !pending.contains(remote.displayName), remote.displayName > peer.displayName else { return }
        pending.insert(remote.displayName)
        browser?.invitePeer(remote, to: session, withContext: Data(envelope.code.utf8), timeout: 15)
    }
}

extension FriendsSync: MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate, MCSessionDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        Task { @MainActor in
            let valid = context.flatMap { String(data: $0, encoding: .utf8) } == self.envelope?.code && self.running
            invitationHandler(valid && self.connected < 7, valid ? self.session : nil)
        }
    }
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        Task { @MainActor in self.status = "Lokales Netzwerk prüfen: \(error.localizedDescription)" }
    }
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        Task { @MainActor in self.found(peerID, info: info) }
    }
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task { @MainActor in self.pending.remove(peerID.displayName) }
    }
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        Task { @MainActor in self.status = "Suche nicht verfügbar: \(error.localizedDescription)" }
    }
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            guard self.session === session else { return }
            self.connected = session.connectedPeers.count
            self.status = self.connected > 0 ? "\(self.connected) Freunde verbunden · verschlüsselt" : "Suche nach Freunden in der Nähe …"
            if state == .connected { self.send() }
            if state == .notConnected { self.pending.remove(peerID.displayName) }
        }
    }
    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard data.count < 16_384, let message = try? JSONDecoder().decode(TeamEnvelope.self, from: data), message.version == 1 else { return }
        Task { @MainActor in
            guard self.session === session, message.code == self.envelope?.code else { return }
            self.onReceive?(message)
        }
    }
    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
