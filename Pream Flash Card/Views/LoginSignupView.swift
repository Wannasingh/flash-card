import SwiftUI
import AuthenticationServices
import CryptoKit

struct LoginSignupView: View {
    @EnvironmentObject var session: SessionStore
    @State private var isLoginMode = true
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var appleNonce: String?
    @State private var localErrorMessage: String?

    var body: some View {
        VStack {
            Spacer()

            Text(isLoginMode ? "เข้าสู่ระบบ" : "ลงทะเบียน")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 40)

            VStack(spacing: 20) {
                if !isLoginMode {
                    TextField("ชื่อผู้ใช้", text: $username)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .autocapitalization(.none)
                }

                TextField(isLoginMode ? "อีเมลหรือชื่อผู้ใช้" : "อีเมล", text: $email)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)

                SecureField("รหัสผ่าน", text: $password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                if !isLoginMode {
                    SecureField("ยืนยันรหัสผ่าน", text: $confirmPassword)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }

                if let error = localErrorMessage ?? session.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                }

                Button(action: {
                    Task { await primaryAction() }
                }) {
                    if session.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(isLoginMode ? "เข้าสู่ระบบ" : "ลงทะเบียน")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Capsule().fill(Color.accentColor))
                .padding(.horizontal)
                .disabled(session.isLoading)

                HStack {
                    Rectangle().frame(height: 1).foregroundColor(Color(.systemGray4))
                    Text("หรือ")
                        .foregroundColor(Color(.systemGray))
                        .font(.footnote)
                    Rectangle().frame(height: 1).foregroundColor(Color(.systemGray4))
                }
                .padding(.horizontal)

                SignInWithAppleButton(.signIn) { request in
                    let nonce = randomNonceString()
                    appleNonce = nonce
                    request.requestedScopes = [.email, .fullName]
                    request.nonce = sha256Hex(nonce)
                } onCompletion: { result in
                    Task { await handleAppleCompletion(result) }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 44)
                .padding(.horizontal)
                .disabled(session.isLoading)

                Button(action: {
                    Task { await signInWithGoogle() }
                }) {
                    Text("เข้าสู่ระบบด้วย Google")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Capsule().fill(Color.black))
                        .padding(.horizontal)
                }
                .disabled(session.isLoading)
            }
            .padding(.horizontal)

            Button(action: {
                isLoginMode.toggle()
                localErrorMessage = nil
                session.errorMessage = nil
            }) {
                Text(isLoginMode ? "ยังไม่มีบัญชี? ลงทะเบียน" : "มีบัญชีอยู่แล้ว? เข้าสู่ระบบ")
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                    .padding(.top, 20)
            }

            Spacer()
        }
        .padding()
    }

    private func primaryAction() async {
        localErrorMessage = nil
        session.errorMessage = nil

        if isLoginMode {
            await session.login(usernameOrEmail: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
        } else {
            guard password == confirmPassword else {
                localErrorMessage = "รหัสผ่านไม่ตรงกัน"
                return
            }
            let u = username.trimmingCharacters(in: .whitespacesAndNewlines)
            let e = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            await session.signup(username: u, email: e, password: password)
        }
    }

    private func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) async {
        localErrorMessage = nil
        session.errorMessage = nil
        
        do {
            guard case .success(let authorization) = result else {
                if case .failure(let error) = result {
                    throw error
                }
                throw NSError(domain: "AppleSignIn", code: -1)
            }
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                throw NSError(domain: "AppleSignIn", code: -2)
            }
            guard let tokenData = credential.identityToken,
                  let token = String(data: tokenData, encoding: .utf8) else {
                throw NSError(domain: "AppleSignIn", code: -3)
            }
            let nonce = appleNonce
            let name = credential.fullName.map { PersonNameComponentsFormatter().string(from: $0) }
            
            await session.loginWithApple(identityToken: token, rawNonce: nonce, displayName: name)
        } catch {
            localErrorMessage = (error as NSError).localizedDescription
        }
    }

    private func signInWithGoogle() async {
        localErrorMessage = nil
        session.errorMessage = nil
        
        do {
            let flow = GoogleOAuthFlow()
            let result = try await flow.start()
            await session.loginWithGoogle(code: result.code, codeVerifier: result.codeVerifier, redirectUri: result.redirectUri)
        } catch {
            localErrorMessage = (error as NSError).localizedDescription
        }
    }

    private func sha256Hex(_ input: String) -> String {
        let data = Data(input.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)

        let charset: Array<Character> =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            if status != errSecSuccess {
                fatalError("Unable to generate nonce")
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }
}

struct LoginSignupView_Previews: PreviewProvider {
    static var previews: some View {
        LoginSignupView().environmentObject(SessionStore.shared)
    }
}
