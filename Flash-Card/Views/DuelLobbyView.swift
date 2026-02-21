import SwiftUI

struct DuelLobbyView: View {
    @StateObject var viewModel = DuelViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background
            Theme.cyberDark.liquidGlassBackground()
            
            VStack(spacing: 40) {
                // Header
                VStack(spacing: 8) {
                    Text("ARENA")
                        .cyberpunkFont(size: 40)
                        .foregroundColor(Theme.neonPink)
                        .shadow(color: Theme.neonPink, radius: 10)
                    
                    Text("1v1 PERFORMANCE DUEL")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(4)
                }
                .padding(.top, 60)
                
                Spacer()
                
                if viewModel.duelState == .idle {
                    // Ready to Join
                    Image(systemName: "bolt.shield.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Theme.cyberYellow)
                        .shadow(color: Theme.cyberYellow, radius: 20)
                    
                    Text("CHALLENGE THE SYSTEM")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Button(action: {
                        viewModel.startMatchmaking()
                    }) {
                        Text("FIND OPPONENT")
                            .cyberpunkFont(size: 20)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 15)
                            .background(Theme.neonGradient)
                            .cornerRadius(15)
                            .shadow(color: Theme.electricBlue, radius: 10)
                    }
                } else if viewModel.duelState == .searching {
                    // Searching Animation
                    VStack(spacing: 20) {
                        RadarView()
                            .frame(width: 200, height: 200)
                        
                        Text("SCANNING ARCHIVES...")
                            .cyberpunkFont(size: 18)
                            .foregroundColor(Theme.cyanAccent)
                        
                        Button("CANCEL") {
                            viewModel.disconnect()
                        }
                        .foregroundColor(.white.opacity(0.5))
                    }
                } else if viewModel.duelState == .matched {
                    // Match Found! Transitioning...
                    VStack(spacing: 30) {
                        DuelMatchHeader(opponent: viewModel.opponentName ?? "Shadow Player")
                        
                        ProgressView()
                            .tint(Theme.neonPink)
                        
                        Text("INITIALIZING SYNC...")
                            .font(.caption.bold())
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .fullScreenCover(isPresented: .constant(true)) {
                        DuelSessionView(viewModel: viewModel)
                    }
                }
                
                Spacer()
                
                // Arena Rules
                VStack(alignment: .leading, spacing: 12) {
                    Label("First to 10 cards wins", systemImage: "timer")
                    Label("XP multipliers for speed", systemImage: "bolt.fill")
                    Label("Real-time progress sync", systemImage: "network")
                }
                .font(.footnote)
                .foregroundColor(.white.opacity(0.4))
                .padding()
                .background(.white.opacity(0.05))
                .cornerRadius(12)
                .padding(.bottom, 40)
            }
        }
    }
}

struct RadarView: View {
    @State private var rotate = 0.0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.cyanAccent.opacity(0.2), lineWidth: 1)
            Circle()
                .stroke(Theme.cyanAccent.opacity(0.1), lineWidth: 1)
                .padding(40)
            Circle()
                .stroke(Theme.cyanAccent.opacity(0.05), lineWidth: 1)
                .padding(80)
            
            // Scanner line
            Rectangle()
                .fill(LinearGradient(colors: [Theme.cyanAccent, .clear], startPoint: .top, endPoint: .bottom))
                .frame(width: 2, height: 100)
                .offset(y: -50)
                .rotationEffect(.degrees(rotate))
            
            Circle()
                .fill(Theme.cyanAccent)
                .frame(width: 8, height: 8)
                .shadow(color: Theme.cyanAccent, radius: 5)
                .offset(x: 40, y: -30)
                .opacity(0.6)
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                rotate = 360
            }
        }
    }
}

struct DuelMatchHeader: View {
    let opponent: String
    
    var body: some View {
        HStack(spacing: 30) {
            VStack {
                Circle().fill(.white.opacity(0.1)).frame(width: 60, height: 60)
                Text("YOU").font(.caption.bold())
            }
            
            Text("VS")
                .cyberpunkFont(size: 24)
                .foregroundColor(Theme.neonPink)
            
            VStack {
                Circle().fill(Theme.neonPink.opacity(0.2)).frame(width: 60, height: 60)
                    .overlay(Circle().stroke(Theme.neonPink, lineWidth: 2))
                Text(opponent).font(.caption.bold())
            }
        }
    }
}
