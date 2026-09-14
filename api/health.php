<?php
/**
 * LilyJoe Textiles ERP - System Health Check API
 * Probed by Railway / monitoring services to ensure service and database availability.
 */

require_once __DIR__ . '/config/database.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
    exit(0);
}

$response = [
    'status'      => 'healthy',
    'timestamp'   => date('c'),
    'app'         => APP_NAME,
    'version'     => APP_VERSION,
    'php_version' => PHP_VERSION,
    'driver'      => DB_DRIVER,
    'database'    => [
        'connected' => false,
        'driver'    => DB_DRIVER,
        'host'      => DB_HOST,
        'database'  => DB_NAME,
        'latency_ms'=> null
    ]
];

$startTime = microtime(true);

try {
    $db = getDB();
    if (DB_DRIVER === 'pgsql') {
        $test = $db->fetchOne("SELECT 1 AS alive, CURRENT_TIMESTAMP AS now");
    } else {
        $test = $db->fetchOne("SELECT 1 AS alive, NOW() AS now");
    }
    
    $response['database']['connected'] = !empty($test['alive']);
    $response['database']['server_time'] = $test['now'] ?? null;
    $response['database']['latency_ms'] = round((microtime(true) - $startTime) * 1000, 2);
    
    http_response_code(200);
    echo json_encode($response);
} catch (Exception $e) {
    $response['status'] = 'degraded';
    $response['database']['connected'] = false;
    $response['database']['error'] = $e->getMessage();
    
    http_response_code(503);
    echo json_encode($response);
}
