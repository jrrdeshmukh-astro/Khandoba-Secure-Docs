# 🏗️ System Architecture

> Cross-platform architecture documentation for Khandoba Secure Docs

---

## 📚 Documentation Index

### Core Architecture
- **[Complete System Architecture](COMPLETE_SYSTEM_ARCHITECTURE.md)** ⭐⭐⭐ - Full system design
- **[Contact Grid Architecture](CONTACT_GRID_ARCHITECTURE.md)** - Contact management system

---

## 🎯 Architecture Overview

Khandoba Secure Docs uses a **shared backend, native frontend** architecture:

```
┌─────────────────────────────────────────────────────┐
│           Supabase Backend (Shared)                 │
│  • PostgreSQL Database                              │
│  • Real-time Subscriptions                          │
│  • Object Storage                                   │
│  • Authentication (OAuth)                           │
│  • Row-Level Security (RLS)                         │
└─────────────────────────────────────────────────────┘
            ↓              ↓              ↓
    ┌───────────┐   ┌───────────┐   ┌───────────┐
    │    iOS    │   │  Android  │   │  Windows  │
    │  SwiftUI  │   │  Compose  │   │  WinUI 3  │
    └───────────┘   └───────────┘   └───────────┘
```

### Architecture Layers

1. **Presentation Layer** - Native UI (SwiftUI/Compose/WinUI)
2. **Business Logic Layer** - Services (platform-specific)
3. **Data Access Layer** - Repositories (Supabase + local DB)
4. **Storage Layer** - Supabase + local persistence

---

## 🔄 Data Flow

### Document Upload Flow
```
User Action → View → ViewModel → Service → Repository → Supabase
                                                      ↓
                                              Local Cache (SwiftData/Room)
```

### Real-time Sync Flow
```
Supabase Change → Real-time Subscription → Repository → Service → ViewModel → View Update
```

---

## 🏛️ Design Patterns

- **MVVM** - Model-View-ViewModel
- **Repository Pattern** - Data access abstraction
- **Service Layer** - Business logic encapsulation
- **Dependency Injection** - Loose coupling

---

## 📖 Read More

- **[Complete System Architecture](COMPLETE_SYSTEM_ARCHITECTURE.md)** - Detailed architecture documentation
