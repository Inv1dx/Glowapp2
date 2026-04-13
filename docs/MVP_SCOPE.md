# Glow App MVP Scope

## Purpose

This document freezes the Glow App MVP before feature development starts. It defines what will be built, what will not be built, and the order in which work should happen.

The MVP is focused. It is not a broad health platform.

## Product Goal

Glow App should help a user answer one daily question:

> What should I do today to look and feel better?

That means the MVP should prioritize clear action, consistency, and explainable behavior over feature count.

## Frozen MVP Priority Order

The MVP priority order is fixed for Stage 0:

1. onboarding + profile + goal selection
2. HealthKit integration and read-only data ingestion
3. dashboard with daily metrics
4. manual logging for nutrition, hydration, and routines
5. Glow Score engine
6. Daily Glow Plan
7. end-of-day recap
8. progress tracking and photo check-ins
9. subscription paywall
10. analytics, polish, and launch hardening

This order should guide implementation sequencing, resourcing, and scope tradeoffs.

## In-Scope MVP Features

### Onboarding, Profile, And Goals

The app should onboard a user, capture a lightweight profile, and let them select goals relevant to looking and feeling better. The onboarding should stay short and action-oriented.

### HealthKit Read-Only Ingestion

The app should support read-only ingestion of relevant HealthKit data later. It should never frame itself as a medical interpretation layer.

### Dashboard

The dashboard should show today's relevant metrics, progress, and next useful actions. It should not become a data wall.

### Manual Logging

The user should be able to log nutrition, hydration, and routine completion simply. Logging should be lightweight and consistency-oriented, not database-heavy.

### Glow Score

The app should provide a deterministic Glow Score placeholder that summarizes current consistency and relevant inputs without pretending to be a finished scientific formula.

### Daily Glow Plan

The app should translate available data into a short, explainable plan for today. The plan should recommend concrete actions, not generic motivation.

### End-Of-Day Recap

The app should close the day with a recap focused on consistency, completion, and tomorrow-facing feedback.

### Progress And Photo Check-Ins

The app should support progress tracking and photo check-ins in a lightweight way. This is for consistency and visible progress, not body scanning or diagnosis.

### Paywall

The MVP includes a subscription paywall. Exact entitlement boundaries remain an open product decision.

### Analytics, Polish, And Launch Hardening

Analytics should measure meaningful product behavior. Polish and hardening belong at the end of the MVP sequence, not at the expense of core product usefulness.

## Explicit V1 Non-Goals

V1 does not include:
- Android
- a social feed
- community features
- AI skin diagnosis
- medical claims
- body scanning
- a complicated nutrition database
- a full chat coach
- enterprise architecture
- feature creep outside the MVP

Additional non-goals for clarity:
- no diagnostic skincare workflow
- no treatment recommendations
- no calorie obsession product direction
- no creator marketplace
- no messaging layer
- no wearables platform strategy beyond scoped HealthKit ingestion

## Product And UX Principles

- simple over clever
- action-oriented over dashboard-heavy
- outcome-focused over data overload
- direct, clean, non-medical language
- daily usefulness over feature count
- explainability over fake intelligence

These are product constraints, not design slogans.

## High-Level MVP User Flows

### First Launch

onboarding -> goals -> optional HealthKit connect -> dashboard

### Daily Use

dashboard -> log actions -> view Glow Score + Daily Glow Plan

### End Of Day

recap -> consistency feedback

### Progress

trends + photo check-ins

### Monetization

paywall -> purchase -> restore

## Implementation Stage Sequencing

Later implementation stages should follow this sequence:

1. Build onboarding, profile capture, and goal selection.
2. Add HealthKit read-only ingestion behind a service boundary.
3. Build the dashboard around today's metrics and action prompts.
4. Add manual logging for nutrition, hydration, and routines.
5. Add the deterministic Glow Score engine.
6. Add the Daily Glow Plan.
7. Add the end-of-day recap flow.
8. Add progress tracking and photo check-ins.
9. Add the subscription paywall.
10. Add analytics, polish, and launch hardening.

Do not reorder this sequence casually. The order is intended to protect MVP focus.

## Glow Score Placeholder Rules

The Glow Score formula is not finalized in Stage 0.

Current placeholder rules:
- likely categories are sleep, movement, nutrition, hydration, routine consistency, and body composition trend signals
- the MVP score must be deterministic and testable
- missing data must degrade gracefully rather than zeroing the whole score
- final weights, thresholds, and category visibility require human product judgment

## Open Decisions

- exact onboarding goal taxonomy
- exact profile field depth
- exact Glow Score weights and thresholds
- exact entitlement split for free versus paid MVP functionality
- exact photo check-in privacy and retention rules
- exact scope of body composition trend handling in the dashboard and progress views
