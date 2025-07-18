# Apex - Caffeine Crash Forecaster

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS%2017.0+-blue.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.9-orange.svg" alt="Swift">
  <img src="https://img.shields.io/badge/SwiftUI-5.0-green.svg" alt="SwiftUI">
  <img src="https://img.shields.io/badge/License-Proprietary-red.svg" alt="License">
</p>

## Overview

Apex is an intelligent iOS app that predicts and prevents caffeine crashes before they happen. Using pharmacokinetic modeling and personalized sensitivity settings, Apex tracks your caffeine intake throughout the day and alerts you 30 minutes before a predicted crash, giving you time to take preventive action.

### Key Features

- **🔮 Crash Prediction**: Advanced algorithms predict when your caffeine levels will drop below your personal threshold
- **📊 Real-time Tracking**: Monitor your current caffeine levels with beautiful, interactive charts
- **⏰ Smart Notifications**: Get alerted 30 minutes before a predicted crash
- **🎯 Personalized Sensitivity**: Customize crash thresholds based on your caffeine tolerance
- **📝 Quick Logging**: Log drinks with our intuitive Q&A style interface
- **📈 History Tracking**: View your caffeine consumption patterns over time
- **🔐 Authentication**: Secure sign-in to sync data across devices
- **🌈 Colorful UI**: Modern, vibrant interface with smooth animations

## Screenshots

<p align="center">
  <img src="docs/screenshots/dashboard.png" width="250" alt="Dashboard">
  <img src="docs/screenshots/log-entry.png" width="250" alt="Log Entry">
  <img src="docs/screenshots/settings.png" width="250" alt="Settings">
</p>

## Installation

### Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

### Setup

1. Clone the repository:
```bash
git clone https://github.com/jpatel98/Apex.git
cd Apex
```

2. Open the project in Xcode:
```bash
open Apex.xcodeproj
```

3. Select your development team in the project settings

4. Build and run on your simulator or device

## Architecture

Apex is built using modern iOS development practices:

- **SwiftUI**: For the entire user interface
- **SwiftData**: For persistent storage and data modeling
- **Combine**: For reactive programming patterns
- **UserNotifications**: For crash alerts

### Project Structure

```
Apex/
├── Models/
│   ├── User.swift              # User profile and settings
│   └── CaffeineEntry.swift     # Caffeine consumption records
├── Views/
│   ├── MainTabView.swift       # Tab navigation
│   ├── DashboardView.swift     # Main dashboard with charts
│   ├── LogEntryView.swift      # Q&A style caffeine logging
│   ├── HistoryView.swift       # Historical data view
│   ├── SettingsView.swift      # User settings and auth
│   └── OnboardingView.swift    # Initial setup flow
├── Services/
│   ├── CaffeineCalculator.swift    # Core prediction algorithms
│   └── NotificationManager.swift   # Notification scheduling
├── docs/
│   ├── METHODOLOGY.md          # Scientific approach
│   └── PROJECT_PLAN.md         # Development roadmap
└── ApexApp.swift               # App entry point
```

## Features in Detail

### 1. Caffeine Tracking

The app uses a step-by-step Q&A interface for logging caffeine:
- Select from preset drinks or add custom entries
- Specify the exact time of consumption
- Support for both mg and cup-based measurements

### 2. Crash Prediction Algorithm

Apex uses first-order elimination kinetics to model caffeine metabolism:
- Default half-life: 5 hours (customizable based on sensitivity)
- Considers multiple doses throughout the day
- Predicts crashes when levels drop below 30% of peak

[Read the full methodology](docs/METHODOLOGY.md)

### 3. Personalization

During onboarding, users can set:
- **Weight**: For future dose calculations
- **Sensitivity Level**:
  - Low: Less sensitive to crashes (20% threshold)
  - Medium: Average sensitivity (30% threshold)
  - High: More sensitive to crashes (40% threshold)

### 4. Smart Notifications

- Proactive alerts 30 minutes before predicted crashes
- Customizable alert timing (15-60 minutes)
- Respects quiet hours and user preferences

## Usage

### First Launch

1. Complete the onboarding process
2. Enter your weight and select caffeine sensitivity
3. Grant notification permissions

### Logging Caffeine

1. Tap the "+" button on the dashboard
2. Follow the Q&A flow:
   - What did you drink?
   - Confirm caffeine amount
   - When did you have it?
3. Review and confirm

### Managing Settings

- **Edit Profile**: Adjust weight and sensitivity
- **Authentication**: Sign in to enable cloud sync
- **Notifications**: Customize alert preferences
- **Data Management**: Export or clear your data

## Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow Swift API Design Guidelines
- Maintain existing code style
- Add unit tests for new features
- Update documentation as needed

## Roadmap

### Version 1.1
- [ ] Apple Watch companion app
- [ ] Widgets for quick logging
- [ ] Sleep quality integration

### Version 1.2
- [ ] Machine learning for personalized predictions
- [ ] Social features for accountability
- [ ] Integration with health apps

### Version 2.0
- [ ] Android version
- [ ] Web dashboard
- [ ] Advanced analytics

## Privacy

Apex takes your privacy seriously:
- All data is stored locally on your device
- Authentication is optional
- No data is shared without explicit consent
- No tracking or analytics

## Pricing & Subscription

Apex uses a freemium model with the following tiers:

### Free Tier
- Basic caffeine tracking and crash prediction
- 7 days of history
- Standard notifications
- Core features for casual users

### Apex Pro ($4.99/month)
- ✅ Unlimited history tracking
- ✅ Custom notification settings
- ✅ Data export (CSV/JSON)
- ✅ Advanced crash prediction

### Apex Premium ($39.99/year - 33% savings)
- ✅ Everything in Pro
- ✅ Multiple user profiles
- ✅ Apple Watch companion app
- ✅ Home screen widgets
- ✅ Advanced analytics dashboard
- ✅ Priority support

## License

Copyright (c) 2025 Jigar Patel. All Rights Reserved.

This is proprietary software. No permission is granted to use, copy, modify, or distribute without explicit written permission from the copyright holder.

## Acknowledgments

- Caffeine metabolism research from peer-reviewed journals
- SwiftUI community for inspiration and solutions
- Beta testers for valuable feedback

## Support

- **Issues**: [GitHub Issues](https://github.com/jpatel98/Apex/issues)
- **Discussions**: [GitHub Discussions](https://github.com/jpatel98/Apex/discussions)
- **Email**: apex.support@example.com

## Author

**Jigar Patel**
- GitHub: [@jpatel98](https://github.com/jpatel98)
- LinkedIn: [Jigar Patel](https://linkedin.com/in/jpatel98)

---

<p align="center">
  Made with ☕ and ❤️ in San Francisco
</p>