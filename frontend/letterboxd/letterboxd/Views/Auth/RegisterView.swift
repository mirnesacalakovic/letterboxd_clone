import SwiftUI
import UIKit

struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var username = ""
    @State private var email = ""
    @State private var password = ""

    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case username
        case email
        case password
    }

    private var isPasswordValid: Bool {
        password.count >= 6
    }

    var body: some View {
        ZStack {
            authBackground

            ScrollView {
                VStack(spacing: 0) {
                    topBar
                        .padding(.top, 12)

                    VStack(spacing: 10) {
                        HStack(spacing: 4) {
                            Circle().fill(AppTheme.orange)
                            Circle().fill(AppTheme.green)
                            Circle().fill(AppTheme.blue)
                        }
                        .frame(width: 55, height: 16)

                        Text("Join Letterboxd")
                            .font(.title2.bold())
                            .foregroundStyle(.white)

                        Text("Create an account to keep your film diary, ratings, reviews, lists and watchlist in one place.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 30)

                    VStack(spacing: 14) {
                        authField(
                            icon: "person",
                            placeholder: "Username",
                            text: $username,
                            field: .username,
                            contentType: .username,
                            keyboardType: .default
                        )

                        authField(
                            icon: "envelope",
                            placeholder: "Email",
                            text: $email,
                            field: .email,
                            contentType: .emailAddress,
                            keyboardType: .emailAddress
                        )

                        authSecureField

                        HStack(spacing: 7) {
                            Image(systemName: isPasswordValid ? "checkmark.circle.fill" : "info.circle")
                                .foregroundStyle(isPasswordValid ? AppTheme.green : AppTheme.secondaryText)

                            Text("Password must be at least 6 characters.")
                                .foregroundStyle(AppTheme.secondaryText)

                            Spacer()
                        }
                        .font(.caption)

                        if let error = authViewModel.errorMessage {
                            errorBanner(error)
                        }

                        Button {
                            focusedField = nil
                            Task {
                                await authViewModel.register(
                                    username: username.trimmingCharacters(in: .whitespacesAndNewlines),
                                    email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                                    password: password
                                )
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .tint(.black)
                                }

                                Text(authViewModel.isLoading ? "Creating account…" : "CREATE ACCOUNT")
                                    .font(.subheadline.bold())
                                    .tracking(0.45)
                            }
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(AppTheme.green)
                            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(!canSubmit)
                        .opacity(canSubmit ? 1 : 0.48)

                        HStack(spacing: 5) {
                            Text("Already a member?")
                                .foregroundStyle(AppTheme.secondaryText)

                            Button("Sign in") {
                                authViewModel.errorMessage = nil
                                dismiss()
                            }
                            .foregroundStyle(AppTheme.blue)
                            .fontWeight(.semibold)
                        }
                        .font(.footnote)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(22)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(hex: "#1B2025"))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
                            }
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 28)
                    .padding(.bottom, 38)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            authViewModel.errorMessage = nil
        }
    }

    private var canSubmit: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        isPasswordValid &&
        !authViewModel.isLoading
    }

    private var topBar: some View {
        HStack {
            Button {
                authViewModel.errorMessage = nil
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color(hex: "#252D34"))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Create account")
                .font(.headline)
                .foregroundStyle(.white)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 18)
    }

    private var authBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "#14181C"),
                    Color(hex: "#20272D"),
                    Color(hex: "#14181C")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Circle()
                .fill(AppTheme.green.opacity(0.035))
                .frame(width: 280, height: 280)
                .offset(x: 165, y: -290)

            Circle()
                .fill(Color.white.opacity(0.02))
                .frame(width: 250, height: 250)
                .offset(x: -160, y: 350)
        }
    }

    private func authField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        field: Field,
        contentType: UITextContentType?,
        keyboardType: UIKeyboardType
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(hex: "#7F93A4"))
                .frame(width: 20)

            TextField(placeholder, text: text)
                .textContentType(contentType)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(.white)
                .focused($focusedField, equals: field)
                .submitLabel(.next)
                .onSubmit {
                    switch field {
                    case .username:
                        focusedField = .email
                    case .email:
                        focusedField = .password
                    case .password:
                        break
                    }
                }
        }
        .padding(.horizontal, 14)
        .frame(height: 50)
        .background(Color(hex: "#2A323A"))
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(
                    focusedField == field ? AppTheme.blue.opacity(0.8) : Color.white.opacity(0.07),
                    lineWidth: 1
                )
        }
    }

    private var authSecureField: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(hex: "#7F93A4"))
                .frame(width: 20)

            SecureField("Password", text: $password)
                .textContentType(.newPassword)
                .foregroundStyle(.white)
                .focused($focusedField, equals: .password)
                .submitLabel(.go)
                .onSubmit {
                    guard canSubmit else { return }
                    focusedField = nil
                    Task {
                        await authViewModel.register(
                            username: username.trimmingCharacters(in: .whitespacesAndNewlines),
                            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                            password: password
                        )
                    }
                }
        }
        .padding(.horizontal, 14)
        .frame(height: 50)
        .background(Color(hex: "#2A323A"))
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(
                    focusedField == .password ? AppTheme.blue.opacity(0.8) : Color.white.opacity(0.07),
                    lineWidth: 1
                )
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "exclamationmark.circle.fill")
                .padding(.top, 1)

            Text(message)
                .font(.footnote)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .foregroundStyle(Color(hex: "#FFB3B3"))
        .padding(11)
        .background(Color.red.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        RegisterView()
            .environmentObject(AuthViewModel())
    }
}
