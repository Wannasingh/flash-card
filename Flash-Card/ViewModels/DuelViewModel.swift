import SwiftUI
import Combine

class DuelViewModel: ObservableObject {
    @Published var duelState: DuelState = .idle
    @Published var opponentName: String?
    @Published var myProgress: Double = 0.0
    @Published var opponentProgress: Double = 0.0
    @Published var winnerName: String?
    @Published var reactions: [String] = []
    
    private var webSocketTask: URLSessionWebSocketTask?
    private let tokenStore = KeychainStore.shared
    private let username: String
    
    enum DuelState {
        case idle, searching, matched, finished
    }
    
    init() {
        // In a real app, get this from SessionStore
        self.username = "LocalPlayer" 
    }
    
    func startMatchmaking() {
        guard let token = try? tokenStore.getString(forKey: "accessToken") else { return }
        duelState = .searching
        connect(token: token)
    }
    
    private func connect(token: String) {
        let wsURLString = AppConfig.backendBaseURL.absoluteString.replacingOccurrences(of: "http", with: "ws")
        let url = URL(string: "\(wsURLString)/ws-duel")!
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        
        sendStompConnect(token: token)
        receiveMessage()
    }
    
    private func sendStompConnect(token: String) {
        let connectFrame = "CONNECT\naccept-version:1.1,1.2\nheart-beat:10000,10000\nAuthorization:Bearer \(token)\n\n\u{0000}"
        sendMessage(connectFrame)
        
        // Subscribe to user-specific topics
        let subscribeFrame = "SUBSCRIBE\nid:sub-0\ndestination:/user/topic/duel\n\n\u{0000}"
        sendMessage(subscribeFrame)
        
        // Join queue
        let joinFrame = "SEND\ndestination:/app/duel.join\n\n\u{0000}"
        sendMessage(joinFrame)
    }
    
    func updateProgress(progress: Double) {
        self.myProgress = progress
        let msg = "SEND\ndestination:/app/duel.progress\ncontent-type:application/json\n\n{\"progress\":\(progress)}\u{0000}"
        sendMessage(msg)
    }
    
    func sendReaction(_ emoji: String) {
        let msg = "SEND\ndestination:/app/duel.reaction\ncontent-type:application/json\n\n{\"content\":\"\(emoji)\"}\u{0000}"
        sendMessage(msg)
    }
    
    private func sendMessage(_ text: String) {
        let message = URLSessionWebSocketTask.Message.string(text)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("WebSocket sending error: \(error)")
            }
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("WebSocket receiving error: \(error)")
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleStompFrame(text)
                default:
                    break
                }
                self?.receiveMessage()
            }
        }
    }
    
    private func handleStompFrame(_ frame: String) {
        if frame.contains("MESSAGE") {
            // Extract JSON body
            if let bodyRange = frame.range(of: "\n\n") {
                let body = String(frame[bodyRange.upperBound...]).trimmingCharacters(in: .init(charactersIn: "\u{0000}"))
                if let data = body.data(using: .utf8) {
                    DispatchQueue.main.async {
                        self.processDuelMessage(data)
                    }
                }
            }
        }
    }
    
    private func processDuelMessage(_ data: Data) {
        do {
            let msg = try JSONDecoder().decode(DuelMessagePayload.self, from: data)
            switch msg.type {
            case "MATCHED":
                self.opponentName = msg.opponent
                self.duelState = .matched
                self.myProgress = 0
                self.opponentProgress = 0
            case "PROGRESS":
                self.opponentProgress = msg.progress ?? 0
            case "FINISH":
                self.winnerName = msg.content
                self.duelState = .finished
            case "CHAT":
                if let reaction = msg.content {
                    self.reactions.append(reaction)
                    if self.reactions.count > 5 { self.reactions.removeFirst() }
                }
            default:
                break
            }
        } catch {
            print("Failed to decode duel message: \(error)")
        }
    }
    
    func disconnect() {
        let msg = "SEND\ndestination:/app/duel.quit\n\n\u{0000}"
        sendMessage(msg)
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        duelState = .idle
    }
}

struct DuelMessagePayload: Codable {
    let type: String
    let duelId: Int64?
    let sender: String?
    let opponent: String?
    let progress: Double?
    let content: String?
}
