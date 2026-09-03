import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false

    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case email
        case password
    }

    var body: some View {
        NavigationStack {
            ZStack {
                authBackground

                ScrollView {
                    VStack(spacing: 0) {
                        brandHeader
                            .padding(.top, 74)

                        VStack(alignment: .leading, spacing: 22) {
                            VStack(alignment: .leading, spacing: 7) {
                                Text("Welcome back")
                                    .font(.title2.bold())
                                    .foregroundStyle(.white)

                                Text("Sign in to keep tracking, rating and reviewing films.")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.secondaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            VStack(spacing: 12) {
                                authTextField(
                                    icon: "envelope",
                                    placeholder: "Email",
                                    text: $email,
                                    field: .email
                                )

                                authSecureField(
                                    icon: "lock",
                                    placeholder: "Password",
                                    text: $password,
                                    field: .password
                                )
                            }

                            if let error = authViewModel.errorMessage {
                                errorBanner(error)
                            }

                            Button {
                                focusedField = nil
                                Task {
                                    await authViewModel.login(
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

                                    Text(authViewModel.isLoading ? "Signing in…" : "SIGN IN")
                                        .font(.subheadline.bold())
                                        .tracking(0.5)
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
                                Text("New to Letterboxd?")
                                    .foregroundStyle(AppTheme.secondaryText)

                                Button("Create an account") {
                                    authViewModel.errorMessage = nil
                                    showRegister = true
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
                        .padding(.top, 34)

                        Text("Track films. Rate what you watch. Share what you love.")
                            .font(.caption)
                            .foregroundStyle(Color(hex: "#6F8291"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 44)
                            .padding(.top, 24)
                            .padding(.bottom, 40)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showRegister) {
                RegisterView()
            }
        }
    }

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty &&
        !authViewModel.isLoading
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
                .fill(Color.white.opacity(0.025))
                .frame(width: 300, height: 300)
                .offset(x: 145, y: -300)

            Circle()
                .fill(AppTheme.blue.opacity(0.035))
                .frame(width: 220, height: 220)
                .offset(x: -160, y: 330)
        }
    }

    private var brandHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 5) {
                Circle().fill(AppTheme.orange)
                Circle().fill(AppTheme.green)
                Circle().fill(AppTheme.blue)
            }
            .frame(width: 76, height: 22)

            Text("Letterboxd")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .tracking(-1)
        }
    }

    private func authTextField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        field: Field
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(hex: "#7F93A4"))
                .frame(width: 20)

            TextField(placeholder, text: text)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(.white)
                .focused($focusedField, equals: field)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .password
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

    private func authSecureField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        field: Field
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(hex: "#7F93A4"))
                .frame(width: 20)

            SecureField(placeholder, text: text)
                .textContentType(.password)
                .foregroundStyle(.white)
                .focused($focusedField, equals: field)
                .submitLabel(.go)
                .onSubmit {
                    guard canSubmit else { return }
                    focusedField = nil
                    Task {
                        await authViewModel.login(
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
                    focusedField == field ? AppTheme.blue.opacity(0.8) : Color.white.opacity(0.07),
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
    LoginView()
        .environmentObject(AuthViewModel())
}
