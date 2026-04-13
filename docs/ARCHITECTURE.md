# Glow App Architecture

## Purpose

This document defines the Stage 0 architecture contract for Glow App. It exists to keep later implementation work small, understandable, and shippable.

This is not a scalability exercise. The MVP architecture should support fast iteration without letting UI, business rules, and integrations collapse into one layer.

## Chosen Stack

### SwiftUI

SwiftUI is the UI framework because Glow App is iPhone-first, interface-heavy, and should move quickly with a small codebase. It supports fast iteration, preview-driven UI work, and straightforward state-driven screens.

### HealthKit

HealthKit is the planned source for read-only health data ingestion. It is used because it is the native iPhone data source for metrics such as sleep, movement, and other relevant inputs. Stage 0 only documents the integration boundary. No HealthKit implementation is included here.

### Supabase

Supabase is the planned backend because it is a pragmatic fit for user data, sync, and future remote configuration without introducing large custom backend surface area early. Stage 0 only defines the future boundary. No backend code is included here.

### RevenueCat

RevenueCat is the planned subscription layer because it reduces custom purchase state complexity and keeps paywall logic focused on product behavior instead of store plumbing. Stage 0 only defines the future boundary. No subscription implementation is included here.

### Analytics Service

Analytics will be added later behind a thin service boundary. The purpose is product learning, funnel measurement, and launch hardening. The purpose is not exhaustive event spam.

### Local Notifications

Local notifications are planned for later to support reminders and consistency nudges. They are out of scope for Stage 0 and should remain behind a service boundary when implemented.

## Stage 0 Assumptions

- Glow App starts as a single iPhone app target.
- Folder-based modularity is enough for the MVP.
- Multi-package or multi-target extraction should happen only after repeated friction proves the need.
- Future integrations are documented as seams, not implemented systems.

## Architecture Principles

- Keep UI, business logic, and persistence separated.
- Prefer MVVM-style feature separation.
- Use repositories and services where they reduce coupling.
- One domain equals one feature area.
- Do not collapse networking, persistence, and UI into one file.
- Deterministic rules come before AI-generated or heuristic behavior.
- Make compile-safe incremental changes only.
- Keep the architecture MVP-sized. Do not introduce enterprise patterns without a concrete need.

## Layer Responsibilities

### Views

Views render state and forward user intent. They should:
- stay presentation-focused
- avoid direct SDK calls
- avoid owning business rules
- remain easy to preview and test through injected state

### ViewModels

View models own screen state, user intents, and flow orchestration. They should:
- translate user actions into domain operations
- expose view-friendly state
- depend on protocols or use-case style interfaces rather than concrete SDKs
- avoid platform integration details where possible

### Models And Rules

Models and rules define domain concepts and deterministic logic. They should:
- represent app data clearly
- hold pure rules such as Glow Score and Daily Glow Plan logic
- stay testable without UI dependencies

### Repositories

Repositories expose app-facing data interfaces. They should:
- combine local, platform, and remote sources when needed
- map raw service responses into domain models
- hide persistence and integration details from view models

### Services

Services wrap platform and third-party SDKs. They should:
- isolate HealthKit, analytics, notifications, Supabase, and RevenueCat details
- provide small interfaces with explicit responsibilities
- avoid becoming product logic containers

## Module Boundaries

Glow App should be organized by feature area, not by a generic dump of screens and helpers.

Primary MVP feature areas:
- Onboarding
- Dashboard
- Logging
- DailyPlan
- Recap
- Progress
- Paywall

Shared layers:
- App
- Core
- Domain
- Data
- Resources

Rules:
- features can depend on `Core`, `Domain`, and `Data` contracts
- features should not import each other's private internals
- shared code belongs in `Core` only when at least two feature areas need it
- business rules should live in `Domain`, not inside feature views

## Dependency And Layering Rules

- `Views` may depend on `ViewModels`, display models, and UI utilities
- `ViewModels` may depend on repository protocols, rule engines, and domain models
- `Repositories` may depend on services, storage, and mapping code
- `Services` may depend on Apple frameworks or third-party SDKs
- dependency direction should move inward toward simpler abstractions, not outward toward UI

Hard rules:
- views never call SDKs directly
- view models never import concrete analytics, purchase, or health SDK types unless there is no reasonable adapter
- repositories do not own screen state
- services do not own product flow
- no feature should require editing unrelated features to add a new screen

## Intended Folder Structure

This is the intended MVP project structure. It is a contract for later implementation, not a promise that every folder exists yet.

```text
GlowApp/
  App/
  Core/
  Features/
    Onboarding/
    Dashboard/
    Logging/
    DailyPlan/
    Recap/
    Progress/
    Paywall/
  Domain/
  Data/
  Resources/
GlowAppTests/
```

Suggested responsibility split:
- `App`: app entry point, app-wide environment assembly, navigation roots
- `Core`: shared primitives, reusable UI tokens, app-wide utilities that are actually shared
- `Features`: feature-specific views, view models, local feature models, and flows
- `Domain`: business models, rule engines, and use-case style logic
- `Data`: repositories, service adapters, persistence mapping, transport models
- `Resources`: assets, strings, static configuration
- `GlowAppTests`: unit tests for rules, view models, repositories, and mappings

## Glow Score Placeholder Contract

The Glow Score is part of the architecture because it will influence data flow and dashboard behavior. The formula is intentionally not finalized in Stage 0.

Current placeholder rules:
- likely categories are sleep, movement, nutrition, hydration, routine consistency, and body composition trend signals
- the MVP score must be deterministic and testable
- missing data must degrade gracefully rather than erase the entire score
- final weights, thresholds, and category visibility require human product judgment

Implementation rule:
- scoring logic should live in a dedicated rule or engine layer, not inside views and not inside analytics code

## Scaling Rule

Start folder-modular. Extract packages, targets, or deeper architecture only after repeated pain shows that the current structure is failing. Do not pre-emptively build enterprise scaffolding around an MVP product.

## Open Decisions

- exact onboarding profile fields
- exact goal taxonomy and default plans
- exact Glow Score weights and thresholds
- exact paywall entitlement boundary
- final persistence split between local storage and backend sync
- photo check-in privacy, retention, and export policy
