# FlwKit iOS SDK Documentation

## Overview
FlwKit iOS SDK is a SwiftUI-first package that renders remote onboarding and funnel flows natively.

---

## Package Structure

FlwKit
- Core (models, schema, state)
- Networking (API client, cache)
- UI (FlowView, ScreenView, ComponentRenderers)
- Analytics (event queue & sender)

---

## Public API

FlwKit.configure(appId, apiKey, userId?)
FlwKit.present(flowKey, attributes, onComplete)

SwiftUI:
FlwKitFlowView(flowKey, attributes, onComplete)

---

## Rendering Rules

- Vertical single-column layout
- Deterministic rendering from schema
- SDK-controlled spacing and typography
- Safe fallback for unknown components

---

## State Management

- FlowState holds current screen, answers, attributes
- Persisted to UserDefaults
- Automatically restored on interruption

---

## Components (V1)

- text
- image
- button
- single_choice
- multi_choice
- text_input
- slider
- spacer

---

## Analytics Events

- flow_start
- screen_view
- answer
- flow_complete
- flow_exit

---

## Error Handling

- Cached flow used on network failure
- Invalid schema fails gracefully
- Errors logged internally

---

## Design Philosophy

Opinionated, predictable, native-first.
