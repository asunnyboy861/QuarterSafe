# Git Repositories

## Main App (iOS Application)

| Item | Value |
|------|-------|
| **Repository Name** | QuarterSafe |
| **Git URL** | git@github.com:asunnyboy861/QuarterSafe.git |
| **Repo URL** | https://github.com/asunnyboy861/QuarterSafe |
| **Visibility** | Public |
| **Primary Language** | Swift |
| **GitHub Pages** | ✅ **ENABLED** (from `/docs` folder) |

## Policy Pages (Deployed from Main Repository /docs)

| Page | URL | Status |
|------|-----|--------|
| Landing Page | https://asunnyboy861.github.io/QuarterSafe/ | ✅ Active |
| Support | https://asunnyboy861.github.io/QuarterSafe/support.html | ✅ Active |
| Privacy Policy | https://asunnyboy861.github.io/QuarterSafe/privacy.html | ✅ Active |

## Repository Structure

```
QuarterSafe/
├── Quarterly Tax.xcodeproj/       # Xcode Project (app + widget + tests targets)
├── Quarterly Tax/                 # App Source (synchronized groups)
│   ├── QuarterSafeApp.swift       # Entry, deep-link routing
│   ├── SharedTypes.swift
│   ├── Config/TaxYearConfig.swift
│   ├── Resources/                 # TaxYearConfig-2026.json, states-2026.json
│   ├── Engines/                   # DeadlineEngine, TaxEngine, JarEngine, ProofEngine
│   ├── Models/AppModels.swift     # IncomeEvent, ExpenseEvent, Payment, Profile (SwiftData)
│   ├── ViewModels/AppStore.swift  # Event-sourcing recompute
│   ├── Views/                     # Onboarding, Home, Calendar, Payments, Vault, Settings, Paywall, ContactSupport
│   ├── Notifications/ReminderScheduler.swift
│   ├── Store/PurchaseManager.swift
│   └── Assets.xcassets/           # AppIcon (Agnes generated)
├── QuarterlySafeWidget/           # Lock Screen + Home widget extension
├── Quarterly TaxTests/            # 22 engine unit tests (Swift Testing)
├── Quarterly TaxUITests/
└── .gitignore                     # excludes .env, keytext*.md, COMPETITOR_REPORT.md, xcuserdata
```

## Build Verification

- iPhone 16 (iOS 26.4) build + run: ✅
- iPad Pro 13-inch (M5) build + run: ✅
- Engine unit tests: 22/22 passed (DeadlineEngine 2026 Q2 business-day rule, holiday shifting, Safe Harbor rules, small-balance exemption, carryforward)
