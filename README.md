# my_sms

This is a simple flutter app that sends and receives SMS using local computer as server
The app currently only works on Windows and Linux
The computer needs to have a working internet connection and a phone connected to the computer

## API Endpoints

### POST /sms

Send SMS to the given phone number

- body:
  - phone_number: string
  - message: string

### GET /sms

Get all received SMS

- query:
  - phone_number: string

### GET /sms/:id

Get the SMS with the given ID

- path:
  - id: string

### DELETE /sms/:id


Here is the documentation based on the provided JSON:

---

# REST API Documentation for SMS Gateway: Flutter

This documentation provides an overview of the REST API endpoints for the SMS Gateway application, including the purpose of each endpoint, request methods, sample payloads, and response expectations.

---

## Overview

### Base URL
**`{{base_url}}`**  
Example: `https://postman-rest-api-learner.glitch.me/`

---

## Endpoints

### 1. **Get SMS**

#### **Description**
Retrieve SMS data from the server. This endpoint performs a `GET` request and does not require a request body.

#### **Request**
- **Method:** `GET`
- **URL:** `{{base_url}}/sms`

#### **Tests**
- Checks if the status code is `200 OK`.

#### **Sample Test Code**
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});
```

---

### 2. **Send SMS**

#### **Description**
Send an SMS by submitting a JSON payload in the request body. This endpoint performs a `POST` request.

#### **Request**
- **Method:** `POST`
- **URL:** `{{base_url}}/sms`
- **Headers:** None
- **Body:**
  ```json
  {
      "number": "+1234567890",
      "message": "Hello, this is a test message!"
  }
  ```

#### **Response**
A successful POST request typically returns:
- **Status Codes:** `200 OK` or `201 Created`.

#### **Tests**
- Validates that the response code is one of `[200, 201]`.

#### **Sample Test Code**
```javascript
pm.test("Successful POST request", function () {
    pm.expect(pm.response.code).to.be.oneOf([200, 201]);
});
```

---

### 3. **Delete SMS**

#### **Description**
Delete an SMS record by specifying its identifier in the URL. This endpoint performs a `DELETE` request.

#### **Request**
- **Method:** `DELETE`
- **URL:** `{{base_url}}/sms/2`  
  *(Replace `2` with the actual ID of the SMS to delete)*
- **Headers:** None
- **Body:** Empty

#### **Response**
A successful DELETE request typically returns:
- **Status Codes:** `200 OK`, `202 Accepted`, or `204 No Content`.

#### **Tests**
- Validates that the response code is one of `[200, 202, 204]`.

#### **Sample Test Code**
```javascript
pm.test("Successful DELETE request", function () {
    pm.expect(pm.response.code).to.be.oneOf([200, 202, 204]);
});
```

---

## Variables

### Defined Variables
1. **`id`**
   - **Value:** `1`
   - **Description:** Represents the ID for specific operations like GET or DELETE.

2. **`base_url`**
   - **Value:** `https://postman-rest-api-learner.glitch.me/`
   - **Description:** The base URL for the API.

---

## Additional Notes

### Tests
Postman tests are included for each endpoint to ensure the API's expected behavior. The tests check for:
- Successful status codes
- Proper responses to CRUD operations

### Prerequest Scripts
No prerequest scripts are defined in the current configuration.

### How to Use
1. Set the `base_url` variable to the desired API server.
2. Use the endpoints as described for CRUD operations.
3. Ensure you have proper network permissions to access the `base_url`.

--- 

This concludes the REST API documentation for SMS Gateway: Flutter. If you have any questions or require further clarification, feel free to ask!
