import SwiftUI

struct StudySessionSummaryView: View {
    @State private var animateCoins = false
    @State private var animateStreak = false
    
    // In the future this should come from a backend StudyStatsResponse
    let earnedCoins: Int = 15
    let currentStreak: Int = 3
    
    var body: some View {
        VStack(spacing: 32) {
            Text("SESSION CLEARED")
                .cyberpunkFont(size: 36)
                .foregroundColor(Theme.neonPink)
                .shadow(color: Theme.neonPink.opacity(0.8), radius: 10, x: 0, y: 0)
                .padding(.top, 40)
            
            Text("Brain capacity upgraded. 🧠✨")
                .foregroundColor(Theme.textSecondary)
                .font(.headline)
            
            // Gamification HUD
            VStack(spacing: 16) {
                // Streak Element
                HStack {
                    ZStack {
                        Circle()
                            .fill(Theme.cyberCard)
                            .frame(width: 60, height: 60)
                        Image(systemName: "flame.fill")
                            .font(.system(size: 30))
                            .foregroundColor(Theme.cyberYellow)
                            .scaleEffect(animateStreak ? 1.2 : 1.0)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Day Streak Maintained!")
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                        Text("\(currentStreak) Days 🔥")
                            .cyberpunkFont(size: 24)
                            .foregroundColor(Theme.textPrimary)
                    }
                    Spacer()
                }
                .padding()
                .background(Theme.cyberCard)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.cyberYellow.opacity(0.3), lineWidth: 1))
                .offset(y: animateStreak ? 0 : 50)
                .opacity(animateStreak ? 1 : 0)
                
                // Coins Element
                HStack {
                    ZStack {
                        Circle()
                            .fill(Theme.cyberCard)
                            .frame(width: 60, height: 60)
                        Image(systemName: "bitcoinsign.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(Theme.electricBlue)
                            .rotation3DEffect(.degrees(animateCoins ? 360 : 0), axis: (x: 0, y: 1, z: 0))
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Coins Rewarded")
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                        Text("+\(earnedCoins) 🪙")
                            .cyberpunkFont(size: 24)
                            .foregroundColor(Theme.cyanAccent)
                    }
                    Spacer()
                }
                .padding()
                .background(Theme.cyberCard)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.electricBlue.opacity(0.3), lineWidth: 1))
                .offset(y: animateCoins ? 0 : 50)
                .opacity(animateCoins ? 1 : 0)
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            Button(action: {
                // Typically would pop navigation back to home,
                // But since Study is a Tab, we might just fire a notification or state reset
                print("Return to home clicked")
            }) {
                Text("RETURN TO BASE")
                    .cyberpunkFont(size: 20)
                    .foregroundColor(Theme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.neonGradient)
                    .cornerRadius(16)
                    .shadow(color: Theme.electricBlue.opacity(0.5), radius: 10, x: 0, y: 5)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.cyberDark.ignoresSafeArea())
        .onAppear {
            // Sequence the animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2)) {
                animateStreak = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.6)) {
                animateCoins = true
            }
            
            // Trigger Haptic Success
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
}

struct StudySessionSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        StudySessionSummaryView()
            .preferredColorScheme(.dark)
    }
}
