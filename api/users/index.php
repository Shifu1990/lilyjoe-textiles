<?php
/**
 * LilyJoe Textiles ERP - Users API
 */

require_once '../config/database.php';

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization');
    exit(0);
}

$method = $_SERVER['REQUEST_METHOD'];

try {
    $db = getDB();
    
    switch ($method) {
        case 'GET':
            if (isset($_GET['id'])) {
                $user = $db->fetchOne("SELECT id, username, full_name, email, mobile, role, modules, status, last_login, profile_image, created_at FROM users WHERE id = ?", [$_GET['id']]);
                if (!$user) {
                    jsonResponse(['success' => false, 'message' => 'User not found'], 404);
                }
                $user['modules'] = json_decode($user['modules'], true) ?? [];
                jsonResponse(['success' => true, 'user' => $user, 'data' => $user]);
            } else {
                $users = $db->fetchAll("SELECT id, username, full_name, email, mobile, role, modules, status, last_login, profile_image, created_at FROM users ORDER BY created_at DESC");
                foreach ($users as &$user) {
                    $modulesJson = $user['modules'];
                    $user['modules'] = json_decode($modulesJson, true) ?? [];
                    $user['modules_display'] = is_array($user['modules']) ? implode(', ', array_map('ucfirst', $user['modules'])) : 'None';
                }
                jsonResponse(['success' => true, 'users' => $users, 'data' => $users, 'count' => count($users)]);
            }
            break;
            
        case 'POST':
            $input = json_decode(file_get_contents('php://input'), true);
            
            if (!isset($input['username']) || !isset($input['password']) || !isset($input['full_name'])) {
                jsonResponse(['success' => false, 'message' => 'Username, password, and full name are required'], 400);
            }
            
            // Check if username exists
            $existing = $db->fetchOne("SELECT id FROM users WHERE username = ?", [$input['username']]);
            if ($existing) {
                jsonResponse(['success' => false, 'message' => 'Username already exists'], 400);
            }
            
            $modules = ['pos']; // Default
            if (isset($input['modules'])) {
                if (is_array($input['modules'])) {
                    $modules = $input['modules'];
                } elseif (is_string($input['modules'])) {
                    $decoded = json_decode($input['modules'], true);
                    if ($decoded) {
                        $modules = $decoded;
                    } else {
                        $modules = array_map('trim', explode(',', $input['modules']));
                    }
                }
            }
            $modulesJson = json_encode(array_values(array_filter($modules)));
            
            $db->query(
                "INSERT INTO users (username, password, full_name, email, mobile, role, modules, status) 
                 VALUES (?, ?, ?, ?, ?, ?, ?, 'active')",
                [
                    $input['username'],
                    $input['password'],
                    $input['full_name'],
                    $input['email'] ?? '',
                    $input['mobile'] ?? '',
                    $input['role'] ?? 'Cashier',
                    $modulesJson
                ]
            );
            
            $userId = $db->lastInsertId();
            $user = $db->fetchOne("SELECT id, username, full_name, email, mobile, role, modules, status, created_at FROM users WHERE id = ?", [$userId]);
            $user['modules'] = json_decode($user['modules'], true);
            
            jsonResponse(['success' => true, 'message' => 'User created successfully', 'user' => $user, 'data' => $user], 201);
            break;
            
        case 'PUT':
            $input = json_decode(file_get_contents('php://input'), true);
            $userId = isset($_GET['id']) ? $_GET['id'] : (isset($input['id']) ? $input['id'] : null);
            
            if (!$userId) {
                jsonResponse(['success' => false, 'message' => 'User ID is required'], 400);
            }
            
            $updateFields = [];
            $params = [];
            
            $allowedFields = ['username', 'full_name', 'email', 'mobile', 'role', 'status', 'phone', 'profile_image'];
            
            foreach ($allowedFields as $field) {
                if (isset($input[$field])) {
                    $updateFields[] = "$field = ?";
                    $params[] = $input[$field];
                }
            }
            
            if (isset($input['modules'])) {
                $modules = $input['modules'];
                if (is_string($modules)) {
                    $decoded = json_decode($modules, true);
                    if ($decoded) {
                        $modules = $decoded;
                    } else {
                        $modules = array_map('trim', explode(',', $modules));
                    }
                }
                $updateFields[] = "modules = ?";
                $params[] = json_encode(array_values(array_filter($modules)));
            }
            
            if (isset($input['password']) && !empty($input['password'])) {
                $updateFields[] = "password = ?";
                $params[] = $input['password'];
            }
            
            if (empty($updateFields)) {
                jsonResponse(['success' => false, 'message' => 'No fields to update'], 400);
            }
            
            $params[] = $userId;
            $db->query("UPDATE users SET " . implode(', ', $updateFields) . " WHERE id = ?", $params);
            
            $user = $db->fetchOne("SELECT id, username, full_name, email, mobile, role, modules, status, created_at FROM users WHERE id = ?", [$userId]);
            $user['modules'] = json_decode($user['modules'], true);
            
            jsonResponse(['success' => true, 'message' => 'User updated successfully', 'user' => $user, 'data' => $user]);
            break;
            
        case 'DELETE':
            $input = json_decode(file_get_contents('php://input'), true) ?? [];
            $userId = $_GET['id'] ?? $input['id'] ?? null;
            
            if (!$userId) {
                jsonResponse(['success' => false, 'message' => 'User ID is required'], 400);
            }
            
            // Prevent deleting super admin
            $user = $db->fetchOne("SELECT * FROM users WHERE id = ?", [$userId]);
            if ($user && $user['role'] === 'Super Admin') {
                jsonResponse(['success' => false, 'message' => 'Cannot delete Super Admin user'], 400);
            }
            if (!$user) {
                jsonResponse(['success' => false, 'message' => 'User not found'], 404);
            }
            
            // Soft delete: archive (without password) before removing
            $snapshot = $user;
            unset($snapshot['password']);
            archiveDeletedItem('user', $user['id'], $user['full_name'], $snapshot, getPerformer($input), $input['reason'] ?? null);
            
            $db->query("DELETE FROM users WHERE id = ?", [$userId]);
            jsonResponse(['success' => true, 'message' => 'User deleted successfully']);
            break;
            
        default:
            jsonResponse(['success' => false, 'message' => 'Method not allowed'], 405);
    }
    
} catch (Exception $e) {
    jsonResponse(['success' => false, 'message' => 'Error: ' . $e->getMessage()], 500);
}
?>
