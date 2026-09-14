<?php
/**
 * LilyJoe Textiles ERP - Token Verification API
 */

require_once '../config/database.php';

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization');
    exit(0);
}

$token = getBearerToken();

if (!$token) {
    jsonResponse(['success' => false, 'message' => 'No token provided'], 401);
}

try {
    $db = getDB();
    
    // Verify session
    $session = $db->fetchOne(
        "SELECT s.*, u.id as user_id, u.username, u.full_name, u.email, u.mobile, u.role, u.modules, u.status, u.last_login 
         FROM sessions s 
         JOIN users u ON s.user_id = u.id 
         WHERE s.session_token = ? AND s.expires_at > NOW() AND u.status = 'active'",
        [$token]
    );
    
    if (!$session) {
        jsonResponse(['success' => false, 'message' => 'Invalid or expired token'], 401);
    }
    
    $user = [
        'id' => $session['user_id'],
        'username' => $session['username'],
        'full_name' => $session['full_name'],
        'email' => $session['email'],
        'mobile' => $session['mobile'],
        'role' => $session['role'],
        'modules' => json_decode($session['modules'], true) ?? ['erp', 'pos', 'inventory'],
        'status' => $session['status'],
        'last_login' => $session['last_login']
    ];
    
    jsonResponse([
        'success' => true,
        'user' => $user
    ]);
    
} catch (Exception $e) {
    jsonResponse(['success' => false, 'message' => 'Verification failed: ' . $e->getMessage()], 500);
}
?>
