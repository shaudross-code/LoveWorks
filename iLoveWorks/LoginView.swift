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
            
            
            VStack(spacing: 0) {
                // Header (matches left side of web for mobile)
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Theme.loveGradient)
                                .frame(width: 48, height: 48)
                                .shadow(color: Theme.lovePink.opacity(0.3), radius: 10, y: 5)
                            
                            Image(systemName: "heart.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("iLoveWorks")
                                .font(.custom("Outfit-Bold", size: 24))
                                .foregroundStyle(Theme.primary)
                            Text("LOVE · TASKS · GIFTS")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.textMuted)
                                .tracking(2)
                        }
                    }
                    .padding(.top, 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Show your Love.")
                            .font(.custom("Outfit-Bold", size: 36))
                            .foregroundStyle(Theme.lovePink)
                            .shadow(color: Theme.lovePink.opacity(0.35), radius: 22)
                        
                        Text("Get Loved with Gifts.")
                            .font(.custom("Outfit-Bold", size: 36))
                            .foregroundStyle(Theme.primary)
                    }
                    .padding(.top, 16)
                    
                    Text("Track everyday acts of love — work, study, breaks, parenting — set goals, and let appreciation flow back as gifts. Charmingly pink & gold.")
                        .font(.system(size: 16))
                        .lineSpacing(4)
                        .foregroundStyle(Theme.textMuted)
                        .padding(.top, 16)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.lovePink)
                        Text("Secured with JWT • Admin invitations only")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textMuted)
                    }
                    .padding(.top, 24)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Form Card (matches right side of web)
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome back")
                            .font(.custom("Outfit-Bold", size: 30))
                            .foregroundStyle(Theme.lovePink)
                            .shadow(color: Theme.lovePink.opacity(0.35), radius: 18)
                        Text("Sign in to start showing Love.")
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("EMAIL")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(Theme.textMuted)
                                .tracking(1)
                            
                            TextField("you@company.com", text: $email)
                                .disableAutocorrection(true)
                                .padding()
                                .background(Color(red: 24/255, green: 24/255, blue: 27/255).opacity(0.7))
                                .cornerRadius(12)
                                .foregroundStyle(Theme.textMain)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(red: 39/255, green: 39/255, blue: 42/255), lineWidth: 1)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PASSWORD")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(Theme.textMuted)
                                .tracking(1)
                            
                            ZStack(alignment: .trailing) {
                                if showPassword {
                                    TextField("••••••••", text: $password)
                                        .padding()
                                        .background(Color(red: 24/255, green: 24/255, blue: 27/255).opacity(0.7))
                                        .cornerRadius(12)
                                        .foregroundStyle(Theme.textMain)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(red: 39/255, green: 39/255, blue: 42/255), lineWidth: 1)
                                        )
                                } else {
                                    SecureField("••••••••", text: $password)
                                        .padding()
                                        .background(Color(red: 24/255, green: 24/255, blue: 27/255).opacity(0.7))
                                        .cornerRadius(12)
                                        .foregroundStyle(Theme.textMain)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(red: 39/255, green: 39/255, blue: 42/255), lineWidth: 1)
                                        )
                                }
                                
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .font(.system(size: 16))
                                        .foregroundStyle(Theme.textMuted)
                                        .padding(.trailing, 16)
                                }
                            }
                        }
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundStyle(Color(red: 248/255, green: 113/255, blue: 113/255))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.1))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.2), lineWidth: 1))
                    }
                    
                    Button(action: handleLogin) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .tint(Color.black)
                            } else {
                                Text("Sign in")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.primary)
                        .foregroundStyle(.black)
                        .cornerRadius(12)
                    }
                    .disabled(isSubmitting)
                    
                    HStack(spacing: 4) {
                        Text("Need an account? Ask your admin to invite you.")
                            .foregroundStyle(Theme.textMuted)
                        Text("·")
                            .foregroundStyle(Theme.textMuted)
                        Text("Privacy")
                            .foregroundStyle(.white)
                            .underline()
                    }
                    .font(.system(size: 12))
                    .padding(.top, 8)
                }
                .padding(32)
                .background(Color(red: 18/255, green: 18/255, blue: 20/255))
                .cornerRadius(24)
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Theme.lovePink.opacity(0.15), lineWidth: 1))
                .shadow(color: Theme.lovePink.opacity(0.1), radius: 25)
                .padding(24)
                .padding(.bottom, 20)
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
