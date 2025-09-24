-- inventory_management_system.sql
-- Small Business Inventory & Sales Database
-- Contains: CREATE DATABASE, CREATE TABLES, constraints, sample data

SET FOREIGN_KEY_CHECKS = 0;

CREATE DATABASE IF NOT EXISTS inventory_system
  CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_general_ci;
USE inventory_system;

SET FOREIGN_KEY_CHECKS = 1;

-- -----------------------------------------------------
-- Table: categories
-- Product categories
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS categories (
  category_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- Table: suppliers
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS suppliers (
  supplier_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  contact_email VARCHAR(150),
  contact_phone VARCHAR(50),
  address TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- Table: warehouses
-- Physical storage locations
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS warehouses (
  warehouse_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  location VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- Table: products
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS products (
  product_id INT AUTO_INCREMENT PRIMARY KEY,
  sku VARCHAR(50) NOT NULL UNIQUE,
  name VARCHAR(200) NOT NULL,
  category_id INT,
  supplier_id INT,
  unit_price DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  cost_price DECIMAL(12,2) DEFAULT 0.00,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_products_category FOREIGN KEY (category_id)
    REFERENCES categories(category_id) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_products_supplier FOREIGN KEY (supplier_id)
    REFERENCES suppliers(supplier_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- Table: stock_levels
-- Tracks quantity of each product per warehouse
-- Composite primary key (warehouse_id, product_id)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS stock_levels (
  warehouse_id INT NOT NULL,
  product_id INT NOT NULL,
  quantity INT NOT NULL DEFAULT 0,
  min_threshold INT NOT NULL DEFAULT 0, -- for reorder notification
  last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (warehouse_id, product_id),
  CONSTRAINT fk_stock_warehouse FOREIGN KEY (warehouse_id)
    REFERENCES warehouses(warehouse_id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_stock_product FOREIGN KEY (product_id)
    REFERENCES products(product_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Index to quickly find low stock items
CREATE INDEX idx_stock_quantity ON stock_levels(quantity);

-- -----------------------------------------------------
-- Table: customers
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS customers (
  customer_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(200) NOT NULL,
  email VARCHAR(150),
  phone VARCHAR(50),
  address TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- Table: sales_orders
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS sales_orders (
  sales_order_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  order_number VARCHAR(50) NOT NULL UNIQUE,
  customer_id INT,
  order_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status ENUM('PENDING','PAID','SHIPPED','CANCELLED','RETURNED') NOT NULL DEFAULT 'PENDING',
  total_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  created_by VARCHAR(100),
  CONSTRAINT fk_sales_customer FOREIGN KEY (customer_id)
    REFERENCES customers(customer_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- Table: sales_order_items
-- Each item in a sales order (many-to-one with sales_orders)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS sales_order_items (
  sales_order_item_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  sales_order_id BIGINT NOT NULL,
  product_id INT NOT NULL,
  warehouse_id INT NOT NULL,
  quantity INT NOT NULL,
  unit_price DECIMAL(12,2) NOT NULL,
  line_total DECIMAL(14,2) GENERATED ALWAYS AS (quantity * unit_price) VIRTUAL,
  CONSTRAINT fk_soi_order FOREIGN KEY (sales_order_id)
    REFERENCES sales_orders(sales_order_id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_soi_product FOREIGN KEY (product_id)
    REFERENCES products(product_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_soi_warehouse FOREIGN KEY (warehouse_id)
    REFERENCES warehouses(warehouse_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_sales_order ON sales_order_items (sales_order_id);

-- -----------------------------------------------------
-- Table: purchase_orders
-- Tracks purchases from suppliers
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS purchase_orders (
  purchase_order_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  po_number VARCHAR(50) NOT NULL UNIQUE,
  supplier_id INT,
  po_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expected_arrival DATE,
  status ENUM('CREATED','RECEIVED','CANCELLED') NOT NULL DEFAULT 'CREATED',
  total_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  CONSTRAINT fk_po_supplier FOREIGN KEY (supplier_id)
    REFERENCES suppliers(supplier_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- Table: purchase_order_items
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS purchase_order_items (
  purchase_order_item_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  purchase_order_id BIGINT NOT NULL,
  product_id INT NOT NULL,
  warehouse_id INT NOT NULL,
  quantity INT NOT NULL,
  unit_cost DECIMAL(12,2) NOT NULL,
  CONSTRAINT fk_poi_po FOREIGN KEY (purchase_order_id)
    REFERENCES purchase_orders(purchase_order_id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_poi_product FOREIGN KEY (product_id)
    REFERENCES products(product_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_poi_warehouse FOREIGN KEY (warehouse_id)
    REFERENCES warehouses(warehouse_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- Optional: users (system users who create orders)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
  user_id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(80) NOT NULL UNIQUE,
  full_name VARCHAR(150),
  password_hash VARCHAR(255),
  role ENUM('ADMIN','STAFF') DEFAULT 'STAFF',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- Views & helper objects (example)
-- -----------------------------------------------------
DROP VIEW IF EXISTS vw_product_stock;
CREATE VIEW vw_product_stock AS
SELECT p.product_id, p.sku, p.name AS product_name, c.name AS category,
       SUM(s.quantity) AS total_stock
FROM products p
LEFT JOIN categories c ON p.category_id = c.category_id
LEFT JOIN stock_levels s ON p.product_id = s.product_id
GROUP BY p.product_id, p.sku, p.name, c.name;

-- -----------------------------------------------------
-- SAMPLE DATA (a few rows to help verify the schema)
-- -----------------------------------------------------
INSERT INTO categories (name, description) VALUES
  ('Electronics','Gadgets and electronic accessories'),
  ('Household','Cleaning and household supplies'),
  ('Groceries','Food items and perishables');

INSERT INTO suppliers (name, contact_email, contact_phone) VALUES
  ('Acme Suppliers Ltd','supplier@acme.example','+254700111222'),
  ('Nairobi Wholesale','contact@nairobisupplies.example','+254700333444');

INSERT INTO warehouses (name, location) VALUES
  ('Main Warehouse','Eldoret - Industrial Area'),
  ('Storefront','Town Center');

INSERT INTO products (sku, name, category_id, supplier_id, unit_price, cost_price)
VALUES
  ('SKU-EE-001','Portable Charger 10,000mAh', 1, 1, 2500.00, 1800.00),
  ('SKU-HH-002','Laundry Detergent 2L', 2, 2, 400.00, 250.00),
  ('SKU-GR-003','Maize Flour 2kg', 3, 2, 200.00, 120.00);

-- Populate stock levels
INSERT INTO stock_levels (warehouse_id, product_id, quantity, min_threshold) VALUES
  (1, 1, 45, 5),
  (2, 1, 10, 3),
  (1, 2, 80, 10),
  (2, 2, 20, 5),
  (1, 3, 150, 20);

INSERT INTO customers (name, email, phone) VALUES
  ('John Mwangi','john.m@example.com','+254722111222'),
  ('Anna Wanjiru','anna.w@example.com','+254722333444');

-- Example sales order
INSERT INTO sales_orders (order_number, customer_id, status, total_amount, created_by)
VALUES ('SO-2025-0001', 1, 'PAID', 5000.00, 'benard');

INSERT INTO sales_order_items (sales_order_id, product_id, warehouse_id, quantity, unit_price)
VALUES (LAST_INSERT_ID(), 1, 2, 2, 2500.00);

-- Example purchase order
INSERT INTO purchase_orders (po_number, supplier_id, status, total_amount)
VALUES ('PO-2025-0001', 1, 'CREATED', 3600.00);

INSERT INTO purchase_order_items (purchase_order_id, product_id, warehouse_id, quantity, unit_cost)
VALUES (LAST_INSERT_ID(), 1, 1, 2, 1800.00);
