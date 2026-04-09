import SwiftUI
import NetworkKit

struct UserListView: View {
    @State private var users: [User] = []
    @State private var error: NetworkError?
    @State private var isLoading = false
    @State private var selectedUser: User?

    private let client = NetworkManager.shared.client

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && users.isEmpty {
                    ProgressView("Loading users...")
                } else if let error {
                    errorView(error)
                } else {
                    userList
                }
            }
            .navigationTitle("Users")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Reload") {
                        Task { await loadUsers() }
                    }
                    .disabled(isLoading)
                }
            }
            .task { await loadUsers() }
            .sheet(item: $selectedUser) { user in
                UserDetailView(user: user)
            }
        }
    }

    private var userList: some View {
        List(users) { user in
            Button {
                selectedUser = user
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.name)
                        .font(.headline)
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let address = user.address {
                        Text("\(address.city)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.vertical, 4)
            }
            .tint(.primary)
        }
    }

    private func errorView(_ error: NetworkError) -> some View {
        ContentUnavailableView {
            Label(errorTitle(error), systemImage: errorIcon(error))
        } description: {
            Text(errorDescription(error))
        } actions: {
            Button("Try Again") {
                self.error = nil
                Task { await loadUsers() }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func loadUsers() async {
        isLoading = true
        error = nil
        do {
            users = try await client.request(JSONPlaceholderEndpoint.users)
        } catch let err as NetworkError {
            error = err
        } catch {}
        isLoading = false
    }

    private func errorTitle(_ error: NetworkError) -> String {
        switch error {
        case .noConnection: "No Connection"
        case .timeout: "Timed Out"
        case .serverError: "Server Error"
        default: "Something Went Wrong"
        }
    }

    private func errorIcon(_ error: NetworkError) -> String {
        switch error {
        case .noConnection: "wifi.slash"
        case .timeout: "clock.badge.xmark"
        default: "exclamationmark.triangle"
        }
    }

    private func errorDescription(_ error: NetworkError) -> String {
        switch error {
        case .noConnection: "Check your internet connection and try again."
        case .timeout: "The server took too long to respond."
        case .serverError(let code): "Server returned error \(code)."
        case .decodingFailed: "Couldn't parse the response."
        default: "An unexpected error occurred."
        }
    }
}

#Preview {
    UserListView()
}
