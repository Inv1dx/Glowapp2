# Glow App

Glow App is an iPhone-first glow-up operating system for young people, especially roughly ages 18-28. The product is built around one daily question:

> What should I do today to look and feel better?

This repository is Stage 0 only. It freezes the MVP scope, architecture guardrails, coding standards, analytics contract, and product principles before feature development starts.

## Product Promise

Glow App should help users improve how they look and feel through simple, consistency-driven tracking and recommendations. The focus is practical daily behavior, not endless dashboards.

Core domains for the MVP:
- sleep
- movement
- nutrition
- hydration
- body composition trend signals
- skincare consistency
- grooming and routine consistency

The app is not a medical product. It must avoid diagnostic, treatment, disease, or pseudo-clinical language.

## MVP Summary

The MVP is intentionally narrow. It includes:
- onboarding, profile setup, and goal selection
- HealthKit read-only data ingestion
- a dashboard with daily metrics
- manual logging for nutrition, hydration, and routines
- a deterministic Glow Score placeholder engine
- a Daily Glow Plan
- an end-of-day recap
- progress tracking and photo check-ins
- a subscription paywall
- analytics, polish, and launch hardening

The MVP should be good at one thing: helping a user decide what to do today and stay consistent.

## What Glow App Is Not

Glow App is not:
- an Android product
- a social feed
- a community platform
- an AI skin diagnosis app
- a medical app
- a body scanning app
- a full nutrition database
- a full chat coach
- an enterprise platform
- a dumping ground for extra features outside the MVP

## Build Philosophy

This codebase should be built as:
- small
- testable
- shippable
- non-medical
- deterministic before AI
- incremental and compile-safe

The default question for implementation work is not "can we add this?" It is "does this make the MVP clearer, more useful, and easier to ship?"

## Glow Score Placeholder Rules

The Glow Score is part of the MVP, but the scoring formula is not finalized in Stage 0.

Current placeholder rules:
- likely score categories include sleep, movement, nutrition, hydration, routine consistency, and body composition trend signals
- scoring in the MVP must be deterministic and testable
- missing data must degrade gracefully rather than collapsing the whole score to zero
- final weights, thresholds, and category visibility require human product judgment

Until those decisions are made, the score is a product contract, not a finished formula.

## Architecture Direction

The intended architecture is deliberately small:
- one iPhone app target
- SwiftUI frontend
- MVVM-style feature separation
- repositories and services where appropriate
- protocol seams around future integrations
- folder-based modularity before any package or multi-target split

Later integrations such as HealthKit, Supabase, RevenueCat, analytics, and notifications are planned boundaries only in Stage 0. They are not implemented in this pass.

## Stage 0 Deliverables

This repository currently freezes five documents:
- [README.md](/Users/kassymkhanjuvarov/Documents/Glowapp2/README.md)
- [ARCHITECTURE.md](/Users/kassymkhanjuvarov/Documents/Glowapp2/docs/ARCHITECTURE.md)
- [MVP_SCOPE.md](/Users/kassymkhanjuvarov/Documents/Glowapp2/docs/MVP_SCOPE.md)
- [CODING_STANDARDS.md](/Users/kassymkhanjuvarov/Documents/Glowapp2/docs/CODING_STANDARDS.md)
- [ANALYTICS_EVENTS.md](/Users/kassymkhanjuvarov/Documents/Glowapp2/docs/ANALYTICS_EVENTS.md)

These documents are the contract for later implementation stages.

## Open Decisions

The following items remain intentionally undecided and require human product judgment:
- final Glow Score weights, thresholds, and category prominence
- exact onboarding goal taxonomy and profile field depth
- exact paywall entitlement boundary for MVP
- photo check-in privacy and retention policy
- final analytics provider and provider-specific reserved fields

Stage 0 is complete only when later implementation work can use these docs to stay inside the MVP instead of redefining it.
