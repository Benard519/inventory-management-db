---

# 📦 Inventory Management Database (MySQL Project)

Welcome to the **Inventory Management Database System** 🎉  
This project is my submission for the Database Management assignment — Question 1.  
It’s a relational database schema built with **MySQL** to manage products, customers, suppliers, warehouses, sales, and purchases.  

---

## 🛠️ What’s Inside?
This repo contains one main file:  

- **`inventory_management_system.sql`**  
  - Creates the database `inventory_system`  
  - Defines **well-structured tables** with proper constraints  
  - Establishes **relationships** (One-to-One, One-to-Many, Many-to-Many where needed)  
  - Includes **sample data inserts** for testing  
  - Adds a **view** (`vw_product_stock`) to quickly check stock levels  

---

## 🗂️ Database Entities
The schema includes the following tables:
- `categories` 🏷️ – groups products by type  
- `suppliers` 🚚 – tracks suppliers and contacts  
- `warehouses` 🏭 – physical storage locations  
- `products` 📦 – items available for sale or purchase  
- `stock_levels` 📊 – product stock per warehouse  
- `customers` 🙋 – stores customer details  
- `sales_orders` 🧾 – customer orders  
- `sales_order_items` 🛒 – line items within sales orders  
- `purchase_orders` 📥 – orders placed to suppliers  
- `purchase_order_items` 📦 – items received from suppliers  
- `users` 👩‍💻 – system users with roles  

---

## 🚀 How to Use

### 1. Import the Database
Run the SQL script in your MySQL server:
```bash
mysql -u root -p < inventory_management_system.sql
````

### 2. Verify Installation

Log into MySQL and check:

```sql
USE inventory_system;
SHOW TABLES;
SELECT * FROM vw_product_stock;
```

You should see the list of tables and some **sample data** ready to test.

---

## 🎯 Features & Highlights

* ✅ **Relational schema** with primary keys, foreign keys, unique & not null constraints
* ✅ **Multiple relationships** (1:1, 1\:N, M\:N)
* ✅ **Indexes & views** for better query performance
* ✅ **Sample data** so you can test immediately
* ✅ **Real-world use case**: inventory + sales + purchases

---
