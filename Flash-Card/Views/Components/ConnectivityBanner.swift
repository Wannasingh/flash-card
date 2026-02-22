import SwiftUI

/**
 ConnectivityBanner: A sleek, floating banner that notifies the user
 of their network status without blocking the UI.
 */
struct ConnectivityBanner: View {
    @ObservedObject var monitor = NetworkMonitor.shared
    @State private var showBanner = false
    
    var body: some View {
        VStack {
            if !monitor.isConnected {
                HStack(spacing: 12) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 14, weight: .bold))
                    
                    Text("OFFLINE MODE — Showing cached content")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                    
                    Spacer()
                    
                    Circle()
                        .fill(Theme.warning)
                        .frame(width: 8, height: 8)
                        .shadow(color: Theme.warning, radius: 4)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .background(Theme.warning.opacity(0.1))
                .cornerRadius(100)
                .overlay(RoundedRectangle(cornerRadius: 100).stroke(Theme.warning.opacity(0.3), lineWidth: 1))
                .padding(.horizontal, 24)
                .padding(.top, 10)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: monitor.isConnected)
    }
}

struct ConnectivityBanner_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ConnectivityBanner()
        }
    }
}
