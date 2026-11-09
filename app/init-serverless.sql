-- ==============================================================================
-- FreshBox SpA - Extension de Base de Datos para Arquitectura Serverless (EA3/EP3)
-- Asignatura: Arquitectura Cloud (ARY1102)
-- Tablas para procesamiento desacoplado de ordenes y persistencia relacional
-- ==============================================================================

USE freshbox;

-- Tabla para persistencia transaccional de ordenes procesadas desde SQS
CREATE TABLE IF NOT EXISTS ordenes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id VARCHAR(64) NOT NULL UNIQUE,
    user_id VARCHAR(64) NOT NULL,
    items JSON NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    estado VARCHAR(30) NOT NULL DEFAULT 'PROCESADA',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user (user_id),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
