<?php
/**
 * LilyJoe Textiles ERP - Logout API
 */

require_once '../config/database.php';

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: POST, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization');
    exit(0);
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(['success' => false, 'message' => 'Method not allowed'], 405);
}

// Get token using centralized helper
$token = getBearerToken();

if (!$token) {
    jsonResponse(['success' => false, 'message' => 'No token provided'], 400);
}

try {
    $db = getDB();
    
    // Get session
    $session = $db->fetchOne(
        "SELECT s.*, u.id as user_id FROM sessions s JOIN users u ON s.user_id = u.id WHERE s.session_token = ?",
        [$token]
    );
    
    if ($session) {
        // Log logout activity
        logActivity($session['user_id'], 'logout', 'User logged out');
        
        // Delete session
        $db->query("DELETE FROM sessions WHERE session_token = ?", [$token]);
    }
    
    jsonResponse(['success' => true, 'message' => 'Logged out successfully']);
    
} catch (Exception $e) {
    jsonResponse(['success' => false, 'message' => 'Logout failed: ' . $e->getMessage()], 500);
}
?>
