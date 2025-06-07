# User Preferences API

## Overview
The User Preferences API allows authenticated users to retrieve and update their notification preferences, including notification time and timezone settings.

## Authentication
All endpoints require JWT authentication via the `Authorization` header:
```
Authorization: Bearer <jwt_token>
```

## Endpoints

### GET /api/v1/user_preferences
Retrieve the current user's preferences.

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "notification_time": "14:30",
    "timezone": "Asia/Kolkata",
    "created_at": "2025-06-07T09:05:04.123Z",
    "updated_at": "2025-06-07T09:05:04.123Z"
  }
}
```

**Response (404 Not Found):**
```json
{
  "success": false,
  "error": "User preferences not found"
}
```

### PUT/PATCH /api/v1/user_preferences
Update the current user's preferences. Only `notification_time` and `timezone` can be updated.

**Request Body:**
```json
{
  "user_preference": {
    "notification_time": "09:00",
    "timezone": "America/New_York"
  }
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "notification_time": "09:00",
    "timezone": "America/New_York",
    "created_at": "2025-06-07T09:05:04.123Z",
    "updated_at": "2025-06-07T09:15:30.456Z"
  },
  "message": "User preferences updated successfully"
}
```

**Response (422 Unprocessable Entity):**
```json
{
  "success": false,
  "errors": [
    "Notification time can't be blank",
    "Timezone can't be blank"
  ]
}
```

**Response (404 Not Found):**
```json
{
  "success": false,
  "error": "User preferences not found"
}
```

## Field Specifications

### notification_time
- **Type:** TIME (HH:MM format)
- **Required:** Yes
- **Example:** "14:30"
- **Description:** The time when the user wants to receive notifications (24-hour format)

### timezone
- **Type:** STRING (max 50 characters)
- **Required:** Yes
- **Examples:** "Asia/Kolkata", "America/New_York", "Europe/London", "UTC"
- **Description:** The user's timezone for notification scheduling

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

### 404 Not Found
```json
{
  "success": false,
  "error": "User preferences not found"
}
```

### 422 Unprocessable Entity
```json
{
  "success": false,
  "errors": ["Validation error messages"]
}
```

## Notes
- Each user can have only one set of preferences
- The timezone field accepts any non-blank string (format is not validated)
- Partial updates are supported (you can update only notification_time or only timezone)
- The notification_time is stored and returned in 24-hour format (HH:MM) 