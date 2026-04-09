# NetworkKit

A lightweight networking library for Swift. Built on async/await and URLSession — no dependencies, no magic.

Comes with an interceptor chain for auth, logging, and retry out of the box.

## What's included

- Async/await all the way — no completion handlers, no Combine
- Protocol-based `Endpoint` for type-safe request definitions
- Interceptor chain — composable, pluggable, runs in order
- `AuthInterceptor` with single-flight token refresh (even if 5 requests hit 401 at once, only one refresh happens)
- `LoggingInterceptor` that auto-redacts sensitive headers
- `RetryInterceptor` with exponential backoff and Retry-After support
- `NetworkError` you can pattern match on exhaustively
- Case-insensitive `HTTPHeaders` with multi-value support
- Swift 6 strict concurrency safe
- Static and dynamic linking

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/tahakirca/NetworkKit.git", from: "1.0.0")
]
```

Two products:
- `NetworkKit` — static linking, works for most projects
- `NetworkKitDynamic` — dynamic linking, useful when multiple modules depend on the same library

## Getting started

### 1. Define an endpoint

```swift
import NetworkKit

enum UserEndpoint: Endpoint {
    case list
    case profile(id: Int)
    case create(name: String, email: String)
    case delete(id: Int)

    var baseURL: URL { URL(string: "https://api.example.com")! }

    var path: String {
        switch self {
        case .list: "/users"
        case .profile(let id): "/users/\(id)"
        case .create: "/users"
        case .delete(let id): "/users/\(id)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .list, .profile: .GET
        case .create: .POST
        case .delete: .DELETE
        }
    }

    var body: RequestBody? {
        switch self {
        case .create(let name, let email):
            .json(["name": name, "email": email])
        default:
            nil
        }
    }
}
```

### 2. Create a client

```swift
let client = HTTPClient()
```

### 3. Make requests

```swift
// Decoded — JSON straight into your model
let users: [User] = try await client.request(UserEndpoint.list)

let user: User = try await client.request(UserEndpoint.profile(id: 5))

// Raw — when you need the data directly (images, files, etc.)
let response = try await client.requestRaw(UserEndpoint.profile(id: 5))
let data = response.data
let status = response.statusCode
let contentType = response.headers["Content-Type"]

// Void — fire and forget (DELETE, logout, that kind of thing)
try await client.send(UserEndpoint.delete(id: 5))
```

## Interceptors

Interceptors sit between your code and URLSession. They can modify requests, observe responses, and decide whether to retry on failure. They run in the order you add them.

### Using the built-in ones

```swift
let tokenManager = TokenManager(
    provider: MyAuthProvider(),
    store: MyKeychainStore()
)

let client = HTTPClient(
    interceptors: [
        AuthInterceptor(tokenManager: tokenManager),
        LoggingInterceptor(),
        RetryInterceptor()
    ]
)

// Now every request will:
// 1. Get a Bearer token attached
// 2. Get logged with sensitive headers redacted
// 3. Retry on transient failures with exponential backoff
// 4. Auto-refresh the token on 401 (no race conditions)
```

### Writing your own

```swift
struct APIKeyInterceptor: Interceptor {
    let apiKey: String

    func adapt(_ request: URLRequest) async throws -> URLRequest {
        var request = request
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        return request
    }
}

let client = HTTPClient(
    interceptors: [APIKeyInterceptor(apiKey: "abc123")]
)
```

## How the chain works

Three phases, all running in order:

```
Request:  → adapt → adapt → adapt → URLSession
Response: ← response ← response ← response
Error:    → retry → retry → retry → throw or retry
```

| Phase | What it does | Example |
|---|---|---|
| `adapt` | Tweaks the request before it goes out | Add auth token, API key, custom headers |
| `response` | Observes the response after it comes back | Log status codes, measure timing |
| `retry` | Decides whether to retry on failure | Refresh token on 401, back off on 500 |

## Auth & token refresh

`AuthInterceptor` + `TokenManager` handle the whole auth flow. You just provide two things:

```swift
struct MyAuthProvider: TokenProvider {
    func refreshToken() async throws -> String {
        // Hit your auth API, return the new access token
    }
}

actor MyKeychainStore: TokenStore {
    func save(token: String) async { /* write to Keychain */ }
    func get() async -> String? { /* read from Keychain */ }
    func clear() async { /* delete from Keychain */ }
}
```

NetworkKit takes care of the rest:
1. Every request gets `Authorization: Bearer <token>`
2. On 401 → refreshes the token → retries the request
3. If multiple requests hit 401 at the same time, only one refresh runs — the rest just wait

## Retry

`RetryInterceptor` deals with transient failures:

```swift
RetryInterceptor(
    maxRetries: 3,              // how many times to retry
    baseDelay: 1.0,             // starting delay
    exponentialBackoff: true,    // 1s → 2s → 4s
    retryableStatusCodes: [408, 429, 500, 502, 503, 504]
)
```

- Honors `Retry-After` from the server (both seconds and HTTP-date formats)
- Only retries on transient stuff (timeout, 500, 503)
- Won't retry on permanent errors (400, 401, 404)

## Logging

`LoggingInterceptor` has 4 log levels and only runs in DEBUG builds — production gets zero log output regardless of the level you set.

```swift
// Just URL + status code
LoggingInterceptor(level: .minimal)

// + request headers with sensitive ones redacted (default)
LoggingInterceptor(level: .headers)

// + pretty-printed response body
LoggingInterceptor(level: .body)

// Completely off
LoggingInterceptor(level: .none)
```

Output at `.body` level:
```
→ GET https://api.example.com/users [Authorization: ████████, Content-Type: application/json]
← 200 https://api.example.com/users (1234 bytes)
📦 Response:
[
  {
    "id" : 1,
    "name" : "Leanne Graham"
  }
]
```

Header redaction is case-insensitive — `authorization`, `AUTHORIZATION`, `Authorization` all get masked. You can also add your own sensitive headers:

```swift
LoggingInterceptor(level: .headers, sensitiveHeaders: ["Authorization", "X-API-Key"])
```

## Error handling

```swift
do {
    let user: User = try await client.request(UserEndpoint.profile(id: 5))
} catch NetworkError.unauthorized {
    // Token refresh failed too — time to show the login screen
} catch NetworkError.notFound {
    // User doesn't exist
} catch NetworkError.decodingFailed(_, let data) {
    // Model didn't match — check the raw response
    print(String(data: data, encoding: .utf8) ?? "")
} catch NetworkError.tooManyRequests(let retryAfter) {
    // Rate limited
    print("Try again in \(retryAfter ?? 0) seconds")
} catch NetworkError.noConnection {
    // No internet
} catch NetworkError.timeout {
    // Took too long
} catch {
    // Something else
}
```

### All error cases

| Error | When |
|---|---|
| `.invalidURL` | Couldn't build a valid URL from the endpoint |
| `.encodingFailed` | JSON encoding blew up |
| `.decodingFailed` | JSON decoding failed (raw data is included so you can debug) |
| `.unauthorized` | 401 |
| `.forbidden` | 403 |
| `.notFound` | 404 |
| `.tooManyRequests` | 429 (includes Retry-After if the server sent one) |
| `.serverError` | 500-599 |
| `.httpError` | Other non-2xx (includes status code and body) |
| `.noConnection` | No internet connection |
| `.timeout` | Request timed out |
| `.cancelled` | Task was cancelled |
| `.unknown` | Something unexpected |

## Request body types

```swift
// JSON — the one you'll use most
var body: RequestBody? {
    .json(CreateUserRequest(name: "Taha", email: "taha@example.com"))
}

// Form URL encoded — OAuth, login forms
var body: RequestBody? {
    .formURLEncoded(["grant_type": "password", "username": "taha", "password": "123"])
}

// Raw data — images, files, whatever
var body: RequestBody? {
    .data(imageData, contentType: "image/jpeg")
}

// No body (this is the default) — GET, DELETE
var body: RequestBody? { nil }
```

## Response headers

Case-insensitive, multi-value header access:

```swift
let response = try await client.requestRaw(endpoint)

response.headers["Content-Type"]           // "application/json"
response.headers["content-type"]           // same thing
response.headers.values(for: "Set-Cookie") // ["session=abc", "lang=en"]
```

## Configuration

```swift
let client = HTTPClient(
    session: customURLSession,          // default: .shared
    interceptors: [auth, logging],      // default: none
    decoder: customDecoder,             // default: JSONDecoder()
    encoder: customEncoder              // default: JSONEncoder()
)

// Example: working with a snake_case API
let decoder = JSONDecoder()
decoder.keyDecodingStrategy = .convertFromSnakeCase
decoder.dateDecodingStrategy = .iso8601

let client = HTTPClient(decoder: decoder)
```

## Architecture

```
┌─────────────┐     ┌──────────────┐     ┌──────────────┐
│   Endpoint   │ ──→ │  HTTPClient  │ ──→ │  URLSession  │
│  (protocol)  │     │   (engine)   │     │   (Apple)    │
└─────────────┘     └──────┬───────┘     └──────────────┘
                           │
                    ┌──────┴───────┐
                    │ Interceptors │
                    │  adapt()     │
                    │  response()  │
                    │  retry()     │
                    └──────────────┘
```

## Example App

There's a full working iOS app in [`Examples/ExampleApp/`](Examples/ExampleApp/). Open `ExampleApp.xcodeproj` in Xcode, pick a simulator, hit Run.

It uses [JSONPlaceholder](https://jsonplaceholder.typicode.com) as a fake API and shows:
- Endpoint definitions
- HTTPClient setup with interceptors (auth + logging + retry)
- Fetching and displaying a user list
- Creating a post (POST request with JSON body)
- Error handling with NetworkError
- TokenProvider and TokenStore implementation

## Requirements

- iOS 17+ / macOS 14+
- Swift 6.0+
- Xcode 16+

## License

MIT
