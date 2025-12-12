-- =====================================================
-- COMPLEX MARIADB DATABASE SCHEMA
-- Features: Multiple foreign keys, orphan tables, 
-- circular dependencies, and multi-level relationships
-- =====================================================

SET FOREIGN_KEY_CHECKS = 0;

CREATE DATABASE IF NOT EXISTS demo;
USE demo;

-- Drop tables if they exist
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS order_status_history;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS shopping_cart_items;
DROP TABLE IF EXISTS shopping_carts;
DROP TABLE IF EXISTS product_reviews;
DROP TABLE IF EXISTS product_images;
DROP TABLE IF EXISTS product_suppliers;
DROP TABLE IF EXISTS product_categories;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS inventory_transactions;
DROP TABLE IF EXISTS inventory;
DROP TABLE IF EXISTS warehouse_employees;
DROP TABLE IF EXISTS warehouses;
DROP TABLE IF EXISTS shipment_items;
DROP TABLE IF EXISTS shipments;
DROP TABLE IF EXISTS payment_methods;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS customer_addresses;
DROP TABLE IF EXISTS customer_preferences;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS employee_roles;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS departments;
DROP TABLE IF EXISTS suppliers;
DROP TABLE IF EXISTS supplier_contacts;
DROP TABLE IF EXISTS audit_logs;
DROP TABLE IF EXISTS system_config;
DROP TABLE IF EXISTS user_sessions;
DROP TABLE IF EXISTS email_queue;
DROP TABLE IF EXISTS notifications;
-- Orphan tables
DROP TABLE IF EXISTS legacy_customer_backup;
DROP TABLE IF EXISTS old_pricing_history;
DROP TABLE IF EXISTS temp_migration_data;
DROP TABLE IF EXISTS archived_orders_2020;

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================
-- CORE BUSINESS TABLES
-- =====================================================

-- Departments table
CREATE TABLE departments (
    department_id INT AUTO_INCREMENT PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL,
    manager_id INT NULL,
    budget DECIMAL(15,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_manager (manager_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Employees table
CREATE TABLE employees (
    employee_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    hire_date DATE NOT NULL,
    department_id INT,
    manager_id INT NULL,
    salary DECIMAL(10,2),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (department_id) REFERENCES departments(department_id) ON DELETE SET NULL,
    FOREIGN KEY (manager_id) REFERENCES employees(employee_id) ON DELETE SET NULL,
    INDEX idx_dept (department_id),
    INDEX idx_manager (manager_id),
    INDEX idx_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Update departments with manager foreign key
ALTER TABLE departments 
ADD CONSTRAINT fk_dept_manager 
FOREIGN KEY (manager_id) REFERENCES employees(employee_id) ON DELETE SET NULL;

-- Employee roles (many-to-many relationship)
CREATE TABLE employee_roles (
    role_id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id INT NOT NULL,
    role_name VARCHAR(50) NOT NULL,
    assigned_date DATE NOT NULL,
    expiry_date DATE NULL,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE,
    INDEX idx_employee (employee_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Customers table
CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    date_of_birth DATE,
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    account_status ENUM('active', 'suspended', 'closed') DEFAULT 'active',
    assigned_employee_id INT NULL,
    loyalty_points INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (assigned_employee_id) REFERENCES employees(employee_id) ON DELETE SET NULL,
    INDEX idx_email (email),
    INDEX idx_status (account_status),
    INDEX idx_employee (assigned_employee_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Customer addresses
CREATE TABLE customer_addresses (
    address_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    address_type ENUM('billing', 'shipping', 'both') NOT NULL,
    street_address VARCHAR(200) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(50) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    country VARCHAR(50) NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE,
    INDEX idx_customer (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Customer preferences
CREATE TABLE customer_preferences (
    preference_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    newsletter_subscribed BOOLEAN DEFAULT FALSE,
    sms_notifications BOOLEAN DEFAULT FALSE,
    preferred_language VARCHAR(10) DEFAULT 'en',
    preferred_currency VARCHAR(3) DEFAULT 'USD',
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE,
    UNIQUE KEY uk_customer (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- PRODUCT MANAGEMENT
-- =====================================================

-- Categories
CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    parent_category_id INT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_category_id) REFERENCES categories(category_id) ON DELETE SET NULL,
    INDEX idx_parent (parent_category_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Suppliers
CREATE TABLE suppliers (
    supplier_id INT AUTO_INCREMENT PRIMARY KEY,
    supplier_name VARCHAR(100) NOT NULL,
    contact_person VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20),
    address TEXT,
    country VARCHAR(50),
    rating DECIMAL(3,2),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_rating (rating)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Supplier contacts
CREATE TABLE supplier_contacts (
    contact_id INT AUTO_INCREMENT PRIMARY KEY,
    supplier_id INT NOT NULL,
    contact_name VARCHAR(100) NOT NULL,
    position VARCHAR(50),
    email VARCHAR(100),
    phone VARCHAR(20),
    is_primary BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id) ON DELETE CASCADE,
    INDEX idx_supplier (supplier_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Products
CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(200) NOT NULL,
    sku VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    base_price DECIMAL(10,2) NOT NULL,
    cost_price DECIMAL(10,2),
    weight DECIMAL(8,2),
    dimensions VARCHAR(50),
    primary_supplier_id INT NULL,
    created_by_employee_id INT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (primary_supplier_id) REFERENCES suppliers(supplier_id) ON DELETE SET NULL,
    FOREIGN KEY (created_by_employee_id) REFERENCES employees(employee_id) ON DELETE SET NULL,
    INDEX idx_sku (sku),
    INDEX idx_supplier (primary_supplier_id),
    INDEX idx_price (base_price)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Product categories (many-to-many)
CREATE TABLE product_categories (
    product_category_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    category_id INT NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE CASCADE,
    UNIQUE KEY uk_product_category (product_id, category_id),
    INDEX idx_product (product_id),
    INDEX idx_category (category_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Product suppliers (many-to-many)
CREATE TABLE product_suppliers (
    product_supplier_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    supplier_id INT NOT NULL,
    supplier_sku VARCHAR(50),
    lead_time_days INT,
    minimum_order_quantity INT,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id) ON DELETE CASCADE,
    UNIQUE KEY uk_product_supplier (product_id, supplier_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Product images
CREATE TABLE product_images (
    image_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    image_url VARCHAR(500) NOT NULL,
    image_type ENUM('thumbnail', 'main', 'gallery') NOT NULL,
    display_order INT DEFAULT 0,
    uploaded_by_employee_id INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    FOREIGN KEY (uploaded_by_employee_id) REFERENCES employees(employee_id) ON DELETE SET NULL,
    INDEX idx_product (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Product reviews
CREATE TABLE product_reviews (
    review_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    customer_id INT NOT NULL,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review_title VARCHAR(200),
    review_text TEXT,
    is_verified_purchase BOOLEAN DEFAULT FALSE,
    helpful_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE,
    INDEX idx_product (product_id),
    INDEX idx_customer (customer_id),
    INDEX idx_rating (rating)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- INVENTORY MANAGEMENT
-- =====================================================

-- Warehouses
CREATE TABLE warehouses (
    warehouse_id INT AUTO_INCREMENT PRIMARY KEY,
    warehouse_name VARCHAR(100) NOT NULL,
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(50),
    country VARCHAR(50),
    manager_employee_id INT NULL,
    capacity INT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (manager_employee_id) REFERENCES employees(employee_id) ON DELETE SET NULL,
    INDEX idx_manager (manager_employee_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Warehouse employees
CREATE TABLE warehouse_employees (
    warehouse_employee_id INT AUTO_INCREMENT PRIMARY KEY,
    warehouse_id INT NOT NULL,
    employee_id INT NOT NULL,
    assigned_date DATE NOT NULL,
    role VARCHAR(50),
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id) ON DELETE CASCADE,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE,
    UNIQUE KEY uk_warehouse_employee (warehouse_id, employee_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Inventory
CREATE TABLE inventory (
    inventory_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    warehouse_id INT NOT NULL,
    quantity_available INT NOT NULL DEFAULT 0,
    quantity_reserved INT NOT NULL DEFAULT 0,
    reorder_point INT DEFAULT 10,
    reorder_quantity INT DEFAULT 50,
    last_restocked_date TIMESTAMP NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id) ON DELETE CASCADE,
    UNIQUE KEY uk_product_warehouse (product_id, warehouse_id),
    INDEX idx_product (product_id),
    INDEX idx_warehouse (warehouse_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Inventory transactions
CREATE TABLE inventory_transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    inventory_id INT NOT NULL,
    transaction_type ENUM('in', 'out', 'adjustment', 'return') NOT NULL,
    quantity INT NOT NULL,
    reference_type VARCHAR(50),
    reference_id INT,
    employee_id INT NULL,
    notes TEXT,
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (inventory_id) REFERENCES inventory(inventory_id) ON DELETE CASCADE,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE SET NULL,
    INDEX idx_inventory (inventory_id),
    INDEX idx_type (transaction_type),
    INDEX idx_date (transaction_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- ORDERS AND SHOPPING
-- =====================================================

-- Shopping carts
CREATE TABLE shopping_carts (
    cart_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE,
    INDEX idx_customer (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Shopping cart items
CREATE TABLE shopping_cart_items (
    cart_item_id INT AUTO_INCREMENT PRIMARY KEY,
    cart_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cart_id) REFERENCES shopping_carts(cart_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    INDEX idx_cart (cart_id),
    INDEX idx_product (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Orders
CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    order_number VARCHAR(50) UNIQUE NOT NULL,
    customer_id INT NOT NULL,
    billing_address_id INT NOT NULL,
    shipping_address_id INT NOT NULL,
    order_status ENUM('pending', 'processing', 'shipped', 'delivered', 'cancelled', 'returned') DEFAULT 'pending',
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    subtotal DECIMAL(12,2) NOT NULL,
    tax_amount DECIMAL(12,2) DEFAULT 0,
    shipping_cost DECIMAL(10,2) DEFAULT 0,
    discount_amount DECIMAL(10,2) DEFAULT 0,
    total_amount DECIMAL(12,2) NOT NULL,
    assigned_warehouse_id INT NULL,
    processed_by_employee_id INT NULL,
    notes TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE RESTRICT,
    FOREIGN KEY (billing_address_id) REFERENCES customer_addresses(address_id) ON DELETE RESTRICT,
    FOREIGN KEY (shipping_address_id) REFERENCES customer_addresses(address_id) ON DELETE RESTRICT,
    FOREIGN KEY (assigned_warehouse_id) REFERENCES warehouses(warehouse_id) ON DELETE SET NULL,
    FOREIGN KEY (processed_by_employee_id) REFERENCES employees(employee_id) ON DELETE SET NULL,
    INDEX idx_customer (customer_id),
    INDEX idx_order_number (order_number),
    INDEX idx_status (order_status),
    INDEX idx_date (order_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Order items
CREATE TABLE order_items (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    discount_percent DECIMAL(5,2) DEFAULT 0,
    line_total DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT,
    INDEX idx_order (order_id),
    INDEX idx_product (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Order status history
CREATE TABLE order_status_history (
    history_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    old_status VARCHAR(20),
    new_status VARCHAR(20) NOT NULL,
    changed_by_employee_id INT NULL,
    notes TEXT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (changed_by_employee_id) REFERENCES employees(employee_id) ON DELETE SET NULL,
    INDEX idx_order (order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- PAYMENTS
-- =====================================================

-- Payment methods
CREATE TABLE payment_methods (
    payment_method_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    method_type ENUM('credit_card', 'debit_card', 'paypal', 'bank_transfer') NOT NULL,
    card_last_four VARCHAR(4),
    card_brand VARCHAR(20),
    expiry_month INT,
    expiry_year INT,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE,
    INDEX idx_customer (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Payments
CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    payment_method_id INT NULL,
    amount DECIMAL(12,2) NOT NULL,
    payment_status ENUM('pending', 'completed', 'failed', 'refunded') DEFAULT 'pending',
    transaction_id VARCHAR(100),
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_by_employee_id INT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE RESTRICT,
    FOREIGN KEY (payment_method_id) REFERENCES payment_methods(payment_method_id) ON DELETE SET NULL,
    FOREIGN KEY (processed_by_employee_id) REFERENCES employees(employee_id) ON DELETE SET NULL,
    INDEX idx_order (order_id),
    INDEX idx_status (payment_status),
    INDEX idx_transaction (transaction_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- SHIPPING
-- =====================================================

-- Shipments
CREATE TABLE shipments (
    shipment_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    tracking_number VARCHAR(100),
    carrier VARCHAR(50),
    shipped_date TIMESTAMP NULL,
    estimated_delivery_date DATE NULL,
    actual_delivery_date TIMESTAMP NULL,
    shipment_status ENUM('preparing', 'shipped', 'in_transit', 'delivered', 'failed') DEFAULT 'preparing',
    shipped_from_warehouse_id INT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (shipped_from_warehouse_id) REFERENCES warehouses(warehouse_id) ON DELETE SET NULL,
    INDEX idx_order (order_id),
    INDEX idx_tracking (tracking_number),
    INDEX idx_status (shipment_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Shipment items
CREATE TABLE shipment_items (
    shipment_item_id INT AUTO_INCREMENT PRIMARY KEY,
    shipment_id INT NOT NULL,
    order_item_id INT NOT NULL,
    quantity INT NOT NULL,
    FOREIGN KEY (shipment_id) REFERENCES shipments(shipment_id) ON DELETE CASCADE,
    FOREIGN KEY (order_item_id) REFERENCES order_items(order_item_id) ON DELETE CASCADE,
    INDEX idx_shipment (shipment_id),
    INDEX idx_order_item (order_item_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- SYSTEM TABLES
-- =====================================================

-- System configuration
CREATE TABLE system_config (
    config_id INT AUTO_INCREMENT PRIMARY KEY,
    config_key VARCHAR(100) UNIQUE NOT NULL,
    config_value TEXT,
    description TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    updated_by_employee_id INT NULL,
    FOREIGN KEY (updated_by_employee_id) REFERENCES employees(employee_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Audit logs
CREATE TABLE audit_logs (
    log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    record_id INT NOT NULL,
    action ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    old_values JSON,
    new_values JSON,
    user_id INT NULL,
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_table (table_name),
    INDEX idx_user (user_id),
    INDEX idx_date (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- User sessions
CREATE TABLE user_sessions (
    session_id VARCHAR(100) PRIMARY KEY,
    customer_id INT NULL,
    employee_id INT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE,
    INDEX idx_customer (customer_id),
    INDEX idx_employee (employee_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Notifications
CREATE TABLE notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    recipient_type ENUM('customer', 'employee') NOT NULL,
    recipient_id INT NOT NULL,
    notification_type VARCHAR(50) NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    reference_type VARCHAR(50),
    reference_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_recipient (recipient_type, recipient_id),
    INDEX idx_read (is_read)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Email queue
CREATE TABLE email_queue (
    email_id INT AUTO_INCREMENT PRIMARY KEY,
    recipient_email VARCHAR(100) NOT NULL,
    subject VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,
    email_type VARCHAR(50),
    status ENUM('pending', 'sent', 'failed') DEFAULT 'pending',
    attempts INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sent_at TIMESTAMP NULL,
    INDEX idx_status (status),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- ORPHAN TABLES (No foreign keys or relationships)
-- =====================================================

-- Legacy customer backup (orphan table)
CREATE TABLE legacy_customer_backup (
    old_customer_id INT PRIMARY KEY,
    legacy_data TEXT,
    migrated_date DATE,
    notes TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Old pricing history (orphan table)
CREATE TABLE old_pricing_history (
    record_id INT AUTO_INCREMENT PRIMARY KEY,
    old_product_code VARCHAR(50),
    old_price DECIMAL(10,2),
    effective_date DATE,
    archived_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Temp migration data (orphan table)
CREATE TABLE temp_migration_data (
    temp_id INT AUTO_INCREMENT PRIMARY KEY,
    source_system VARCHAR(50),
    raw_data JSON,
    import_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed BOOLEAN DEFAULT FALSE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Archived orders from 2020 (orphan table)
CREATE TABLE archived_orders_2020 (
    archive_id INT AUTO_INCREMENT PRIMARY KEY,
    original_order_id INT,
    order_data JSON,
    archived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- SAMPLE DATA INSERTION
-- =====================================================

