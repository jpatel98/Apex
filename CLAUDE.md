# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Apex is a proprietary iOS app that predicts caffeine crashes using pharmacokinetic modeling. Built with SwiftUI and SwiftData for iOS 17.0+.

## Build Commands

```bash
# Open in Xcode (primary development method)
open Apex.xcodeproj

# Build from command line
xcodebuild -project Apex.xcodeproj -scheme Apex -configuration Debug build

# Run on simulator
xcodebuild -project Apex.xcodeproj -scheme Apex -destination 'platform=iOS Simulator,name=iPhone 15' build
```

## Architecture

### Core Components
- **CaffeineCalculator.swift**: Implements pharmacokinetic model using first-order elimination kinetics. Core crash prediction algorithm with configurable half-life (4-6 hours based on sensitivity).
- **NotificationManager.swift**: Singleton managing crash alerts. Schedules notifications 30 minutes before predicted crashes.
- **SwiftData Models**: `User` and `CaffeineEntry` models with automatic persistence.

### UI Flow
1. **OnboardingView** → Initial setup (weight, sensitivity)
2. **MainTabView** → Tab navigation container
3. **DashboardView** → Real-time caffeine charts and crash predictions
4. **LogEntryView** → 4-step Q&A interface for logging caffeine
5. **HistoryView** → Past consumption with 7-day limit for free users
6. **SettingsView** → Profile, authentication, and subscription management

### Key Technical Decisions
- **No external dependencies**: Pure SwiftUI/SwiftData implementation
- **Freemium monetization**: Free (7-day history), Pro ($4.99/mo), Premium ($39.99/yr)
- **Privacy-first**: All data stored locally, no analytics
- **Scientific approach**: Based on peer-reviewed caffeine metabolism research (see docs/METHODOLOGY.md)

## Known Issues & TODOs

1. **Payment Processing**: Currently uses fake `UserDefaults.isPremiumUser = true`. Needs StoreKit integration.
2. **Data Export**: Premium feature shows "Exporting data..." but doesn't actually export. Implement CSV/JSON export.
3. **Authentication**: Accepts any email/password. Either implement properly or remove.
4. **Error Handling**: 11 print() statements should be user-facing alerts.
5. **Hardcoded Values**: Prices, limits, and timeouts scattered throughout. Create Constants.swift.
6. **Tests**: No unit tests exist. Priority: test CaffeineCalculator algorithms.

## Development Notes

- **No ViewModels**: Currently using SwiftUI's built-in state management. ViewModels directory exists but is empty.
- **Notification Reliability**: Current implementation may fail when app is backgrounded. Consider background tasks.
- **ModelContainer Error**: App crashes with fatalError if data initialization fails (ApexApp.swift:16).
- **Empty Handlers**: Several buttons (e.g., "Maybe Later") have empty closures `{ }`.

## When Making Changes

1. Follow existing Q&A UI pattern for new user inputs
2. Maintain colorful, gradient-heavy design language
3. Use SwiftData for any new persistent data
4. Check docs/PROJECT_PLAN.md for feature priorities
5. Scientific accuracy is critical - refer to docs/METHODOLOGY.md

## iOS Development Standards

When working on this codebase, follow these iOS development standards:

### Architecture Patterns
- **Current Pattern**: MVVM-lite (Views with inline state management)
- **Future Direction**: Full MVVM with dedicated ViewModels for complex views
- **Data Flow**: SwiftUI state management (@State, @StateObject, @Published)

### Code Standards
- **Swift Version**: Latest stable (currently 5.9)
- **UI Framework**: SwiftUI exclusively (no UIKit)
- **Concurrency**: Use async/await patterns
- **Optional Handling**: Always use `guard let` or `if let` - never force unwrap
- **Documentation**: Add Swift-DocC comments for public methods

### Testing Strategy
- **Unit Tests**: Priority on CaffeineCalculator algorithms
- **UI Tests**: Test critical user flows (onboarding, logging caffeine, viewing predictions)
- **Test Framework**: XCTest

### Safety & Security
- **No Force Unwrapping**: Replace all `!` with safe unwrapping
- **Error Handling**: Replace print() with proper error alerts
- **Sensitive Data**: Never log user data or authentication tokens
- **Background Tasks**: Implement proper background task handling for notifications

### When Implementing Features
1. **Analyze existing patterns** in similar views/components
2. **Maintain consistency** with current UI design language
3. **Follow SwiftData patterns** for any data persistence
4. **Test on multiple device sizes** (iPhone SE to Pro Max)
5. **Verify iOS 17.0 compatibility** for all APIs used