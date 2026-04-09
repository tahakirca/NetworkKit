import SwiftUI
import NetworkKit

struct UserDetailView: View {
    let user: User

    @State private var posts: [Post] = []
    @State private var isLoading = false
    @State private var showCreatePost = false
    @State private var newPostTitle = ""
    @State private var newPostBody = ""
    @State private var isCreating = false

    @Environment(\.dismiss) private var dismiss

    private let client = NetworkManager.shared.client

    var body: some View {
        NavigationStack {
            List {
                userInfoSection
                createPostSection
                postsSection
            }
            .navigationTitle(user.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await loadPosts() }
        }
    }

    private var userInfoSection: some View {
        Section("Info") {
            LabeledContent("Username", value: user.username)
            LabeledContent("Email", value: user.email)
            LabeledContent("Phone", value: user.phone)
            if let address = user.address {
                LabeledContent("City", value: address.city)
            }
        }
    }

    private var createPostSection: some View {
        Section("New Post") {
            TextField("Title", text: $newPostTitle)
            TextField("Body", text: $newPostBody, axis: .vertical)
                .lineLimit(3...6)
            Button {
                Task { await createPost() }
            } label: {
                if isCreating {
                    ProgressView()
                } else {
                    Text("Create Post")
                }
            }
            .disabled(newPostTitle.isEmpty || newPostBody.isEmpty || isCreating)
        }
    }

    private var postsSection: some View {
        Section("Posts (\(posts.count))") {
            if isLoading {
                ProgressView()
            } else if posts.isEmpty {
                Text("No posts yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(posts) { post in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(post.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(post.body)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func loadPosts() async {
        isLoading = true
        do {
            posts = try await client.request(
                JSONPlaceholderEndpoint.posts(userId: user.id)
            )
        } catch {
            print("Failed to load posts: \(error)")
        }
        isLoading = false
    }

    private func createPost() async {
        isCreating = true
        do {
            // .request<T> decodes the response into a Post
            let post: Post = try await client.request(
                JSONPlaceholderEndpoint.createPost(
                    title: newPostTitle,
                    body: newPostBody,
                    userId: user.id
                )
            )
            // JSONPlaceholder returns the created post with id: 101
            posts.insert(post, at: 0)
            newPostTitle = ""
            newPostBody = ""
        } catch {
            print("Failed to create post: \(error)")
        }
        isCreating = false
    }
}

#Preview {
    UserDetailView(user: User(
        id: 1,
        name: "Leanne Graham",
        username: "Bret",
        email: "leanne@example.com",
        phone: "1-770-736-8031",
        address: User.Address(street: "Kulas Light", suite: "Apt. 556", city: "Gwenborough", zipcode: "92998-3874")
    ))
}
