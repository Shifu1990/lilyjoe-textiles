<?php
/**
 * LilyJoe Textiles ERP - Login API
 * Handles user authentication
 */

require_once '../config/database.php';

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: POST, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type');
    exit(0);
}

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(['success' => false, 'message' => 'Method not allowed'], 405);
}

// Get JSON input
$input = json_decode(file_get_contents('php://input'), true);

// Validate input
if (!isset($input['username']) || !isset($input['password'])) {
    jsonResponse(['success' => false, 'message' => 'Username and password are required'], 400);
}

$username = trim($input['username']);
$password = trim($input['password']);

if (empty($username) || empty($password)) {
    jsonResponse(['success' => false, 'message' => 'Username and password cannot be empty'], 400);
}

try {
    $db = getDB();
    
    // Find user by username
    $user = $db->fetchOne(
        "SELECT * FROM users WHERE username = ? AND status = 'active'",
        [$username]
    );
    
    if (!$user) {
        jsonResponse(['success' => false, 'message' => 'Invalid username or password'], 401);
    }
    
    // Check password: supports modern bcrypt hash and legacy plain text fallback
    $passwordMatches = password_verify($password, $user['password']) || ($user['password'] === $password);
    if (!$passwordMatches) {
        jsonResponse(['success' => false, 'message' => 'Invalid username or password'], 401);
    }
    
    // Generate session token
    $sessionToken = bin2hex(random_bytes(32));
    $expiresAt = date('Y-m-d H:i:s', strtotime('+24 hours'));
    
    // Store session in database
    $db->query(
        "INSERT INTO sessions (user_id, session_token, ip_address, user_agent, expires_at) VALUES (?, ?, ?, ?, ?)",
        [
            $user['id'],
            $sessionToken,
            $_SERVER['REMOTE_ADDR'] ?? 'unknown',
            $_SERVER['HTTP_USER_AGENT'] ?? 'unknown',
            $expiresAt
        ]
    );
    
    // Update last login
    $db->query(
        "UPDATE users SET last_login = NOW() WHERE id = ?",
        [$user['id']]
    );
    
    // Log the login activity
    logActivity($user['id'], 'login', 'User logged in successfully');
    
    // Remove sensitive data
    unset($user['password']);
    
    // Parse modules JSON
    $user['modules'] = json_decode($user['modules'], true) ?? ['erp', 'pos', 'inventory'];
    
    // Return success response
    jsonResponse([
        'success' => true,
        'message' => 'Login successful',
        'user' => $user,
        'token' => $sessionToken,
        'expires_at' => $expiresAt
    ]);
    
} catch (Exception $e) {
    jsonResponse(['success' => false, 'message' => 'Login failed: ' . $e->getMessage()], 500);
}
?>
