<?php
/**
 * LilyJoe Textiles ERP - Settings API
 * Handles company settings CRUD operations
 */

require_once '../config/database.php';

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization');
    exit(0);
}

$method = $_SERVER['REQUEST_METHOD'];

try {
    $db = getDB();
    
    switch ($method) {
        case 'GET':
            // Load all settings from company_settings table
            $settings = $db->fetchAll("SELECT setting_key, setting_value FROM company_settings");
            $result = [];
            foreach ($settings as $row) {
                $result[$row['setting_key']] = $row['setting_value'];
            }
            if (isset($result['company_mobile']) && !isset($result['company_phone'])) {
                $result['company_phone'] = $result['company_mobile'];
            }
            if (isset($result['company_phone']) && !isset($result['company_mobile'])) {
                $result['company_mobile'] = $result['company_phone'];
            }
            
            $posUsers = $db->fetchOne("SELECT COUNT(*) as count FROM users WHERE status = 'active' AND JSON_CONTAINS(modules, '\"pos\"')");
            $result['pos_user_count'] = $posUsers ? $posUsers['count'] : 1;
            
            jsonResponse(['success' => true, 'data' => $result, 'settings' => $result]);
            break;
            
        case 'POST':
            // Save settings
            $input = json_decode(file_get_contents('php://input'), true);
            
            if (!$input) {
                jsonResponse(['success' => false, 'message' => 'Invalid JSON data'], 400);
            }
            
            $companyPhone = $input['phone'] ?? $input['company_phone'] ?? $input['company_mobile'] ?? null;
            
            $settingsMap = [
                'company_name' => $input['companyName'] ?? $input['company_name'] ?? null,
                'company_phone' => $companyPhone,
                'company_mobile' => $companyPhone,
                'company_email' => $input['email'] ?? $input['company_email'] ?? null,
                'company_address' => $input['address'] ?? $input['company_address'] ?? null,
                'currency' => $input['currency'] ?? null,
                'support_email' => $input['supportEmail'] ?? $input['support_email'] ?? null,
                'timezone' => $input['timezone'] ?? null,
                'daily_target' => $input['dailyTarget'] ?? $input['daily_target'] ?? null,
                'sync_interval' => $input['syncInterval'] ?? $input['sync_interval'] ?? null,
                'tax_enabled' => isset($input['taxEnabled']) ? ($input['taxEnabled'] ? 'true' : 'false') : null,
                'tax_rate' => $input['taxRate'] ?? $input['tax_rate'] ?? null,
                'receipt_header' => $input['receiptHeader'] ?? $input['receipt_header'] ?? null,
                'receipt_footer' => $input['receiptFooter'] ?? $input['receipt_footer'] ?? null
            ];
            
            foreach ($settingsMap as $key => $value) {
                if ($value !== null) {
                    // Check if setting exists
                    $existing = $db->fetchOne("SELECT id FROM company_settings WHERE setting_key = ?", [$key]);
                    
                    if ($existing) {
                        $db->query(
                            "UPDATE company_settings SET setting_value = ?, updated_at = NOW() WHERE setting_key = ?",
                            [$value, $key]
                        );
                    } else {
                        $db->query(
                            "INSERT INTO company_settings (setting_key, setting_value, setting_type, created_at, updated_at) VALUES (?, ?, 'string', NOW(), NOW())",
                            [$key, $value]
                        );
                    }
                }
            }
            
            jsonResponse(['success' => true, 'message' => 'Settings saved successfully']);
            break;
            
        default:
            jsonResponse(['success' => false, 'message' => 'Method not allowed'], 405);
    }
    
} catch (Exception $e) {
    jsonResponse(['success' => false, 'message' => 'Error: ' . $e->getMessage()], 500);
}
?>
