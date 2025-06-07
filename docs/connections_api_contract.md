# Connections Management API Contract

## Base Information
- **Base URL**: `https://yourapp.com/api/v1`
- **API Version**: v1
- **Content-Type**: `application/json`
- **Authentication**: JWT Bearer Token

## Authentication

### Required Headers
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

### Get JWT Token
First authenticate with Google OAuth to get JWT token:

**Endpoint**: `POST /api/v1/auth/google`

**Request Body**:
```json
{
  "auth": {
    "id_token": "google_oauth_id_token"
  }
}
```

**Response**:
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "John Doe",
    "avatar_url": "https://example.com/avatar.jpg"
  }
}
```

## Connections API Endpoints

### 1. List All Connections
**Method**: `GET`  
**Endpoint**: `/api/v1/connections`  
**Authentication**: Required

**Response** (200 OK):
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "John Doe",
      "phone_number": "+1234567890",
      "relationship": "colleague",
      "created_at": "2023-12-01T10:00:00.000Z",
      "updated_at": "2023-12-01T10:00:00.000Z"
    },
    {
      "id": 2,
      "name": "Jane Smith",
      "phone_number": "+0987654321",
      "relationship": "friend",
      "created_at": "2023-12-02T10:00:00.000Z",
      "updated_at": "2023-12-02T10:00:00.000Z"
    }
  ]
}
```

### 2. Get Single Connection
**Method**: `GET`  
**Endpoint**: `/api/v1/connections/{id}`  
**Authentication**: Required

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "John Doe",
    "phone_number": "+1234567890",
    "relationship": "colleague",
    "created_at": "2023-12-01T10:00:00.000Z",
    "updated_at": "2023-12-01T10:00:00.000Z"
  }
}
```

### 3. Create New Connection
**Method**: `POST`  
**Endpoint**: `/api/v1/connections`  
**Authentication**: Required

**Request Body**:
```json
{
  "connection": {
    "name": "John Doe",
    "phone_number": "+1234567890",
    "relationship": "colleague"
  }
}
```

**Response** (201 Created):
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "John Doe",
    "phone_number": "+1234567890",
    "relationship": "colleague",
    "created_at": "2023-12-01T10:00:00.000Z",
    "updated_at": "2023-12-01T10:00:00.000Z"
  },
  "message": "Connection created successfully"
}
```

### 4. Update Connection
**Method**: `PUT` or `PATCH`  
**Endpoint**: `/api/v1/connections/{id}`  
**Authentication**: Required

**Request Body**:
```json
{
  "connection": {
    "name": "John Updated",
    "phone_number": "+1111111111",
    "relationship": "family"
  }
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "John Updated",
    "phone_number": "+1111111111",
    "relationship": "family",
    "created_at": "2023-12-01T10:00:00.000Z",
    "updated_at": "2023-12-01T11:00:00.000Z"
  },
  "message": "Connection updated successfully"
}
```

### 5. Delete Connection
**Method**: `DELETE`  
**Endpoint**: `/api/v1/connections/{id}`  
**Authentication**: Required

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Connection deleted successfully"
}
```

## Relationship Types
The API supports the following relationship types:
- `friend` - Personal friend
- `family` - Family member
- `colleague` - Work colleague  
- `partner` - Partner/Spouse
- `parent` - Parent
- `child` - Child
- `sibling` - Brother/Sister
- `romantic_interest` - Romantic interest

## Error Responses

### Authentication Errors
**Status**: `401 Unauthorized`
```json
{
  "error": "Missing authorization token"
}
```

```json
{
  "error": "Invalid token"
}
```

### Validation Errors
**Status**: `422 Unprocessable Entity`
```json
{
  "success": false,
  "errors": [
    "Name can't be blank",
    "Phone number can't be blank",
    "Relationship can't be blank"
  ]
}
```

### Not Found Errors
**Status**: `404 Not Found`
```json
{
  "success": false,
  "error": "Connection not found"
}
```

### Server Errors
**Status**: `500 Internal Server Error`
```json
{
  "error": "Authentication service unavailable"
}
```

## Data Models

### Connection Object
```json
{
  "id": "integer - Unique identifier",
  "name": "string - Connection's name (required, max 100 chars)",
  "phone_number": "string - Phone number (required, any format)",
  "relationship": "string - Type of relationship (required, see relationship types above)",
  "created_at": "datetime - ISO 8601 format",
  "updated_at": "datetime - ISO 8601 format"
}
```

### User Object (from auth)
```json
{
  "id": "integer - Unique identifier",
  "email": "string - User's email",
  "name": "string - User's name",
  "avatar_url": "string - Profile picture URL"
}
```

## Request/Response Examples

### cURL Examples

#### Get All Connections
```bash
curl -X GET "https://yourapp.com/api/v1/connections" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json"
```

#### Create Connection
```bash
curl -X POST "https://yourapp.com/api/v1/connections" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "connection": {
      "name": "John Doe",
      "phone_number": "+1234567890",
      "relationship": "colleague"
    }
  }'
```

#### Update Connection
```bash
curl -X PUT "https://yourapp.com/api/v1/connections/1" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "connection": {
      "name": "John Updated",
      "phone_number": "+1111111111",
      "relationship": "family"
    }
  }'
```

#### Delete Connection
```bash
curl -X DELETE "https://yourapp.com/api/v1/connections/1" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json"
```

## JavaScript/TypeScript Examples

### Using Fetch API

#### Authentication
```javascript
async function authenticateWithGoogle(idToken) {
  const response = await fetch('/api/v1/auth/google', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      auth: {
        id_token: idToken
      }
    })
  });
  
  const data = await response.json();
  return data.token; // Store this token for subsequent requests
}
```

#### Get All Connections
```javascript
async function getConnections(token) {
  const response = await fetch('/api/v1/connections', {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    }
  });
  
  const data = await response.json();
  return data.data; // Array of connections
}
```

#### Create Connection
```javascript
async function createConnection(token, connectionData) {
  const response = await fetch('/api/v1/connections', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      connection: connectionData
    })
  });
  
  const data = await response.json();
  return data.data; // Created connection object
}

// Usage
const newConnection = await createConnection(token, {
  name: "Alice Johnson",
  phone_number: "+1555123456",
  relationship: "colleague"
});
```

#### Update Connection
```javascript
async function updateConnection(token, connectionId, updates) {
  const response = await fetch(`/api/v1/connections/${connectionId}`, {
    method: 'PUT',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      connection: updates
    })
  });
  
  const data = await response.json();
  return data.data; // Updated connection object
}
```

#### Delete Connection
```javascript
async function deleteConnection(token, connectionId) {
  const response = await fetch(`/api/v1/connections/${connectionId}`, {
    method: 'DELETE',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    }
  });
  
  const data = await response.json();
  return data.success; // true if successful
}
```

### TypeScript Interfaces

```typescript
 interface Connection {
   id: number;
   name: string;
   phone_number: string;
   relationship: 'friend' | 'family' | 'colleague' | 'partner' | 'parent' | 'child' | 'sibling' | 'romantic_interest';
   created_at: string;
   updated_at: string;
 }

 interface ConnectionInput {
   name: string;
   phone_number: string;
   relationship: 'friend' | 'family' | 'colleague' | 'partner' | 'parent' | 'child' | 'sibling' | 'romantic_interest';
 }

interface ApiResponse<T> {
  success: boolean;
  data?: T;
  message?: string;
  errors?: string[];
  error?: string;
}

interface User {
  id: number;
  email: string;
  name: string;
  avatar_url: string;
}

interface AuthResponse {
  token: string;
  user: User;
}
```

## Security Features
- HTTPS only in production
- JWT tokens expire after 2 years
- CORS protection enabled
- Input sanitization applied
- SQL injection protection via ActiveRecord
- User data isolation (users can only access their own connections)

## Status Codes Summary
- `200` - OK (successful GET, PUT, DELETE)
- `201` - Created (successful POST)
- `401` - Unauthorized (missing/invalid token)
- `404` - Not Found (connection doesn't exist or belongs to another user)
- `422` - Unprocessable Entity (validation errors)
- `500` - Internal Server Error

## Integration Notes for AI Agents

1. **Authentication Flow**: Always authenticate with Google OAuth first to get JWT token
2. **Token Management**: Store JWT token securely, it's valid for 2 years
3. **Error Handling**: Check response status codes and handle errors appropriately
4. **Data Isolation**: Users can only access their own connections
5. **Input Validation**: Name, phone_number, and relationship are required fields
6. **Phone Format**: Any phone format accepted, system will strip/clean input
7. **Relationship Types**: Must be one of the predefined relationship types
8. **Pagination**: Not currently implemented, all connections returned in single request
9. **Filtering**: Not currently implemented, use client-side filtering if needed

## Testing Endpoint
Use the health check endpoint to verify API availability:
```
GET https://yourapp.com/up
```
Returns `200 OK` if service is healthy. 