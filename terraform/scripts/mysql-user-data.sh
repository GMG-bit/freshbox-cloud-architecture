#!/bin/bash
set -ex
exec > /var/log/user-data.log 2>&1

# Instalar MySQL Server
yum update -y
yum install -y mysql-server
systemctl enable mysqld
systemctl start mysqld

# Esperar a que MySQL inicie
sleep 10

# Configurar usuario
mysql -e "CREATE USER '${db_user}'@'%' IDENTIFIED BY '${db_password}';"
mysql -e "GRANT ALL PRIVILEGES ON *.* TO '${db_user}'@'%';"
mysql -e "FLUSH PRIVILEGES;"

# Crear base de datos y tabla
mysql -e "
CREATE DATABASE IF NOT EXISTS ${db_name};
USE ${db_name};
CREATE TABLE IF NOT EXISTS productos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    descripcion TEXT,
    precio DECIMAL(10,2) NOT NULL,
    stock INT NOT NULL DEFAULT 0,
    categoria VARCHAR(100),
    imagen_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
INSERT INTO productos (nombre, descripcion, precio, stock, categoria) VALUES
('Manzana organica 1kg', 'Manzanas rojas organicas, cultivo sin pesticidas', 3490.00, 120, 'Frutas'),
('Lechuga hidroponica', 'Lechuga fresca cultivada en sistema hidroponico', 1990.00, 80, 'Verduras'),
('Granola artesanal 500g', 'Granola con avena, miel, almendras y arandanos', 4990.00, 60, 'Snacks'),
('Jugo natural naranja 1L', 'Jugo 100%% natural de naranja, sin preservantes', 2990.00, 100, 'Bebidas'),
('Mix frutos secos 250g', 'Mezcla de almendras, nueces, castanas y pasas organicas', 5490.00, 45, 'Snacks');
"

echo '=== MySQL User Data completado ==='
