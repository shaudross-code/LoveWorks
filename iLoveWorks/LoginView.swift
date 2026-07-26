//
//  LoginView.swift
//  iLoveWorks
//

import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var errorMessage: String?
    @State private var isSubmitting = false
    
    @EnvironmentObject var sessionManager: SessionManager
    
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            // Floating background icons
            GeometryReader { geo in
                ZStack {
                    FloatingIcon(icon: "heart.fill", color: Theme.lovePink, delay: 0, geo: geo)
                    FloatingIcon(icon: "gift.fill", color: Theme.primary, delay: 2, geo: geo)
                    FloatingIcon(icon: "airplane", color: .blue, delay: 4, geo: geo)
                    FloatingIcon(icon: "diamond.fill", color: .cyan, delay: 1, geo: geo)
                    FloatingIcon(icon: "banknote.fill", color: .green, delay: 3, geo: geo)
                    FloatingIcon(icon: "key.fill", color: .orange, delay: 5, geo: geo)
                }
            }
            .allowsHitTesting(false)
            
            VStack(spacing: 32) {
                // LoveWorks Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Theme.loveGradient)
                            .frame(width: 84, height: 84)
                            .shadow(color: Theme.lovePink.opacity(0.5), radius: 25)
                        
                        Image(systemName: "heart.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.white)
                    }
                    
                    VStack(spacing: 4) {
                        Text("Show your Love.")
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: Theme.lovePink.opacity(0.6), radius: 10)
                        
                        Text("Get Loved with Gifts.")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.primary)
                    }
                    
                    Text("Secured with JWT • Admin invitations only")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.textMuted)
                        .tracking(1)
                }
                .padding(.top, 40)
                
                // Form Card
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome back")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.lovePink)
                        Text("Sign in to start showing Love.")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("EMAIL")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(Theme.textMuted)
                            
                            TextField("you@loveworks.com", text: $email)
                                .disableAutocorrection(true)
                                .padding()
                                .background(Theme.surface)
                                .cornerRadius(12)
                                .foregroundStyle(Theme.textMain)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Theme.border, lineWidth: 1)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PASSWORD")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(Theme.textMuted)
                            
                            ZStack(alignment: .trailing) {
                                if showPassword {
                                    TextField("••••••••", text: $password)
                                } else {
                                    SecureField("••••••••", text: $password)
                                }
                                
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Theme.textMuted)
                                        .padding(.trailing, 16)
                                }
                            }
                            .padding(.vertical, 4)
                            .background(Theme.surface)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.border, lineWidth: 1)
                            )
                        }
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.danger)
                            .padding(.vertical, 4)
                    }
                    
                    Button(action: handleLogin) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .tint(Color.white)
                            } else {
                                Text("Sign In")
                                    .font(.system(size: 17, weight: .black))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.loveGradient)
                        .foregroundStyle(.white)
                        .cornerRadius(100)
                        .shadow(color: Theme.lovePink.opacity(0.3), radius: 15, y: 8)
                    }
                    .disabled(isSubmitting)
                    
                    Text("Need an account? Ask your admin to invite you.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textMuted)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .background(Theme.surface)
                .cornerRadius(24)
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Theme.border, lineWidth: 1))
                .padding(.horizontal)
                
                Spacer()
            }
        }
    }
    
    private func handleLogin() {
        guard !email.isEmpty && !password.isEmpty else {
            errorMessage = "Please enter both email and password."
            return
        }
        
        isSubmitting = true
        errorMessage = nil
        
        Task {
            do {
                try await sessionManager.login(email: email, password: password)
                await MainActor.run {
                    isSubmitting = false
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = "Login failed. Please check your credentials."
                }
            }
        }
    }
}

struct FloatingIcon: View {
    let icon: String
    let color: Color
    let delay: Double
    let geo: GeometryProxy
    
    @State private var position = CGPoint(x: 0, y: 0)
    @State private var opacity = 0.0
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 24))
            .foregroundStyle(color.opacity(0.2))
            .position(position)
            .opacity(opacity)
            .onAppear {
                reset()
                animate()
            }
    }
    
    func reset() {
        position = CGPoint(
            x: CGFloat.random(in: 0...geo.size.width),
            y: geo.size.height + 50
        )
    }
    
    func animate() {
        let duration = Double.random(in: 12...25)
        withAnimation(.linear(duration: duration).delay(delay).repeatForever(autoreverses: false)) {
            position.y = -100
            opacity = 0.4
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(SessionManager.shared)
}
