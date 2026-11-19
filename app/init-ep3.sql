-- FreshBox SpA - Base de Datos Extendida (EP3)
USE freshbox;

CREATE TABLE IF NOT EXISTS ordenes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(100) NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    estado ENUM('pendiente', 'procesado', 'enviado', 'entregado') DEFAULT 'pendiente',
    items JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Verificar productos existentes (de EP2)
-- Si no existen, insertarlos
INSERT IGNORE INTO productos (id, nombre, descripcion, precio, stock, categoria) VALUES
(1, 'Manzana organica 1kg', 'Manzanas rojas organicas, cultivo sin pesticidas', 3490.00, 120, 'Frutas'),
(2, 'Lechuga hidroponica', 'Lechuga fresca cultivada en sistema hidroponico', 1990.00, 80, 'Verduras'),
(3, 'Granola artesanal 500g', 'Granola con avena, miel, almendras y arandanos', 4990.00, 60, 'Snacks'),
(4, 'Jugo natural naranja 1L', 'Jugo 100% natural de naranja, sin preservantes', 2990.00, 100, 'Bebidas'),
(5, 'Mix frutos secos 250g', 'Mezcla de almendras, nueces, castanas y pasas organicas', 5490.00, 45, 'Snacks');

-- 2026 - Disenador asignatura: Ignacio A. Pastenet M.
