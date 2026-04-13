# Glow App Analytics Events

## Purpose

This document defines a lightweight analytics contract for the MVP. Analytics exists to measure user progress through the product, identify friction, and support launch decisions.

It does not exist to track every tap.

## Naming Convention

Use this format:

`feature_object_action`

Rules:
- use `snake_case`
- keep names short and literal
- prefer stable nouns and verbs
- avoid provider-specific naming in the event contract
- do not encode large amounts of state into event names

Examples:
- `onboarding_started`
- `goal_selected`
- `dashboard_viewed`
- `purchase_completed`

## Event Design Rules

- instrument meaningful decisions, completions, and drop-off points
- prefer a small number of high-signal events over large event volume
- keep properties low-cardinality where possible
- do not duplicate screen-view events across multiple layers
- do not emit vanity instrumentation for every small tap

## Property Rules

- include only properties that clarify context or funnel behavior
- use stable enums or IDs where possible
- avoid free-text properties unless there is a strong reason
- avoid storing raw health payloads, notes, or sensitive blobs in analytics
- keep error properties normalized, such as `error_code` or `result`

Recommended shared properties where relevant:
- `source`
- `step_name`
- `goal_id`
- `log_method`
- `routine_type`
- `plan_item_count`
- `product_id`
- `result`
- `error_code`

## First-Pass Event Inventory

### Onboarding

#### `onboarding_started`

Purpose: marks entry into the onboarding funnel.

Recommended properties:
- `source`

#### `onboarding_step_viewed`

Purpose: measures step progression and drop-off points.

Recommended properties:
- `step_name`
- `source`

#### `goal_selected`

Purpose: captures which user goal categories drive intent.

Recommended properties:
- `goal_id`

#### `onboarding_completed`

Purpose: marks successful completion of the onboarding flow.

Recommended properties:
- `selected_goal_count`
- `healthkit_connected`

### Dashboard

#### `dashboard_viewed`

Purpose: measures daily app entry and dashboard usage.

Recommended properties:
- `source`

#### `dashboard_card_tapped`

Purpose: shows which dashboard modules drive action.

Recommended properties:
- `card_id`
- `source`

### Health Connection

#### `healthkit_connect_tapped`

Purpose: measures intent to connect HealthKit.

Recommended properties:
- `source`

#### `healthkit_connect_completed`

Purpose: measures successful connection completion.

Recommended properties:
- `source`

#### `healthkit_connect_skipped`

Purpose: measures opt-out behavior in onboarding or settings.

Recommended properties:
- `source`

#### `healthkit_sync_completed`

Purpose: confirms a successful sync event at a useful product level.

Recommended properties:
- `source`
- `result`

### Nutrition Logging

#### `nutrition_log_started`

Purpose: measures entry into nutrition logging.

Recommended properties:
- `source`
- `log_method`

#### `nutrition_log_saved`

Purpose: measures successful nutrition logging completion.

Recommended properties:
- `source`
- `log_method`

### Hydration Logging

#### `hydration_log_started`

Purpose: measures entry into hydration logging.

Recommended properties:
- `source`
- `log_method`

#### `hydration_log_saved`

Purpose: measures successful hydration logging completion.

Recommended properties:
- `source`
- `log_method`

### Routine Completion

#### `routine_completed`

Purpose: tracks consistency on routine actions such as skincare or grooming flows.

Recommended properties:
- `routine_type`
- `source`

### Score, Plan, And Recap

#### `glow_score_viewed`

Purpose: measures whether users open the score surface.

Recommended properties:
- `source`

#### `daily_plan_viewed`

Purpose: measures plan consumption and dashboard-to-plan movement.

Recommended properties:
- `source`
- `plan_item_count`

#### `recap_viewed`

Purpose: measures end-of-day recap usage.

Recommended properties:
- `source`

### Paywall, Purchase, And Restore

#### `paywall_viewed`

Purpose: measures paywall exposure and paywall entry points.

Recommended properties:
- `source`

#### `purchase_started`

Purpose: marks entry into the purchase flow.

Recommended properties:
- `product_id`
- `source`

#### `purchase_completed`

Purpose: confirms a successful purchase.

Recommended properties:
- `product_id`
- `source`

#### `purchase_failed`

Purpose: measures purchase failures without storing noisy raw error blobs.

Recommended properties:
- `product_id`
- `source`
- `error_code`

#### `restore_started`

Purpose: measures user intent to restore access.

Recommended properties:
- `source`

#### `restore_completed`

Purpose: confirms successful restore flow completion.

Recommended properties:
- `source`
- `result`

#### `restore_failed`

Purpose: measures restore failures in a normalized way.

Recommended properties:
- `source`
- `error_code`

## Explicit Non-Goals For Analytics

Do not:
- send raw HealthKit payloads
- send free-text blobs from users
- duplicate the same screen-view event from multiple layers
- track vanity tap spam
- introduce analytics-specific branching into core product rules

The MVP analytics plan should stay small, actionable, and easy to reason about.
