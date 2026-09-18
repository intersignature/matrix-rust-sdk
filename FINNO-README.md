# Finnomena fork of matrix-rust-sdk

Fork: https://github.com/intersignature/matrix-rust-sdk (personal, not yet under the `finnomena` org).
Upstream: https://github.com/matrix-org/matrix-rust-sdk

## Branch / tag convention

- `finno-main` — upstream release commit + Finnomena patches. Base: `48e07662` (= matrix-rust-components-swift release 26.09.07).
- Tags: `<upstream-swift-release>-finno-0.0.N`, e.g. `26.09.07-finno-0.0.1`.
- To move to a newer upstream release: find the commit in the "Bump to version X (matrix-rust-sdk/main <sha>)" commit of
  https://github.com/matrix-org/matrix-rust-components-swift, then `git rebase --onto <sha> <old-base> finno-main`.

## Patches on top of upstream

| Swift API | Purpose | Replaces (finnomena/matrix-ios-sdk) |
|---|---|---|
| `Client.loginWithToken(token:initialDeviceName:deviceId:)` | `m.login.token` login | `kMXLoginFlowTypeToken` |
| `Room.accountData(eventType:)` | custom room account data from the store (content JSON) | PR #3 `getCustomEvent` |
| `Room.accountDataOrFetch(eventType:)` | store first, else fetch + persist, `M_NOT_FOUND` negative cache | PR #6 `customEventOfType:` |
| `Room.stateEvent(eventType:stateKey:)` | custom state event content from the store | `stateEvents(with: .custom(...))` |
| `Package.swift` / `Debug-Package.swift` → iOS 14 | match nter deployment target | — |

Reply fallbacks (PR #4) need no patch: the Rust SDK never generates them (MSC2781).
VoIP PRs (#1, #2, #5, #7) have no equivalent: the Rust SDK has no legacy `m.call.*` implementation.

## Build for nter

    bindings/apple/finno-build-xcframework.sh

Produces `bindings/apple/generated/MatrixSDKFFI.xcframework` (ios-arm64 + ios-arm64-simulator, minos 14.0),
`bindings/apple/generated/swift/*.swift`, and copies `bindings/apple/Debug-Package.swift` to `./Package.swift`.
nter references this checkout with an SPM `path:` dependency (see nter `NterApp/project.yml`).

## Tests for the patches

    cargo test -p matrix-sdk --lib account_data_or_fetch
    cargo clippy -p matrix-sdk-ffi -- -D warnings
