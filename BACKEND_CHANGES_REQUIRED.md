# Backend Changes Required for Active Flow Implementation

This document outlines the changes made to the iOS SDK that require corresponding backend updates.

## Overview

The SDK has been updated to remove the `appId` requirement. The backend should now extract the `appId` from the API key instead of requiring it as a URL parameter.

## Key Changes

### 1. Removed `appId` from SDK Configuration

**SDK Change:**
- `FlwKit.configure()` now only requires `apiKey` (removed `appId` parameter)
- The backend must extract `appId` from the API key for all requests

**Backend Requirement:**
- API key authentication must resolve to an `appId`
- All endpoints should use the `appId` from the authenticated API key, not from URL parameters

---

## API Endpoint Changes

### 1. Get Active Flow

**Old Endpoint:**
```
GET /sdk/v1/apps/:appId/flow
```

**New Endpoint:**
```
GET /sdk/v1/flow
```

**Changes:**
- Remove `:appId` from URL path
- Extract `appId` from API key (`X-API-Key` header)
- Return the active flow for the app associated with the API key

**Request Headers:**
```
X-API-Key: <api-key>
```

**Response:** (No change)
```json
{
  "schemaVersion": 1,
  "flowKey": "onboarding-flow",
  "version": 3,
  "entryScreenId": "screen_welcome",
  "defaultThemeId": "theme_mint_dark",
  "themes": [...],
  "screens": [...]
}
```

**Error Responses:**
- `404 Not Found`: No active flow found for the app (extracted from API key)
- `404 Not Found`: Active flow has no published version
- `401 Unauthorized`: Invalid or missing API key
- `403 Forbidden`: API key doesn't have access to this app

---

### 2. Get A/B Test Variant

**Old Endpoint:**
```
GET /sdk/v1/apps/:appId/ab-tests/:flowKey
```

**New Endpoint:**
```
GET /sdk/v1/ab-tests/:flowKey
```

**Changes:**
- Remove `:appId` from URL path
- Extract `appId` from API key (`X-API-Key` header)
- Verify that the `flowKey` belongs to the app associated with the API key

**Request Headers:**
```
X-API-Key: <api-key>
```

**Query Parameters:** (No change)
- `userId` (optional): User identifier
- `sessionId` (optional): Session identifier

**Response:** (No change)
```json
{
  "hasActiveTest": true,
  "experimentId": "experiment_id",
  "testName": "Onboarding Experiment",
  "variant": {
    "id": "variant_1",
    "name": "Variant A",
    "flowVersionId": "version_id"
  },
  "flowVersionId": "version_id",
  "flowData": {
    "schemaVersion": 1,
    "flowKey": "onboarding-flow",
    "version": 2,
    "entryScreenId": "screen_123",
    "themes": [...],
    "screens": [...]
  }
}
```

**Error Responses:**
- `404 Not Found`: No active test for this flow
- `404 Not Found`: Flow not found or doesn't belong to the app
- `401 Unauthorized`: Invalid or missing API key
- `403 Forbidden`: API key doesn't have access to this app/flow

---

### 3. Get Theme (No Change)

**Endpoint:**
```
GET /sdk/v1/themes/:themeId
```

**Note:** This endpoint already doesn't use `appId` in the URL, but should verify:
- Theme belongs to the app associated with the API key
- API key has access to the theme

---

### 4. Track Analytics Event (No Change)

**Endpoint:**
```
POST /sdk/v1/events
```

**Note:** This endpoint already doesn't use `appId` in the URL, but should:
- Extract `appId` from API key
- Associate the event with the correct app
- Verify API key has permission to track events for the app

---

## Backend Implementation Requirements

### 1. API Key Authentication

**Requirement:**
- All endpoints must extract `appId` from the API key
- API key should be validated and mapped to an `appId`
- Invalid API keys should return `401 Unauthorized`

**Implementation Pattern:**
```typescript
// Middleware/Handler pattern
async function authenticateApiKey(apiKey: string): Promise<AppId> {
  // Lookup API key in database
  const apiKeyRecord = await ApiKey.findOne({ key: apiKey, isActive: true });
  
  if (!apiKeyRecord) {
    throw new UnauthorizedError('Invalid API key');
  }
  
  // Return the appId associated with this API key
  return apiKeyRecord.appId;
}

// Usage in endpoint handlers
app.get('/sdk/v1/flow', async (req, res) => {
  const apiKey = req.headers['x-api-key'];
  if (!apiKey) {
    return res.status(401).json({ error: 'Missing API key' });
  }
  
  const appId = await authenticateApiKey(apiKey);
  
  // Now use appId to fetch active flow
  const activeFlow = await getActiveFlow(appId);
  // ...
});
```

### 2. Flow Ownership Verification

**Requirement:**
- When fetching flows by `flowKey`, verify the flow belongs to the app
- When fetching A/B tests, verify the flow belongs to the app
- Return `404` if flow doesn't exist or doesn't belong to the app

**Implementation Pattern:**
```typescript
async function getFlowByKey(flowKey: string, appId: string): Promise<Flow> {
  const flow = await Flow.findOne({ flowKey, appId });
  
  if (!flow) {
    throw new NotFoundError('Flow not found');
  }
  
  return flow;
}
```

### 3. Active Flow Logic

**Requirement:**
- Endpoint `/sdk/v1/flow` should return the flow with `isActive: true` for the app
- Only one flow per app can be active at a time
- Active flow must have a published version

**Implementation Pattern:**
```typescript
async function getActiveFlow(appId: string): Promise<FlowPayloadV1> {
  // Find active flow for the app
  const flow = await Flow.findOne({ 
    appId, 
    isActive: true 
  });
  
  if (!flow) {
    throw new NotFoundError('No active flow found for this app');
  }
  
  // Get published version
  const version = await FlowVersion.findOne({
    flowId: flow._id,
    isPublished: true
  });
  
  if (!version) {
    throw new NotFoundError('Active flow has no published version');
  }
  
  // Resolve assets and return FlowPayloadV1
  return await buildFlowPayload(flow, version);
}
```

---

## Migration Guide

### For Existing Endpoints

**Step 1: Update Route Definitions**

**Before:**
```typescript
app.get('/sdk/v1/apps/:appId/flow', handler);
app.get('/sdk/v1/apps/:appId/ab-tests/:flowKey', handler);
```

**After:**
```typescript
app.get('/sdk/v1/flow', handler);
app.get('/sdk/v1/ab-tests/:flowKey', handler);
```

**Step 2: Add API Key Authentication Middleware**

```typescript
async function authenticateApiKey(req, res, next) {
  const apiKey = req.headers['x-api-key'];
  
  if (!apiKey) {
    return res.status(401).json({ error: 'Missing API key' });
  }
  
  try {
    const appId = await getAppIdFromApiKey(apiKey);
    req.appId = appId; // Attach to request for use in handlers
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid API key' });
  }
}

// Apply middleware
app.get('/sdk/v1/flow', authenticateApiKey, getActiveFlowHandler);
app.get('/sdk/v1/ab-tests/:flowKey', authenticateApiKey, getABTestHandler);
```

**Step 3: Update Handlers**

**Before:**
```typescript
async function getActiveFlowHandler(req, res) {
  const { appId } = req.params; // From URL
  const flow = await getActiveFlow(appId);
  res.json(flow);
}
```

**After:**
```typescript
async function getActiveFlowHandler(req, res) {
  const appId = req.appId; // From authenticated API key
  const flow = await getActiveFlow(appId);
  res.json(flow);
}
```

---

## Testing Checklist

### API Key Authentication
- [ ] Valid API key extracts correct `appId`
- [ ] Invalid API key returns `401 Unauthorized`
- [ ] Missing API key returns `401 Unauthorized`
- [ ] Inactive API key returns `401 Unauthorized`

### Active Flow Endpoint
- [ ] `/sdk/v1/flow` returns active flow for the app
- [ ] Returns `404` when no active flow exists
- [ ] Returns `404` when active flow has no published version
- [ ] Verifies flow belongs to the app from API key

### A/B Test Endpoint
- [ ] `/sdk/v1/ab-tests/:flowKey` works without `appId` in URL
- [ ] Verifies flow belongs to the app from API key
- [ ] Returns `404` when flow doesn't belong to app
- [ ] Returns correct variant assignment

### Flow Ownership
- [ ] Cannot access flows from other apps
- [ ] Returns `404` for flows that don't belong to the app
- [ ] A/B tests only return variants for flows belonging to the app

### Backward Compatibility
- [ ] Old endpoints with `appId` in URL can be deprecated (optional)
- [ ] Consider keeping old endpoints temporarily with deprecation warnings
- [ ] Document migration path for any SDKs still using old endpoints

---

## Security Considerations

### 1. API Key Validation
- Always validate API key before processing requests
- Check API key is active and not revoked
- Rate limit based on API key if needed

### 2. Flow Access Control
- Verify flow ownership before returning flow data
- Don't leak information about flows from other apps
- Return generic `404` errors (don't reveal if flow exists but belongs to another app)

### 3. A/B Test Access Control
- Verify flow ownership before returning A/B test data
- Ensure experiments belong to the correct app
- Don't expose experiment data for other apps

---

## Summary

### Endpoints Changed

1. **`GET /sdk/v1/apps/:appId/flow`** → **`GET /sdk/v1/flow`**
   - Remove `:appId` from URL
   - Extract `appId` from API key

2. **`GET /sdk/v1/apps/:appId/ab-tests/:flowKey`** → **`GET /sdk/v1/ab-tests/:flowKey`**
   - Remove `:appId` from URL
   - Extract `appId` from API key
   - Verify flow ownership

### Endpoints Unchanged (but should verify appId from API key)

3. **`GET /sdk/v1/themes/:themeId`** - Verify theme belongs to app
4. **`POST /sdk/v1/events`** - Associate events with correct app

### Key Implementation Points

- **API Key → AppId Mapping**: All endpoints must extract `appId` from API key
- **Flow Ownership Verification**: Verify flows belong to the app before returning
- **Active Flow Logic**: Return flow with `isActive: true` for the app
- **Error Handling**: Return appropriate errors (401 for auth, 404 for not found)

The SDK now only requires the API key, and the backend handles all app identification internally.
