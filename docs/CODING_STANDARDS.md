# Glow App Coding Standards

## Purpose

This document defines the coding standards for Glow App. The goal is not stylistic perfection. The goal is preventing a messy MVP codebase.

## Core Rules

- keep UI, business logic, and persistence separated
- prefer MVVM-style feature separation
- use repositories and services where they reduce coupling
- one domain equals one feature area
- deterministic rules before AI
- compile-safe incremental changes only

## Naming Conventions

### Types

- use `XView` for SwiftUI screens and reusable UI surfaces
- use `XViewModel` for presentation state and user intent handling
- use `XRepository` for app-facing data access layers
- use `XService` for SDK or platform wrappers
- use `XEngine` for deterministic rule systems such as scoring or planning
- use `XModel` only when the suffix adds clarity

### General Naming

- use `UpperCamelCase` for type names
- use `lowerCamelCase` for properties, functions, and enum cases
- use `snake_case` only for analytics event strings and wire-level keys when required
- prefer singular type names unless the collection itself is the real concept
- avoid vague names such as `DataManager`, `Helper`, `Utils`, `Common`, or `Stuff`

## File Size And Responsibility Guardrails

- one primary type per file
- split views and view models before they exceed about 200 lines
- split repositories and services before they become multi-feature containers
- avoid files that mix UI, persistence, networking, and business rules
- avoid catch-all files such as `Utils.swift`, `Helpers.swift`, or `Manager.swift`

If a file keeps growing, the answer is usually better boundaries, not more comments.

## Layer Standards

### Models

- keep models simple, explicit, and testable
- avoid UI framework imports in domain models
- avoid third-party SDK imports in domain models unless there is no reasonable adapter
- prefer value types for pure data unless reference semantics are required

### Services

- services wrap Apple frameworks or third-party SDKs
- services should not own screen flow or product decisions
- services should expose small, explicit interfaces
- services should not become general-purpose application coordinators

### Repositories

- repositories map services or storage into app-facing data
- repositories should hide integration details from view models
- repositories should return domain-shaped data, not raw SDK payloads
- repositories should stay scoped to a clear feature or domain

### ViewModels

- view models own presentation state, user intents, and async orchestration
- view models should not call third-party SDKs directly
- view models should not contain large formatting layers that belong in views
- view models should not embed heavy business logic that belongs in rule engines or repositories

### Views

- views compose UI from state
- keep formatting logic minimal and local
- do not place networking, persistence, analytics, or scoring logic in views
- prefer small dedicated subviews over one giant screen file

### Tests

- prioritize tests for Glow Score rules
- prioritize tests for Daily Glow Plan rules
- prioritize tests for repository mapping and fallback behavior
- prioritize tests for view model state transitions
- do not over-invest early in snapshot coverage if rule logic is untested

## Comments Policy

- use comments to explain why something exists, what invariant matters, or what tradeoff is being preserved
- do not comment obvious code line by line
- use `TODO` only for explicit open decisions or intentionally deferred work
- if a code block needs several comments to be understandable, consider refactoring it instead

## Error Handling

- do not silently swallow errors except for non-blocking analytics failures
- convert low-level errors into app-safe states before they reach the UI
- keep user-facing error copy calm, direct, and non-medical
- log or surface enough context for debugging without leaking raw personal data
- design fallback behavior for missing or partial data instead of crashing or returning nonsense

## Do Not Do This

- do not create singleton god objects
- do not mix UI, networking, persistence, and business logic in one file
- do not introduce speculative abstractions for future scale
- do not call third-party SDKs directly from views
- do not bury product rules inside analytics or service layers
- do not ship AI-derived core logic before deterministic rules exist
- do not create cross-feature dependencies when a shared contract would do
- do not keep adding flags and optionals when the model structure should be redesigned
- do not let TODOs become an informal backlog for unrelated ideas

## PR And Change Expectations

- every change should compile cleanly before it is merged
- every change should stay inside the current stage scope
- every change should preserve or improve testability
- every new file should have a clear reason to exist
- if a change increases complexity, the justification should be concrete
