-- ================================================================
-- LILYJOE TEXTILES ERP - SUPABASE (POSTGRESQL) PRODUCTION SCHEMA
-- ================================================================
-- Version: 3.0 Production Ready for Supabase / PostgreSQL 14+
-- Description: Complete PostgreSQL database schema with tables,
--              compatibility shim functions for MySQL syntax,
--              views, indexes, and initial seed data.
-- ================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ================================================================
-- 1. MYSQL COMPATIBILITY SHIM FUNCTIONS FOR POSTGRESQL
-- ================================================================
-- Allows existing PHP queries written for MySQL to run seamlessly
-- on Supabase PostgreSQL without changes.

CREATE OR REPLACE FUNCTION CURDATE() RETURNS DATE AS $$
BEGIN
    RETURN CURRENT_DATE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION DATE_SUB(d TIMESTAMP, i INTERVAL) RETURNS TIMESTAMP AS $$
BEGIN
    RETURN d - i;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION DATE_SUB(d DATE, i INTERVAL) RETURNS DATE AS $$
BEGIN
    RETURN (d - i)::DATE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION MONTH(d TIMESTAMP) RETURNS INTEGER AS $$
BEGIN
    RETURN EXTRACT(MONTH FROM d)::INTEGER;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION MONTH(d DATE) RETURNS INTEGER AS $$
BEGIN
    RETURN EXTRACT(MONTH FROM d)::INTEGER;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION YEAR(d TIMESTAMP) RETURNS INTEGER AS $$
BEGIN
    RETURN EXTRACT(YEAR FROM d)::INTEGER;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION YEAR(d DATE) RETURNS INTEGER AS $$
BEGIN
    RETURN EXTRACT(YEAR FROM d)::INTEGER;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION JSON_CONTAINS(target JSONB, candidate JSONB) RETURNS BOOLEAN AS $$
BEGIN
    RETURN target @> candidate;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION JSON_CONTAINS(target TEXT, candidate TEXT) RETURNS BOOLEAN AS $$
BEGIN
    BEGIN
        RETURN target::JSONB @> candidate::JSONB;
    EXCEPTION WHEN OTHERS THEN
        RETURN target LIKE '%' || candidate || '%';
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ================================================================
-- 2. CORE TABLES
-- ================================================================

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    mobile VARCHAR(20),
    phone VARCHAR(20),
    role VARCHAR(50) NOT NULL DEFAULT 'Cashier',
    modules JSONB DEFAULT '["erp","pos","inventory"]'::jsonb,
    profile_image TEXT DEFAULT NULL,
    status VARCHAR(20) DEFAULT 'active',
    last_login TIMESTAMP DEFAULT NULL,
    deleted_at TIMESTAMP DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- Categories table
CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    icon VARCHAR(50) DEFAULT 'fa-box',
    color VARCHAR(20) DEFAULT '#667eea',
    description TEXT,
    product_count INT DEFAULT 0,
    deleted_at TIMESTAMP DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_categories_name ON categories(name);

-- Units table
CREATE TABLE IF NOT EXISTS units (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    symbol VARCHAR(20),
    abbreviation VARCHAR(20),
    type VARCHAR(20) DEFAULT 'count',
    description TEXT,
    products_using INT DEFAULT 0,
    deleted_at TIMESTAMP DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_units_name ON units(name);

-- Products table
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    sku VARCHAR(50) UNIQUE,
    barcode VARCHAR(100),
    category_id INT REFERENCES categories(id) ON DELETE SET NULL,
    unit_id INT REFERENCES units(id) ON DELETE SET NULL,
    cost_price NUMERIC(15,2) DEFAULT 0.00,
    selling_price NUMERIC(15,2) DEFAULT 0.00,
    minimum_price NUMERIC(15,2) DEFAULT 0.00,
    current_stock NUMERIC(15,3) DEFAULT 0,
    stock_quantity NUMERIC(15,3) DEFAULT 0,
    minimum_stock NUMERIC(15,3) DEFAULT 0,
    low_stock_threshold INT DEFAULT 0,
    maximum_stock INT DEFAULT 0,
    has_multi_unit SMALLINT DEFAULT 0,
    base_unit_label VARCHAR(60) DEFAULT NULL,
    package_unit_label VARCHAR(60) DEFAULT NULL,
    package_size NUMERIC(15,3) DEFAULT NULL,
    image TEXT,
    image_url TEXT,
    description TEXT,
    description_color VARCHAR(50),
    description_size VARCHAR(50),
    description_type VARCHAR(100),
    description_dimensions VARCHAR(100),
    description_weight VARCHAR(50),
    brand VARCHAR(100),
    supplier VARCHAR(200),
    total_sold INT DEFAULT 0,
    last_restocked TIMESTAMP,
    storage_location VARCHAR(100),
    status VARCHAR(30) DEFAULT 'active',
    deleted_at TIMESTAMP DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_products_name ON products(name);
CREATE INDEX IF NOT EXISTS idx_products_sku ON products(sku);
CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_status ON products(status);
CREATE INDEX IF NOT EXISTS idx_products_stock ON products(current_stock);

-- Customers table
CREATE TABLE IF NOT EXISTS customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    mobile VARCHAR(20),
    email VARCHAR(100),
    address TEXT,
    total_purchases NUMERIC(15,2) DEFAULT 0.00,
    total_debt NUMERIC(15,2) DEFAULT 0.00,
    last_purchase_date TIMESTAMP,
    deleted_at TIMESTAMP DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_customers_name ON customers(name);
CREATE INDEX IF NOT EXISTS idx_customers_mobile ON customers(mobile);

-- Sales table
CREATE TABLE IF NOT EXISTS sales (
    id SERIAL PRIMARY KEY,
    order_number VARCHAR(50) NOT NULL UNIQUE,
    parent_sale_id INT REFERENCES sales(id) ON DELETE SET NULL,
    sale_type VARCHAR(30) DEFAULT 'regular',
    customer_id INT REFERENCES customers(id) ON DELETE SET NULL,
    customer_name VARCHAR(100),
    customer_mobile VARCHAR(20),
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subtotal NUMERIC(15,2) DEFAULT 0.00,
    tax NUMERIC(15,2) DEFAULT 0.00,
    discount NUMERIC(15,2) DEFAULT 0.00,
    total NUMERIC(15,2) DEFAULT 0.00,
    profit NUMERIC(15,2) DEFAULT 0.00,
    unexpected_profit NUMERIC(15,2) DEFAULT 0.00,
    payment_method VARCHAR(30) DEFAULT 'cash',
    mpesa_code VARCHAR(50),
    split_cash NUMERIC(15,2) DEFAULT NULL,
    split_mobile NUMERIC(15,2) DEFAULT NULL,
    payment_status VARCHAR(30) DEFAULT 'paid',
    amount_paid NUMERIC(15,2) DEFAULT 0.00,
    amount_due NUMERIC(15,2) DEFAULT 0.00,
    notes TEXT,
    receipt_html TEXT,
    invoice_html TEXT,
    sale_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sales_order_number ON sales(order_number);
CREATE INDEX IF NOT EXISTS idx_sales_date ON sales(sale_date);
CREATE INDEX IF NOT EXISTS idx_sales_status ON sales(payment_status);
CREATE INDEX IF NOT EXISTS idx_sales_user ON sales(user_id);
CREATE INDEX IF NOT EXISTS idx_sales_parent ON sales(parent_sale_id);

-- Sale items table
CREATE TABLE IF NOT EXISTS sale_items (
    id SERIAL PRIMARY KEY,
    sale_id INT NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
    product_id INT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    product_name VARCHAR(200) NOT NULL,
    quantity NUMERIC(15,3) NOT NULL,
    unit_label VARCHAR(60) DEFAULT NULL,
    base_quantity NUMERIC(15,3) DEFAULT NULL,
    unit_price NUMERIC(15,2) NOT NULL,
    cost_price NUMERIC(15,2) DEFAULT 0.00,
    minimum_price NUMERIC(15,2) DEFAULT 0.00,
    discount NUMERIC(15,2) DEFAULT 0.00,
    total NUMERIC(15,2) NOT NULL,
    profit NUMERIC(15,2) DEFAULT 0.00,
    unexpected_profit NUMERIC(15,2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sale_items_sale ON sale_items(sale_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_product ON sale_items(product_id);

-- Stock movements table
CREATE TABLE IF NOT EXISTS stock_movements (
    id SERIAL PRIMARY KEY,
    product_id INT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    product_name VARCHAR(200) NOT NULL,
    type VARCHAR(30) NOT NULL,
    quantity NUMERIC(15,3) NOT NULL,
    previous_stock NUMERIC(15,3) NOT NULL,
    new_stock NUMERIC(15,3) NOT NULL,
    user_id INT REFERENCES users(id) ON DELETE SET NULL,
    reference_id INT,
    reference_type VARCHAR(50),
    reason TEXT,
    movement_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_movements_product ON stock_movements(product_id);
CREATE INDEX IF NOT EXISTS idx_movements_type ON stock_movements(type);
CREATE INDEX IF NOT EXISTS idx_movements_date ON stock_movements(movement_date);

-- Debt orders table
CREATE TABLE IF NOT EXISTS debt_orders (
    id SERIAL PRIMARY KEY,
    sale_id INT NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
    customer_id INT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    amount_due NUMERIC(15,2) NOT NULL,
    amount_paid NUMERIC(15,2) DEFAULT 0.00,
    due_date DATE NOT NULL,
    status VARCHAR(30) DEFAULT 'pending',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_debt_orders_customer ON debt_orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_debt_orders_status ON debt_orders(status);
CREATE INDEX IF NOT EXISTS idx_debt_orders_due_date ON debt_orders(due_date);

-- Debt payments table
CREATE TABLE IF NOT EXISTS debt_payments (
    id SERIAL PRIMARY KEY,
    debt_id INT NOT NULL REFERENCES debt_orders(id) ON DELETE CASCADE,
    sale_id INT REFERENCES sales(id) ON DELETE SET NULL,
    amount NUMERIC(15,2) NOT NULL,
    payment_method VARCHAR(30) DEFAULT 'cash',
    mpesa_code VARCHAR(50),
    user_id INT REFERENCES users(id) ON DELETE SET NULL,
    receipt_html TEXT,
    notes TEXT,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_debt_payments_debt ON debt_payments(debt_id);

-- Product units table
CREATE TABLE IF NOT EXISTS product_units (
    id SERIAL PRIMARY KEY,
    product_id INT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    unit_label VARCHAR(60) NOT NULL,
    conversion_to_base NUMERIC(15,3) NOT NULL DEFAULT 1,
    selling_price NUMERIC(15,2) NOT NULL DEFAULT 0,
    minimum_price NUMERIC(15,2) NOT NULL DEFAULT 0,
    is_base SMALLINT DEFAULT 0,
    is_default SMALLINT DEFAULT 0,
    allow_custom_length SMALLINT DEFAULT 0,
    sort_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_product_units_product ON product_units(product_id);

-- Deleted items archive table
CREATE TABLE IF NOT EXISTS deleted_items (
    id SERIAL PRIMARY KEY,
    entity_type VARCHAR(50) NOT NULL,
    entity_id INT NOT NULL,
    entity_label VARCHAR(255),
    data TEXT,
    deleted_by_id INT,
    deleted_by_name VARCHAR(150),
    deleted_by_role VARCHAR(50),
    reason TEXT,
    deleted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_deleted_items_entity ON deleted_items(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_deleted_items_date ON deleted_items(deleted_at);

-- Support messages table
CREATE TABLE IF NOT EXISTS support_messages (
    id SERIAL PRIMARY KEY,
    user_id INT,
    sender_name VARCHAR(150),
    sender_email VARCHAR(150),
    sender_role VARCHAR(50),
    subject VARCHAR(255),
    message TEXT NOT NULL,
    category VARCHAR(60) DEFAULT 'general',
    status VARCHAR(30) DEFAULT 'new',
    emailed SMALLINT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_support_messages_status ON support_messages(status);
CREATE INDEX IF NOT EXISTS idx_support_messages_created ON support_messages(created_at);

-- User activity log table
CREATE TABLE IF NOT EXISTS user_activity (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    action VARCHAR(100) NOT NULL,
    description TEXT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_user_activity_user ON user_activity(user_id);
CREATE INDEX IF NOT EXISTS idx_user_activity_action ON user_activity(action);
CREATE INDEX IF NOT EXISTS idx_user_activity_date ON user_activity(created_at);

-- Company settings table
CREATE TABLE IF NOT EXISTS company_settings (
    id SERIAL PRIMARY KEY,
    setting_key VARCHAR(100) NOT NULL UNIQUE,
    setting_value TEXT,
    setting_type VARCHAR(50) DEFAULT 'string',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_company_settings_key ON company_settings(setting_key);

-- Sessions table
CREATE TABLE IF NOT EXISTS sessions (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_token VARCHAR(255) NOT NULL UNIQUE,
    ip_address VARCHAR(45),
    user_agent TEXT,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sessions_token ON sessions(session_token);
CREATE INDEX IF NOT EXISTS idx_sessions_user ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_expires ON sessions(expires_at);

-- ================================================================
-- 3. VIEWS
-- ================================================================

-- Cashier performance view
CREATE OR REPLACE VIEW cashier_performance AS
SELECT 
    u.id as user_id,
    u.full_name,
    u.username,
    u.role,
    COUNT(s.id) as total_sales,
    COALESCE(SUM(s.total), 0) as total_revenue,
    COALESCE(SUM(s.profit), 0) as total_profit,
    COALESCE(SUM(s.unexpected_profit), 0) as total_unexpected_profit,
    COALESCE(AVG(s.total), 0) as avg_order_value,
    COUNT(DISTINCT (s.sale_date)::DATE) as days_worked,
    MAX(s.sale_date) as last_sale_date
FROM users u
LEFT JOIN sales s ON u.id = s.user_id
WHERE u.role IN ('Cashier', 'Inventory Manager', 'Manager', 'Admin', 'Super Admin')
GROUP BY u.id, u.full_name, u.username, u.role;

-- Low stock products view
CREATE OR REPLACE VIEW low_stock_products AS
SELECT 
    p.id,
    p.name,
    p.sku,
    p.current_stock,
    p.minimum_stock,
    p.selling_price,
    c.name as category_name
FROM products p
LEFT JOIN categories c ON p.category_id = c.id
WHERE p.current_stock <= p.minimum_stock AND p.status = 'active';

-- Daily sales summary view
CREATE OR REPLACE VIEW daily_sales_summary AS
SELECT 
    (sale_date)::DATE as sale_day,
    COUNT(*) as total_orders,
    SUM(total) as total_revenue,
    SUM(profit) as total_profit,
    SUM(unexpected_profit) as total_unexpected_profit,
    SUM(CASE WHEN payment_method = 'cash' THEN total ELSE 0 END) as cash_sales,
    SUM(CASE WHEN payment_method = 'mobile' THEN total ELSE 0 END) as mobile_sales,
    SUM(CASE WHEN payment_status IN ('partial', 'pending') THEN amount_due ELSE 0 END) as total_debt
FROM sales
WHERE payment_status != 'cancelled'
GROUP BY (sale_date)::DATE
ORDER BY sale_day DESC;

-- ================================================================
-- 4. DEFAULT SEED DATA
-- ================================================================

-- Company Settings
INSERT INTO company_settings (setting_key, setting_value, setting_type) VALUES
('company_name', 'LilyJoe Textiles', 'string'),
('company_address', 'LilyJoe Plaza, Biashara Street, Nairobi, Kenya', 'string'),
('company_mobile', '+254712345678', 'string'),
('company_phone', '+254712345678', 'string'),
('company_email', 'info@lilyjoetextiles.com', 'string'),
('company_website', 'www.lilyjoetextiles.com', 'string'),
('tax_rate', '16', 'number'),
('currency', 'KES', 'string'),
('daily_target', '75000', 'number'),
('support_email', 'support@lilyjoetextiles.com', 'string'),
('receipt_footer', 'Thank you for choosing LilyJoe Textiles!', 'string')
ON CONFLICT (setting_key) DO UPDATE SET setting_value = EXCLUDED.setting_value;

-- Default Users (superadmin, admin, manager, cashier, inventory)
INSERT INTO users (username, password, full_name, email, mobile, phone, role, modules, status) VALUES
('superadmin', 'super123', 'Caleb Magaju', 'calebmagaju@lilyjoetextiles.com', '+254707516393', '+254707516393', 'Super Admin', '["erp","pos","inventory"]'::jsonb, 'active'),
('admin', 'admin123', 'Sarah Njeri', 'sarah@lilyjoetextiles.com', '+254700000002', '+254700000002', 'Admin', '["erp","pos","inventory"]'::jsonb, 'active'),
('manager', 'manage123', 'John Kamau', 'john@lilyjoetextiles.com', '+254700000003', '+254700000003', 'Manager', '["erp","pos","inventory"]'::jsonb, 'active'),
('cashier1', 'cash123', 'Mary Wanjiku', 'mary@lilyjoetextiles.com', '+254700000004', '+254700000004', 'Cashier', '["pos"]'::jsonb, 'active'),
('inventory1', 'invent123', 'David Otieno', 'david@lilyjoetextiles.com', '+254700000007', '+254700000007', 'Inventory Manager', '["inventory"]'::jsonb, 'active')
ON CONFLICT (username) DO NOTHING;

-- Default Categories
INSERT INTO categories (name, icon, color, description) VALUES
('Cotton Fabrics', 'fa-scroll', '#3B82F6', '100% pure and blended cotton fabrics'),
('Silk & Satin', 'fa-feather', '#EC4899', 'Premium silk, satin, and organza materials'),
('Wool & Linen', 'fa-cloud', '#10B981', 'Heavy wool, suitings, and lightweight linens'),
('Curtains & Drapes', 'fa-blinds', '#F59E0B', 'Sheer curtains, heavy drapery, and blackout fabrics'),
('Accessories & Notions', 'fa-cut', '#8B5CF6', 'Threads, zippers, buttons, and tailoring supplies')
ON CONFLICT DO NOTHING;

-- Default Units
INSERT INTO units (name, symbol, abbreviation, type, description) VALUES
('Metre', 'm', 'm', 'length', 'Standard metric unit for fabric length'),
('Roll', 'roll', 'roll', 'count', 'Whole fabric bolt or roll (approx 30-50m)'),
('Piece', 'pc', 'pc', 'count', 'Pre-cut finished fabric pieces, scarfs, blankets'),
('Yard', 'yd', 'yd', 'length', 'Traditional imperial fabric measure (0.9144m)')
ON CONFLICT DO NOTHING;
