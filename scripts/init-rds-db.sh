#!/bin/bash
# ==============================================================================
# FreshBox SpA - Inicializacion de Tablas y Datos en Amazon RDS via Pod K8s
# ==============================================================================
set -e

NAMESPACE="freshbox"
PROJECT_NAME="freshbox"
REGION="${AWS_REGION:-us-east-1}"

echo "=========================================================="
echo " Inicializando base de datos en Amazon RDS MySQL Multi-AZ"
echo "=========================================================="

# 1. Obtener Endpoint de RDS
RDS_HOST=$(aws rds describe-db-instances --db-instance-identifier "${PROJECT_NAME}-db" --region "$REGION" --query "DBInstances[0].Endpoint.Address" --output text 2>/dev/null || echo "")

if [ -z "$RDS_HOST" ] || [ "$RDS_HOST" == "None" ]; then
    echo "Consultando desde ConfigMap de Kubernetes..."
    RDS_HOST=$(kubectl get configmap freshbox-config -n "$NAMESPACE" -o jsonpath='{.data.DB_HOST}')
fi

echo "Conectando a RDS Host: $RDS_HOST"

# 2. Ejecutar init.sql utilizando un pod efimero de MySQL dentro de EKS
echo "Ejecutando app/init.sql mediante Pod efimero de MySQL en el cluster..."
kubectl run mysql-init-job --rm -i --restart=Never --image=mysql:8.0 -n "$NAMESPACE" -- \
  mysql -h "$RDS_HOST" -u alumno -palumno123 -e "
    CREATE DATABASE IF NOT EXISTS freshbox;
    USE freshbox;
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
    INSERT IGNORE INTO productos (id, nombre, descripcion, precio, stock, categoria) VALUES
    (1, 'Manzana organica 1kg', 'Manzanas rojas organicas, cultivo sin pesticidas', 3490.00, 120, 'Frutas'),
    (2, 'Lechuga hidroponica', 'Lechuga fresca cultivada en sistema hidroponico', 1990.00, 80, 'Verduras'),
    (3, 'Granola artesanal 500g', 'Granola con avena, miel, almendras y arandanos', 4990.00, 60, 'Snacks'),
    (4, 'Jugo natural naranja 1L', 'Jugo 100% natural sin preservantes', 2990.00, 100, 'Bebidas'),
    (5, 'Mix frutos secos 250g', 'Mezcla de almendras, nueces y castanas de caju', 5490.00, 45, 'Snacks');
  "

echo "=========================================================="
echo " Base de datos y datos de prueba inicializados en RDS!"
echo "=========================================================="
