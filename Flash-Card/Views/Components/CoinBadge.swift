import SwiftUI

struct CoinBadge: View {
    let count: Int
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "bitcoinsign.circle.fill")
                .foregroundColor(Theme.cyberYellow)
            Text("\(count)")
                .font(.system(.subheadline, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Theme.cyberYellow.opacity(0.3), lineWidth: 1)
        )
    }
}
