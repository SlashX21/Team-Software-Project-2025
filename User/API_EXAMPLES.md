# User Allergen API Examples

## Add User Allergen - POST /user/{userId}/allergens

### Case 1: Adding a new allergen (Success)

**Request:**
```bash
POST /user/1/allergens
Content-Type: application/json

{
  "allergenId": 5,
  "severityLevel": "moderate",
  "notes": "Causes digestive issues"
}
```

**Response:**
```json
{
  "code": 200,
  "message": "success!",
  "data": {
    "userAllergenId": 9,
    "allergenId": 5,
    "allergenName": "Soy",
    "category": "Legumes",
    "severityLevel": "moderate",
    "confirmed": true,
    "notes": "Causes digestive issues",
    "message": "User allergen added successfully",
    "isExisting": false
  }
}
```

### Case 2: Attempting to add existing allergen

**Request:**
```bash
POST /user/1/allergens
Content-Type: application/json

{
  "allergenId": 1,
  "severityLevel": "severe",
  "notes": "New notes"
}
```

**Response:**
```json
{
  "code": 200,
  "message": "success!",
  "data": {
    "userAllergenId": 1,
    "allergenId": 1,
    "allergenName": "Milk",
    "category": "Dairy",
    "severityLevel": "moderate",
    "confirmed": true,
    "notes": "Lactose intolerant, can have small amounts",
    "message": "User already has this allergen",
    "isExisting": true
  }
}
```

### Case 3: Invalid allergen ID

**Request:**
```bash
POST /user/1/allergens
Content-Type: application/json

{
  "allergenId": 999,
  "severityLevel": "moderate",
  "notes": "Test"
}
```

**Response:**
```json
{
  "code": 400,
  "message": "Invalid request: Allergen not found with id: 999",
  "data": null
}
```

## Frontend Handling Guide

The frontend can distinguish between new and existing allergens using the `isExisting` field:

```javascript
// Handle API response
if (response.data.isExisting) {
  // Show message: "You already have this allergen with severity level: {severityLevel}"
  // Optionally offer to update the existing allergen
  showExistingAllergenDialog(response.data);
} else {
  // Show success message: "Allergen added successfully"
  showSuccessMessage(response.data);
}
``` 