# LilyJoe Textiles ERP System

A complete, production-ready Enterprise Resource Planning (ERP) system designed for textile and retail businesses. Features Point of Sale (POS), Inventory Management, and Admin Dashboard modules.

## Features

- **Multi-Module System**: ERP Dashboard, Point of Sale, and Inventory Management
- **Role-Based Access**: Super Admin, Admin, Cashier, and Inventory Manager roles
- **Real-Time Sync**: Automatic data synchronization every 15 seconds
- **Dark/Light Mode**: Full theme support across all modules
- **PWA Ready**: Installable on mobile devices with offline support
- **Responsive Design**: Works on desktop, tablet, and mobile devices
- **Invoice & Receipt Generation**: Professional PDF invoices and thermal receipts

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | HTML5, Tailwind CSS, JavaScript |
| Backend | PHP 7.4+ |
| Database | MySQL 5.7+ / MariaDB 10.3+ |
| Server | Apache (XAMPP) |
| Icons | Material Icons |
| Charts | ECharts |
| PDF | html2pdf.js |

## Project Structure

```
lilyjoe_textiles/
├── api/                          # Backend PHP APIs
│   ├── config/
│   │   └── database.php          # Database connection & helpers
│   ├── auth/
│   │   ├── login.php             # User authentication
│   │   ├── logout.php            # Session termination
│   │   └── verify.php            # Token verification
│   ├── products/index.php        # Products CRUD
│   ├── categories/index.php      # Categories CRUD
│   ├── units/index.php           # Units CRUD
│   ├── sales/index.php           # Sales management
│   ├── customers/index.php       # Customer management
│   ├── users/index.php           # User management
│   ├── stock/index.php           # Stock movements
│   ├── dashboard/index.php       # Dashboard statistics
│   └── settings/index.php        # Company settings
├── scripts/                      # Database scripts
│   ├── 001_main_database.sql     # Database schema (run first)
│   └── 002_sample_database.sql   # Sample data with users
├── index.html                    # Redirect to login
├── login.html                    # Authentication page
├── erp-hub.html                  # Admin dashboard
├── pos.html                      # Point of Sale module
├── inventory.html                # Inventory management
├── manifest.json                 # PWA manifest
├── sw.js                         # Service worker
├── offline.html                  # Offline fallback page
└── README.md                     # This documentation
```

## Installation on XAMPP (Windows)

### Prerequisites

1. Download XAMPP from [apachefriends.org](https://www.apachefriends.org/download.html)
2. Install with Apache and MySQL components
3. Default path: `C:\xampp`

### Step 1: Start XAMPP Services

1. Open XAMPP Control Panel (Run as Administrator)
2. Click **Start** next to Apache
3. Click **Start** next to MySQL
4. Both should show green "Running" status

### Step 2: Deploy Project Files

1. Navigate to `C:\xampp\htdocs\`
2. Create folder `lilyjoe_textiles`
3. Copy all project files maintaining the structure:

```
C:\xampp\htdocs\lilyjoe_textiles\
├── api\
├── scripts\
├── index.html
├── login.html
├── erp-hub.html
├── pos.html
├── inventory.html
└── ...
```

### Step 3: Create Database

**Option A: Using phpMyAdmin (Recommended)**

1. Open browser: `http://localhost/phpmyadmin`
2. Click **SQL** tab
3. Copy contents of `scripts/001_main_database.sql`
4. Paste and click **Go**
5. Repeat for `scripts/002_sample_database.sql`
*(Alternatively, import `scripts/lilyjoe_textiles.sql` directly)*

**Option B: Using MySQL Command Line**

```bash
cd C:\xampp\mysql\bin
mysql -u root
source C:/xampp/htdocs/lilyjoe_textiles/scripts/001_main_database.sql;
source C:/xampp/htdocs/lilyjoe_textiles/scripts/002_sample_database.sql;
```

### Step 4: Access the Application

1. Open browser: `http://localhost/lilyjoe_textiles/`
2. Login with credentials below

## Default Login Credentials

| Role | Username | Password | Access |
|------|----------|----------|--------|
| Super Admin | superadmin | super123 | All modules |
| Admin | admin | admin123 | All modules |
| Manager | manager | manage123 | All modules |
| Cashier 1 | cashier1 | cash123 | POS only |
| Cashier 2 | cashier2 | cash123 | POS only |
| Cashier 3 | cashier3 | cash123 | POS only |
| Stock Keeper 1 | stockkeeper | stock123 | Inventory only |
| Stock Keeper 2 | stockkeeper2 | stock123 | Inventory only |

## Sample Data Included

- **8 Users** with different roles
- **8 Categories** (Fabrics, Threads, Zippers & Fasteners, Buttons, Elastic, Linings, etc.)
- **10 Units** of measurement
- **44 Products** across all categories
- **15 Customers** including businesses
- **210 Sales** with items and debt tracking over 24 months
- **Company Settings** pre-configured for LilyJoe Textiles

## API Endpoints

| Endpoint | Methods | Description |
|----------|---------|-------------|
| `/api/auth/login.php` | POST | Authenticate user |
| `/api/auth/logout.php` | POST | End session |
| `/api/auth/verify.php` | GET | Verify token |
| `/api/products/index.php` | GET, POST, PUT, DELETE | Manage products |
| `/api/categories/index.php` | GET, POST, PUT, DELETE | Manage categories |
| `/api/units/index.php` | GET, POST, PUT, DELETE | Manage units |
| `/api/sales/index.php` | GET, POST | Process sales |
| `/api/customers/index.php` | GET, POST, PUT, DELETE | Manage customers |
| `/api/users/index.php` | GET, POST, PUT, DELETE | Manage users |
| `/api/stock/index.php` | GET, POST | Stock movements |
| `/api/dashboard/index.php` | GET | Dashboard stats |
| `/api/settings/index.php` | GET, POST | Company settings |

## Database Configuration

Edit `api/config/database.php` if needed:

```php
define('DB_HOST', '127.0.0.1');
define('DB_NAME', 'lilyjoe_textiles');
define('DB_USER', 'root');
define('DB_PASS', '');  // Empty for default XAMPP
```

## Troubleshooting

### "Database connection failed"
- Ensure MySQL is running in XAMPP
- Verify database `lilyjoe_textiles` exists
- Check credentials in `api/config/database.php`

### "Apache won't start" (Port conflict)
1. Open XAMPP Config > Apache (httpd.conf)
2. Change `Listen 80` to `Listen 8080`
3. Access via `http://localhost:8080/lilyjoe_textiles/`

### "Login not working"
1. Check browser console (F12) for errors
2. Verify SQL scripts executed successfully
3. Check users table has data:
   ```sql
   SELECT * FROM users WHERE username = 'superadmin';
   ```

### "Settings not saving"
- Ensure `company_settings` table exists
- Check API folder permissions
- View Apache error logs: `C:\xampp\apache\logs\error.log`

### "Data not showing in modules"
- Verify sample database script ran successfully
- Check browser network tab for API errors
- Ensure JavaScript console has no errors

## Module Features

### ERP Dashboard
- KPI cards with real-time data
- Sales trend charts
- Cashier performance matrix
- User management
- Company settings
- Report generation

### Point of Sale
- Product grid with search
- Cart with editable prices
- Multiple payment methods (Cash, M-Pesa)
- Debt/partial payment tracking
- Receipt and invoice generation
- Sales history with receipts

### Inventory Management
- Product catalog (grid/list view)
- Category management with icons
- Unit management
- Low stock alerts
- Stock value and potential sales calculations
- Stock adjustments

## Cloud Production Deployment Guide

LilyJoe Textiles ERP is architected to run across a modern cloud stack without modifying its design or frontend interfaces:

```
[ Clients / Mobile PWA ]
          │
          ▼
   [ Vercel CDN ]  ── (proxies /api/*) ──►  [ Railway Backend ]
  (Static HTML/JS)                          (PHP 8.2 Docker API)
                                                      │
                                                      ▼
                                           [ Supabase PostgreSQL ]
                                             (Managed Cloud DB)
```

---

### 1. Database Setup on Supabase
1. Create a project at [supabase.com](https://supabase.com).
2. Go to **SQL Editor** in your Supabase dashboard.
3. Open `scripts/supabase_schema.sql` from this repository, paste its contents into the SQL Editor, and click **Run**.
   - *This creates all 16 tables, 3 views, default seed accounts, and MySQL compatibility shim functions (`CURDATE()`, `DATE_SUB()`, `MONTH()`, `YEAR()`, `JSON_CONTAINS()`).*
4. In Supabase, go to **Project Settings** -> **Database**.
5. Copy the **Connection URI** under **Connection string** (select the **Transaction Pooler** with port `65432` or session port `5432`).
   - Example: `postgresql://postgres.[REF]:[PASSWORD]@aws-0-[REGION].pooler.supabase.com:65432/postgres?sslmode=require`

---

### 2. Backend Deployment on Railway
1. Push this repository to **GitHub**.
2. Go to [railway.com](https://railway.com) and create a **New Project** -> **Deploy from GitHub repo**.
3. Select your `lilyjoe_textiles` repository.
4. Railway will automatically detect the `Dockerfile` and `railway.json`.
5. Under service **Variables**, add:
   - `DATABASE_URL` = `<Your Supabase Connection String>`
   - `DB_DRIVER` = `pgsql`
   - `APP_ENV` = `production`
6. Click **Deploy**. Railway will build the container and verify health via `/api/health.php`.
7. Under service **Settings** -> **Networking**, generate a public domain (e.g. `https://lilyjoe-api.up.railway.app`).

---

### 3. Frontend Deployment on Vercel
1. Go to [vercel.com](https://vercel.com) and click **Add New** -> **Project**.
2. Import your GitHub repository.
3. Configure the build:
   - **Framework Preset**: `Other`
   - **Build Command**: Leave empty / None
   - **Output Directory**: Leave empty / `.`
4. Deploy! Vercel uses `vercel.json` to route `/` to `/login.html` and configure PWA caching.
5. In `vercel.json`, update the `/api/` rewrite destination to point to your Railway domain:
   ```json
   "rewrites": [
     { "source": "/api/:path*", "destination": "https://YOUR_RAILWAY_URL.up.railway.app/api/:path*" },
     { "source": "/", "destination": "/login.html" }
   ]
   ```
   *(Alternatively, configure the Railway URL directly in the browser via `LILYJOE_CONFIG.setApiBase('https://YOUR_RAILWAY_URL.up.railway.app/api')`).*

---

## Security Notes

1. **Password Hashing**: Supported via bcrypt with backward-compatible plain text fallback.
2. **HTTPS**: Enforced automatically by Vercel and Railway edge certificates.
3. **Database SSL**: Enforced by default on Supabase via `sslmode=require`.
4. **Session Authentication**: Bearer tokens are tracked in the database and verified against active sessions.

## License

Proprietary - LilyJoe Textiles Ltd.

---

© 2026 LilyJoe Textiles. All rights reserved.
