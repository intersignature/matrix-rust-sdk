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
| `Room.stateEventOrFetch(eventType:stateKey:)` | store first, else `GET .../state/{type}/{key}?format=event`; persisted when the server returns the full event | `stateEvents(with: .custom(...))` under sliding sync (custom state is never synced) |
| `Package.swift` / `Debug-Package.swift` → iOS 14 | match nter deployment target | — |

Reply fallbacks (PR #4) need no patch: the Rust SDK never generates them (MSC2781).
VoIP PRs (#1, #2, #5, #7) have no equivalent: the Rust SDK has no legacy `m.call.*` implementation.

## API notes for the app

- `Room.accountData`, `Room.accountDataOrFetch`, `Room.stateEvent` and `Room.stateEventOrFetch` return the
  event **`content`** object as a JSON string. Upstream `Client.accountData(eventType:)` returns the **whole
  event** JSON (`{"type": ..., "content": ...}`) — same selector name, different payload.
- `Room.accountDataOrFetch` issues at most one `GET` per (user, room, type) per process; after `M_NOT_FOUND`
  it answers `nil` without a request until the app restarts. A value created server-side later still
  arrives through sync (room account data is synced for all types).
- `Room.stateEventOrFetch` has no negative cache. Sliding sync never delivers custom state types, so the
  first read per process fetches; the event is persisted only when the homeserver honours `format=event`.
- `Room.stateEventOrFetch` needs the exact state key. If a custom state type can be written under several
  state keys, confirm the key with the backend before relying on it.

## Build for nter

    bindings/apple/finno-build-xcframework.sh

Produces `bindings/apple/generated/MatrixSDKFFI.xcframework` (ios-arm64 + ios-arm64_x86_64-simulator, minos 14.0; the simulator slice is universal because nter can build for the Rosetta simulator),
`bindings/apple/generated/swift/*.swift`, and copies `bindings/apple/Debug-Package.swift` to `./Package.swift`.
nter references this checkout with an SPM `path:` dependency (see nter `NterApp/project.yml`).
Both the root `Package.swift` and `bindings/apple/generated/` are generated and git-ignored: after a fresh clone, run the script once before nter's `xcodegen` can resolve the package.

## Verify the patches

    cargo test -p matrix-sdk --lib account_data_or_fetch
    cargo test -p matrix-sdk --lib state_event_or_fetch
    cargo check -p matrix-sdk-ffi

`cargo clippy -p matrix-sdk-ffi -- -D warnings` fails on a clean upstream checkout of this commit
(an unfulfilled `#[expect]` lint in `crates/matrix-sdk/src/widget/mod.rs` on stable Rust); it is not
caused by the fork. Use `cargo clippy -p matrix-sdk-ffi` and check that no warning points at the
patched files.
