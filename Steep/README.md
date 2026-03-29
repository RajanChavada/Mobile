# Steep (SwiftUI Scratch MVP)

This folder contains a SwiftUI-first scratch MVP scaffold for the Steep iOS app based on `AGENT.md`, `PROJECT.md`, and `SCREENS_FLOW.md`.

## Implemented in this scaffold

- App shell with 4 visible tabs + center floating quick-log action
- Guest mode + action-triggered sign-in sheet
- 3-step onboarding flow
- Map -> venue detail -> quick log loop
- Optimistic log insert with rollback on failure
- Optimistic follow/unfollow with rollback on failure
- Offline pending log queue with retry when network returns
- Inline error/info banners (no `UIAlertController`)
- Design token system (`ColorToken`, `Typography`, `Spacing`, `Radius`)
- Supabase-ready backend boundary + mock backend for local development

## Security conventions enforced

- Google Places key is not used by the iOS client and should stay in Edge Function env only
- Supabase queries in `SupabaseBackendService` require an authenticated session token
- `SUPABASE_SECRET` is treated as server-only and should not be used in client builds

## Required environment for real backend wiring

Set these as Xcode scheme environment variables (or xcconfig-backed build settings):

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE`

Optional but currently ignored on client:

- `GOOGLE_MAPS_API` (or `GOOGLE_API_KEY`) - should remain server-side only
- `SUPABASE_SECRET` - should remain server-side only

## Main files

- `App/SipApp.swift`
- `App/AppStore.swift`
- `Features/Map/MapScreen.swift`
- `Features/Log/QuickLogSheet.swift`
- `Features/Feed/FeedScreen.swift`
- `Features/Profile/ProfileScreen.swift`
- `Services/SupabaseBackendService.swift`
- `Services/MockBackendService.swift`

## CI (No Local Xcode)

- Workflow: `.github/workflows/ios-ci.yml`
- Runner: `macos-15`
- Actions performed:
  - install `xcodegen`
  - generate `Steep.xcodeproj` from `project.yml`
  - `xcodebuild clean build` for iOS Simulator
  - `xcodebuild test` (runs `SteepTests`)

You can run it from GitHub Actions via `workflow_dispatch` or by pushing a branch/PR that changes files in `Steep/**`.
