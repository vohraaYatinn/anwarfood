# Anwar Food Backend

This is the backend API for the Anwar Food application. It provides endpoints for user authentication, product management, cart operations, and order processing.

## Prerequisites

- Node.js (v14 or higher)
- MySQL (v5.6 or higher)
- npm or yarn package manager

## Setup

1. Clone the repository
2. Install dependencies:
   ```bash
   npm install
   ```

3. Create a `.env` file in the root directory with the following variables:
   ```
   DB_HOST=localhost
   DB_USER=your_mysql_username
   DB_PASSWORD=your_mysql_password
   DB_NAME=shoppurs
   JWT_SECRET=your_jwt_secret_key
   PORT=3000
   ```

4. Import the database schema from `sqldata.md` into your MySQL server

5. Start the server:
   ```bash
   node server.js
   ```

## API Endpoints

### Authentication
- POST `/signup` - Register a new user
- POST `/login` - User login

### Products
- GET `/productlist` - Get all products
- GET `/productdetail/:id` - Get product details
- POST `/productadd` - Add new product
- PUT `/productedit/:id` - Edit product

### Cart
- POST `/addtocart` - Add item to cart
- GET `/getcart/:userId` - Get user's cart

### Retailers
- GET `/retailerlist` - Get all retailers
- GET `/retailerdetails/:id` - Get retailer details

### Orders
- GET `/orderlist/:userId` - Get user's orders

## Authentication

Most endpoints require authentication. Include the JWT token in the Authorization header:
```
Authorization: Bearer your_jwt_token
```

## Error Handling

The API uses standard HTTP status codes:
- 200: Success
- 201: Created
- 400: Bad Request
- 401: Unauthorized
- 404: Not Found
- 500: Internal Server Error

## Security

- Passwords are hashed using bcrypt
- JWT tokens are used for authentication
- SQL injection prevention using parameterized queries
- CORS enabled for cross-origin requests 