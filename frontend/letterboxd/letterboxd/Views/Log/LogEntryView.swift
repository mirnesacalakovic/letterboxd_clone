import SwiftUI

struct LogEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: LogEntryViewModel

    let onSaved: () -> Void

    init(movie: Movie, onSaved: @escaping () -> Void) {
        _vm = StateObject(wrappedValue: LogEntryViewModel(movie: movie))
        self.onSaved = onSaved
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.secondaryBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        filmHeader
                        Divider().overlay(Color.white.opacity(0.08))
                        dateRow
                        Divider().overlay(Color.white.opacity(0.08))
                        ratingRow
                        Divider().overlay(Color.white.opacity(0.08))
                        reviewSection
                        Divider().overlay(Color.white.opacity(0.08))
                        tagsSection
                        Divider().overlay(Color.white.opacity(0.08))
                        optionBar
                    }
                }
                .scrollDismissesKeyboard(.interactively)

                if vm.isLoading || vm.isSaving {
                    Color.black.opacity(0.25).ignoresSafeArea()
                    ProgressView()
                        .tint(AppTheme.green)
                        .scaleEffect(1.15)
                }
            }
            .navigationTitle("I Watched…")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.secondaryBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.secondaryText)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await vm.save() }
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.green)
                    .disabled(vm.isSaving || !vm.canSave)
                }
            }
            .task {
                await vm.loadState()
            }
            .onChange(of: vm.didSave) { _, saved in
                guard saved else { return }
                onSaved()
                dismiss()
            }
            .alert("Couldn’t save", isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(vm.errorMessage ?? "Unknown error")
            }
        }
        .presentationDragIndicator(.visible)
    }

    private var filmHeader: some View {
        HStack(spacing: 12) {
            PosterView(url: vm.movie.posterUrl, width: 44, height: 64)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(vm.movie.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    if let year = vm.movie.releaseYear {
                        Text(String(year))
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var dateRow: some View {
        HStack {
            Text("Date")
                .foregroundStyle(AppTheme.secondaryText)

            Spacer()

            DatePicker(
                "",
                selection: $vm.watchedDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .environment(\.colorScheme, .dark)
            .tint(AppTheme.green)
        }
        .font(.subheadline)
        .padding(.horizontal, 14)
        .frame(minHeight: 48)
    }

    private var ratingRow: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Rated")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)

                HStack(spacing: 8) {
                    HalfStarRatingPicker(rating: $vm.rating)

                    if vm.rating > 0 {
                        Button {
                            vm.clearRating()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Spacer()

            Button {
                vm.liked.toggle()
            } label: {
                VStack(spacing: 4) {
                    Text("Like")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                    Image(systemName: vm.liked ? "heart.fill" : "heart")
                        .font(.system(size: 31))
                        .foregroundStyle(vm.liked ? AppTheme.green : AppTheme.secondaryText.opacity(0.45))
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var reviewSection: some View {
        ZStack(alignment: .topLeading) {
            if vm.reviewText.isEmpty {
                Text("Add review…")
                    .foregroundStyle(AppTheme.secondaryText.opacity(0.75))
                    .padding(.horizontal, 18)
                    .padding(.top, 15)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $vm.reviewText)
                .scrollContentBackground(.hidden)
                .foregroundStyle(.white)
                .frame(minHeight: 190)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
        }
    }

    private var tagsSection: some View {
        TextField("Add tags…  (comma separated)", text: $vm.tagsText)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .frame(minHeight: 52)
    }

    private var optionBar: some View {
        HStack(spacing: 0) {
            LogOptionButton(
                icon: "arrow.triangle.2.circlepath",
                title: "I've seen this\nfilm before",
                isOn: $vm.isRewatch
            )

            LogOptionButton(
                icon: "theatermasks",
                title: vm.isSpoiler ? "Contains\nspoilers" : "No spoilers",
                isOn: $vm.isSpoiler
            )

            LogOptionButton(
                icon: "quote.bubble",
                title: vm.commentsAllowed ? "Anyone can\nreply" : "Replies\noff",
                isOn: $vm.commentsAllowed
            )
        }
        .padding(.vertical, 16)
    }
}

private struct HalfStarRatingPicker: View {
    @Binding var rating: Double

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { star in
                ZStack {
                    Image(systemName: symbol(for: star))
                        .font(.system(size: 28))
                        .foregroundStyle(AppTheme.green)

                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                rating = Double(star) - 0.5
                            }

                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                rating = Double(star)
                            }
                    }
                }
                .frame(width: 30, height: 32)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rating")
        .accessibilityValue(rating > 0 ? "\(rating) out of 5" : "Not rated")
    }

    private func symbol(for star: Int) -> String {
        let fullValue = Double(star)
        let halfValue = fullValue - 0.5

        if rating >= fullValue {
            return "star.fill"
        }
        if rating >= halfValue {
            return "star.leadinghalf.filled"
        }
        return "star"
    }
}

private struct LogOptionButton: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(isOn ? AppTheme.green : AppTheme.secondaryText.opacity(0.45))

                Text(title)
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(isOn ? .white : AppTheme.secondaryText)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
