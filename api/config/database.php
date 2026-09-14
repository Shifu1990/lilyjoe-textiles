<?php
/**
 * LilyJoe Textiles ERP - Database Configuration
 * Configuration for MySQL database connection via XAMPP
 */

// Environment resolution helper
function getEnvVar($key, $default = null) {
    $val = getenv($key);
    if ($val !== false && $val !== '') {
        return $val;
    }
    if (isset($_ENV[$key]) && $_ENV[$key] !== '') {
        return $_ENV[$key];
    }
    if (isset($_SERVER[$key]) && $_SERVER[$key] !== '') {
        return $_SERVER[$key];
    }
    return $default;
}

// Database configuration with environment variable support (Supabase, Railway, XAMPP)
$dbUrl = getEnvVar('DATABASE_URL');
$parsedDriver = null;
$parsedHost = null;
$parsedPort = null;
$parsedName = null;
$parsedUser = null;
$parsedPass = null;

if ($dbUrl) {
    $parsed = parse_url($dbUrl);
    if ($parsed) {
        $scheme = strtolower($parsed['scheme'] ?? 'mysql');
        $parsedDriver = in_array($scheme, ['postgres', 'postgresql', 'pgsql']) ? 'pgsql' : 'mysql';
        $parsedHost = $parsed['host'] ?? '127.0.0.1';
        $parsedPort = isset($parsed['port']) ? (int)$parsed['port'] : ($parsedDriver === 'pgsql' ? 5432 : 3306);
        $parsedName = isset($parsed['path']) ? ltrim($parsed['path'], '/') : 'lilyjoe_textiles';
        $parsedUser = isset($parsed['user']) ? urldecode($parsed['user']) : 'root';
        $parsedPass = isset($parsed['pass']) ? urldecode($parsed['pass']) : '';
    }
}

$dbDriver = $parsedDriver ?: strtolower(getEnvVar('DB_DRIVER', getEnvVar('DB_CONNECTION', 'mysql')));
if (in_array($dbDriver, ['postgres', 'postgresql'])) {
    $dbDriver = 'pgsql';
}

define('DB_DRIVER', $dbDriver);
define('DB_HOST', $parsedHost ?: getEnvVar('DB_HOST', getEnvVar('PGHOST', getEnvVar('MYSQLHOST', '127.0.0.1'))));
define('DB_PORT', $parsedPort ?: (int)getEnvVar('DB_PORT', getEnvVar('PGPORT', getEnvVar('MYSQLPORT', DB_DRIVER === 'pgsql' ? 5432 : 3306))));
define('DB_NAME', $parsedName ?: getEnvVar('DB_NAME', getEnvVar('DB_DATABASE', getEnvVar('PGDATABASE', getEnvVar('MYSQLDATABASE', 'lilyjoe_textiles')))));
define('DB_USER', $parsedUser ?: getEnvVar('DB_USER', getEnvVar('DB_USERNAME', getEnvVar('PGUSER', getEnvVar('MYSQLUSER', 'root')))));
define('DB_PASS', $parsedPass !== null ? $parsedPass : getEnvVar('DB_PASS', getEnvVar('DB_PASSWORD', getEnvVar('PGPASSWORD', getEnvVar('MYSQLPASSWORD', '')))));
define('DB_CHARSET', getEnvVar('DB_CHARSET', 'utf8mb4'));

// Application configuration
define('APP_NAME', 'LilyJoe Textiles');
define('APP_VERSION', '2.0.0');
define('CURRENCY', 'KES');
define('TIMEZONE', 'Africa/Nairobi');

// Set timezone
date_default_timezone_set(TIMEZONE);

// Ensure output buffering is active to prevent PHP warnings corrupting JSON output
if (!ob_get_level()) {
    ob_start();
}

// Error reporting: log errors, suppress stdout display in API responses
error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);

// Session configuration
ini_set('session.cookie_httponly', 1);
ini_set('session.use_only_cookies', 1);

/**
 * Database connection class using PDO supporting MySQL & PostgreSQL (Supabase)
 */
class Database {
    private static $instance = null;
    private $connection;
    private $driver;
    
    private function __construct() {
        try {
            $this->driver = DB_DRIVER;
            if ($this->driver === 'pgsql') {
                $sslmode = getEnvVar('DB_SSLMODE', 'require');
                $dsn = "pgsql:host=" . DB_HOST . ";port=" . DB_PORT . ";dbname=" . DB_NAME . ";sslmode=" . $sslmode;
                $options = [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                    PDO::ATTR_EMULATE_PREPARES => false,
                ];
            } else {
                $dsn = "mysql:host=" . DB_HOST . ";port=" . DB_PORT . ";dbname=" . DB_NAME . ";charset=" . DB_CHARSET;
                $options = [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                    PDO::ATTR_EMULATE_PREPARES => false,
                    PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES " . DB_CHARSET
                ];
            }
            
            $this->connection = new PDO($dsn, DB_USER, DB_PASS, $options);
        } catch (PDOException $e) {
            jsonResponse([
                'success' => false,
                'message' => 'Database connection failed: ' . $e->getMessage()
            ], 500);
        }
    }
    
    /**
     * Get singleton database instance
     */
    public static function getInstance() {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }
    
    /**
     * Get PDO connection
     */
    public function getConnection() {
        return $this->connection;
    }
    
    /**
     * Execute a query with parameters
     */
    public function query($sql, $params = []) {
        try {
            $stmt = $this->connection->prepare($sql);
            $stmt->execute($params);
            return $stmt;
        } catch (PDOException $e) {
            throw new Exception('Query failed: ' . $e->getMessage());
        }
    }
    
    /**
     * Fetch single row
     */
    public function fetchOne($sql, $params = []) {
        $stmt = $this->query($sql, $params);
        return $stmt->fetch();
    }
    
    /**
     * Fetch all rows
     */
    public function fetchAll($sql, $params = []) {
        $stmt = $this->query($sql, $params);
        return $stmt->fetchAll();
    }
    
    /**
     * Get database driver (pgsql or mysql)
     */
    public function getDriver() {
        return $this->driver;
    }
    
    /**
     * Get last inserted ID
     */
    public function lastInsertId($name = null) {
        return $this->connection->lastInsertId($name);
    }
    
    /**
     * Begin transaction
     */
    public function beginTransaction() {
        return $this->connection->beginTransaction();
    }
    
    /**
     * Commit transaction
     */
    public function commit() {
        return $this->connection->commit();
    }
    
    /**
     * Rollback transaction
     */
    public function rollback() {
        return $this->connection->rollBack();
    }
    
    // Prevent cloning
    private function __clone() {}
    
    // Prevent unserialization
    public function __wakeup() {
        throw new Exception("Cannot unserialize singleton");
    }
}

/**
 * Helper function to get database instance
 */
function getDB() {
    return Database::getInstance();
}

/**
 * JSON response helper with clean buffer flushing
 */
function jsonResponse($data, $statusCode = 200) {
    if (ob_get_level()) {
        ob_clean();
    }
    http_response_code($statusCode);
    header('Content-Type: application/json; charset=utf-8');
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
    echo json_encode($data);
    exit;
}

/**
 * Robust Bearer token extraction across Apache / XAMPP configurations
 */
function getBearerToken() {
    $headers = function_exists('getallheaders') ? getallheaders() : [];
    $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? null;
    if ($authHeader && preg_match('/Bearer\s+(\S+)/i', $authHeader, $matches)) {
        return $matches[1];
    }
    return $_GET['token'] ?? null;
}

/**
 * Require valid authenticated user session.
 * Returns user_id or halts with 401.
 */
function requireAuth($db = null) {
    if (!$db) {
        $db = getDB();
    }
    $token = getBearerToken();
    if (!$token) {
        jsonResponse(['success' => false, 'message' => 'Unauthorized: Missing token'], 401);
    }
    $session = $db->fetchOne(
        "SELECT user_id FROM sessions WHERE session_token = ? AND expires_at > NOW()",
        [$token]
    );
    if (!$session) {
        jsonResponse(['success' => false, 'message' => 'Unauthorized: Invalid or expired session'], 401);
    }
    return (int)$session['user_id'];
}

/**
 * Format currency
 */
function formatCurrency($amount) {
    return CURRENCY . ' ' . number_format($amount, 2);
}

/**
 * Generate unique order number
 */
function generateOrderNumber() {
    $date = date('Ymd');
    $db = getDB();
    $result = $db->fetchOne(
        "SELECT COUNT(*) as count FROM sales WHERE DATE(sale_date) = CURDATE()"
    );
    $sequence = str_pad(($result['count'] + 1), 3, '0', STR_PAD_LEFT);
    return $date . $sequence;
}

/**
 * Get a company setting value (with fallback default)
 */
function getSetting($key, $default = null) {
    try {
        $db = getDB();
        $row = $db->fetchOne("SELECT setting_value FROM company_settings WHERE setting_key = ?", [$key]);
        return ($row && $row['setting_value'] !== null && $row['setting_value'] !== '') ? $row['setting_value'] : $default;
    } catch (Exception $e) {
        return $default;
    }
}

/**
 * Soft delete helper - archives a record into deleted_items before/instead of
 * a hard delete. Returns the inserted archive id.
 *
 * @param string $entityType  e.g. 'product', 'category', 'unit', 'user', 'sale'
 * @param int    $entityId    original primary key
 * @param string $label       human readable name / order number
 * @param mixed  $data        full row(s) snapshot (array) - stored as JSON
 * @param array  $performer   ['id'=>, 'name'=>, 'role'=>] of the user deleting
 * @param string $reason      optional reason
 */
function archiveDeletedItem($entityType, $entityId, $label, $data, $performer = [], $reason = null) {
    $db = getDB();
    $db->query(
        "INSERT INTO deleted_items (entity_type, entity_id, entity_label, data, deleted_by_id, deleted_by_name, deleted_by_role, reason)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        [
            $entityType,
            $entityId,
            $label,
            is_string($data) ? $data : json_encode($data),
            $performer['id'] ?? null,
            $performer['name'] ?? 'Unknown',
            $performer['role'] ?? 'Unknown',
            $reason
        ]
    );
    return $db->lastInsertId();
}

/**
 * Extract the acting user (performer) from request input for delete auditing.
 */
function getPerformer($input = []) {
    return [
        'id'   => $input['performed_by_id'] ?? $input['user_id'] ?? null,
        'name' => $input['performed_by_name'] ?? $input['user_name'] ?? 'Unknown',
        'role' => $input['performed_by_role'] ?? $input['user_role'] ?? 'Unknown',
    ];
}

/**
 * Log user activity
 */
function logActivity($userId, $action, $description = '') {
    $db = getDB();
    $ip = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
    $userAgent = $_SERVER['HTTP_USER_AGENT'] ?? 'unknown';
    
    $db->query(
        "INSERT INTO user_activity (user_id, action, description, ip_address, user_agent) VALUES (?, ?, ?, ?, ?)",
        [$userId, $action, $description, $ip, $userAgent]
    );
}
?>
