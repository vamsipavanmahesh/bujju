# Onboarding API

## Overview
The Onboarding API allows authenticated users to retrieve their onboarding settings. This is a read-only API that automatically creates an onboarding record if one doesn't exist.

## Authentication
All endpoints require JWT authentication via the `Authorization` header:
```
Authorization: Bearer <jwt_token>
```

## Endpoints

### GET /api/v1/onboarding
Retrieve the current user's onboarding settings. If no onboarding record exists, it will be automatically created.

**Response (200 OK - Existing Record):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "notification_time_setting": "2025-06-07T15:30:00.000Z",
    "created_at": "2025-06-07T09:05:04.123Z",
    "updated_at": "2025-06-07T09:05:04.123Z"
  }
}
```

**Response (200 OK - Auto-Created Record):**
When no onboarding record exists, the API automatically creates a new one and returns it:
```json
{
  "success": true,
  "data": {
    "id": 2,
    "notification_time_setting": null,
    "created_at": "2025-06-07T10:15:30.456Z",
    "updated_at": "2025-06-07T10:15:30.456Z"
  }
}
```
*Note: The `created_at` and `updated_at` timestamps will be identical for newly created records, and `notification_time_setting` will be `null` by default.*

## Field Specifications

### notification_time_setting
- **Type:** DATETIME (ISO 8601 format)
- **Example:** "2025-06-07T15:30:00.000Z" or `null`
- **Description:** The specific datetime when the user wants to receive onboarding notifications
- **Format:** ISO 8601 datetime string in UTC
- **Nullable:** Yes - will be `null` for newly created records

## Error Responses

### 401 Unauthorized
```json
{
  "error": "Missing authorization token"
}
```
or
```json
{
  "error": "Invalid token"
}
```

## Auto-Creation Behavior
The onboarding resource has special auto-creation behavior:
- If a user doesn't have an onboarding record, the GET endpoint will automatically create one
- This ensures every user always has onboarding settings available
- New records are created with `notification_time_setting` set to `null`

## Usage Examples

### Retrieving onboarding settings
```bash
curl -X GET \
  https://api.example.com/api/v1/onboarding \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN'
```

## Notes
- Each user can have only one onboarding record (enforced by unique database constraint)
- The notification_time_setting is stored as a datetime and serialized in ISO 8601 format
- This is a read-only API - onboarding settings cannot be updated via the API
- Auto-creation ensures the API is always available for GET operations
- The onboarding record is automatically deleted when the associated user is deleted 