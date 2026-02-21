import SwiftUI

struct BadgeView: View {
    let badge: BadgeModel
    var size: CGFloat = 60
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(getCategoryColor().opacity(0.1))
                    .frame(width: size, height: size)
                    .overlay(Circle().stroke(getCategoryColor(), lineWidth: 2))
                    .shadow(color: getCategoryColor(), radius: 5)
                
                Image(systemName: getBadgeIcon())
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundColor(getCategoryColor())
            }
            
            Text(badge.name)
                .font(.caption2.bold())
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .frame(width: size + 20)
        .help(badge.description)
    }
    
    private func getCategoryColor() -> Color {
        switch badge.category {
        case "STUDY": return Theme.cyanAccent
        case "STREAK": return Theme.cyberYellow
        case "DUEL": return Theme.neonPink
        case "SOCIAL": return Theme.electricBlue
        default: return .white
        }
    }
    
    private func getBadgeIcon() -> String {
        switch badge.code {
        case "FIRST_SWIPE": return "hand.tap.fill"
        case "STREAK_7": return "flame.fill"
        case "DUEL_WINNER": return "bolt.shield.fill"
        case "XP_1000": return "brain.head.profile"
        default: return "star.fill"
        }
    }
}
