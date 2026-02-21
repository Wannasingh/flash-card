import SwiftUI

struct WelcomeView: View {
    @Binding var showWelcomeScreen: Bool
    @Binding var showLoginSignupScreen: Bool
    @State private var selection = 0

    var body: some View {
        VStack {
            TabView(selection: $selection) {
                WelcomeSlideView(
                    title: "ยินดีต้อนรับสู่ Flash Card App",
                    description: "เรียนรู้และจดจำได้อย่างมีประสิทธิภาพ",
                    imageName: "rectangle.on.rectangle.angled.fill"
                )
                .tag(0)

                WelcomeSlideView(
                    title: "สร้างชุดการ์ดของคุณเอง",
                    description: "ปรับแต่งการเรียนรู้ให้เข้ากับคุณ",
                    imageName: "square.stack.3d.up.fill"
                )
                .tag(1)

                WelcomeSlideView(
                    title: "ทบทวนอย่างชาญฉลาดด้วย Liquid Glass",
                    description: "ประสบการณ์การเรียนรู้ที่สวยงามและลื่นไหล",
                    imageName: "sparkles.square.filled.on.square"
                )
                .tag(2)
            }
            #if os(iOS)
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            #endif

            Button(action: {
                showWelcomeScreen = false
                showLoginSignupScreen = true
            }) {
                Text("เริ่มต้นใช้งาน")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Capsule().fill(Color.accentColor))
                    .padding(.horizontal)
            }
            .padding(.bottom)
        }
    }
}

struct WelcomeSlideView: View {
    let title: String
    let description: String
    let imageName: String

    var body: some View {
        VStack {
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .foregroundColor(.accentColor)
                .padding(.bottom, 20)

            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 10)

            Text(description)
                .font(.title3)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(showWelcomeScreen: .constant(true), showLoginSignupScreen: .constant(false))
    }
}
