import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    @State private var currentTab = 0
    
    var body: some View {
        ZStack {
            Theme.cyberDark.ignoresSafeArea()
            
            TabView(selection: $currentTab) {
                // Slide 1
                OnboardingPage(
                    icon: "sparkles",
                    title: "WELCOME TO THE FUTURE",
                    description: "Meet Gen-Z Flashcards. The most gamified, cyberpunk way to hack your brain and ace your exams."
                )
                .tag(0)
                
                // Slide 2
                OnboardingPage(
                    icon: "hand.point.up.left.fill",
                    title: "TINDER FOR STUDYING",
                    description: "Swipe RIGHT if you mastered the card. Swipe LEFT if you forgot. Our Spaced Repetition System handles the rest."
                )
                .tag(1)
                
                // Slide 3
                OnboardingPage(
                    icon: "bitcoinsign.circle.fill",
                    title: "EARN & ACQUIRE",
                    description: "Earn Coins by studying every day. Use them to acquire premium Creator Decks from the Marketplace!"
                )
                .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .animation(.easeInOut, value: currentTab)
            
            VStack {
                Spacer()
                
                if currentTab == 2 {
                    Button(action: {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        withAnimation {
                            hasSeenOnboarding = true
                        }
                    }) {
                        Text("ENTER SYSTEM")
                            .cyberpunkFont(size: 20)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Theme.neonGradient)
                            .cornerRadius(16)
                            .shadow(color: Theme.neonPink.opacity(0.5), radius: 10, y: 5)
                            .padding(.horizontal, 40)
                            .padding(.bottom, 60)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    Button(action: {
                        withAnimation {
                            currentTab += 1
                        }
                    }) {
                        Text("NEXT")
                            .cyberpunkFont(size: 20)
                            .foregroundColor(Theme.textPrimary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Theme.cyberCard)
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.neonPink.opacity(0.5), lineWidth: 1))
                            .padding(.horizontal, 40)
                            .padding(.bottom, 60)
                    }
                }
            }
        }
    }
}

struct OnboardingPage: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundColor(Theme.cyanAccent)
                .shadow(color: Theme.cyanAccent.opacity(0.5), radius: 20, y: 10)
            
            Text(title)
                .cyberpunkFont(size: 32)
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.body)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .lineSpacing(6)
        }
        .padding(.bottom, 80) // Make room for the button
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
