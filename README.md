# REST API Documentation for SMS Gateway: Flutter  

This documentation outlines the API endpoints for the **SMS Gateway** application. It details each endpoint's functionality, request/response structure, and example use cases.  

---

## Overview  

### **Base URL**  
The base URL serves as the entry point for all API requests:  
**`{{base_url}}`**  
Example: `https://localhost:8080/`  

---

## Endpoints  

### 1. **Retrieve SMS Messages**  

#### **Description**  
This endpoint retrieves all SMS messages stored on the server.  

#### **Request**  
- **Method:** `GET`  
- **URL:** `{{base_url}}/sms`  
- **Headers:** None required  

#### **Query Parameters**  
You can optionally include query parameters to filter results:  
- **`phone_number`** (optional): Filter messages by the associated phone number.  

#### **Example Request**  
```http
GET https://localhost:8080/sms
```  

#### **Response**  
- **Status Code:** `200 OK`  
- **Body:** JSON array containing SMS records  

#### **Postman Test Code**  
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});
```  

---

### 2. **Send an SMS**  

#### **Description**  
This endpoint allows you to send an SMS by providing a recipient's phone number and a message in the request body.  

#### **Request**  
- **Method:** `POST`  
- **URL:** `{{base_url}}/sms`  
- **Headers:**  
  - `Content-Type`: `application/json`  
- **Body:** JSON object  
  ```json
  {
      "number": "+1234567890",
      "message": "Hello, this is a test message!"
  }
  ```  

#### **Example Request**  
```http
POST https://localhost:8080/sms
Content-Type: application/json

{
    "number": "+1234567890",
    "message": "Hello, this is a test message!"
}
```  

#### **Response**  
- **Status Code:**  
  - `200 OK` or  
  - `201 Created`  
- **Body:** JSON confirmation of the message sent  

#### **Postman Test Code**  
```javascript
pm.test("Successful POST request", function () {
    pm.expect(pm.response.code).to.be.oneOf([200, 201]);
});
```  

---

### 3. **Delete an SMS**  

#### **Description**  
This endpoint deletes a specific SMS record by its unique identifier (`id`).  

#### **Request**  
- **Method:** `DELETE`  
- **URL:** `{{base_url}}/sms/:id`  
  *(Replace `:id` with the actual SMS ID)*  
- **Headers:** None required  
- **Body:** Empty  

#### **Example Request**  
```http
DELETE https://localhost:8080/sms/2
```  

#### **Response**  
- **Status Code:**  
  - `200 OK`  
  - `202 Accepted`  
  - `204 No Content`  

#### **Postman Test Code**  
```javascript
pm.test("Successful DELETE request", function () {
    pm.expect(pm.response.code).to.be.oneOf([200, 202, 204]);
});
```  

---

## Variables  

### Defined Variables  
These variables allow dynamic usage of the API:  

1. **`base_url`**  
   - **Value:** `https://localhost:8080/`  
   - **Description:** The root URL for the API.  

2. **`id`**  
   - **Value:** `1`  
   - **Description:** Represents the identifier for specific SMS records used in GET and DELETE requests.  

---

## Usage Guidelines  

1. Set the **`base_url`** variable to point to your API server.  
2. Use the provided endpoints to perform CRUD operations.  
3. Ensure that you have a stable internet connection for server communication.  

---

## Additional Information  

### Postman Tests  
Each endpoint includes a predefined Postman test to verify expected behavior. These tests ensure:  
- Correct status codes are returned (`200`, `201`, etc.)  
- Proper response formats for all CRUD operations  

### Prerequest Scripts  
No prerequest scripts are defined in the current configuration.  

---

## Examples  

### Example 1: Retrieve All SMS Messages  
```bash
curl -X GET "{{base_url}}/sms"
```  

### Example 2: Send an SMS  
```bash
curl -X POST "{{base_url}}/sms" \
-H "Content-Type: application/json" \
-d '{
    "number": "+1234567890",
    "message": "Hello, this is a test message!"
}'
```  

### Example 3: Delete an SMS  
```bash
curl -X DELETE "{{base_url}}/sms/2"
```  

---

## Notes  
- This application is a proof-of-concept and may require additional features for production use.  
- Ensure the server is configured correctly and accessible at the specified base URL.  

For additional questions or support, refer to the development team.  