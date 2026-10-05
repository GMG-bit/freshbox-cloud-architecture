# Security Groups para Arquitectura EKS + RDS Multi-AZ (EA2)

# 1. Security Group para Application Load Balancer (ALB Ingress)
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-sg-alb"
  description = "Security Group para Application Load Balancer gestionado por AWS Load Balancer Controller"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP desde Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS desde Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Trafico de salida hacia pods y worker nodes"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name                                           = "${var.project_name}-sg-alb"
    "kubernetes.io/cluster/${var.project_name}-cluster" = "shared"
  }
}

# 2. Security Group para EKS Control Plane
resource "aws_security_group" "eks_cluster" {
  name        = "${var.project_name}-sg-eks-cluster"
  description = "Security Group para el plano de control gestionado de Amazon EKS"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "Salida hacia Worker Nodes y servicios AWS"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name                                           = "${var.project_name}-sg-eks-cluster"
    "kubernetes.io/cluster/${var.project_name}-cluster" = "shared"
  }
}

# 3. Security Group para EKS Worker Nodes y Pods
resource "aws_security_group" "eks_nodes" {
  name        = "${var.project_name}-sg-eks-nodes"
  description = "Security Group para EKS Worker Nodes y Pods de microservicios"
  vpc_id      = aws_vpc.main.id

  # Comunicacion interna nodo a nodo (Pod to Pod)
  ingress {
    description = "Comunicacion interna Pod-to-Pod entre worker nodes"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # Comunicacion desde Control Plane
  ingress {
    description     = "Control Plane a Worker Nodes (API kubelet y webhooks)"
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
  }

  ingress {
    description     = "Control Plane a Worker Nodes HTTPS"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
  }

  # Trafico entrante desde ALB Ingress
  ingress {
    description     = "Trafico HTTP Frontend desde ALB Ingress"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "Trafico APIs Microservicios desde ALB Ingress (3001-3004)"
    from_port       = 3001
    to_port         = 3004
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "Rango NodePort de Kubernetes para balanceo"
    from_port       = 30000
    to_port         = 32767
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Salida total a traves de NAT Gateway (ECR, RDS, CloudWatch, Internet)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name                                           = "${var.project_name}-sg-eks-nodes"
    "kubernetes.io/cluster/${var.project_name}-cluster" = "owned"
  }
}

# Regla de ingreso al cluster desde los worker nodes
resource "aws_security_group_rule" "cluster_ingress_workstation_https" {
  description              = "Permitir comunicacion HTTPS de los worker nodes hacia el control plane EKS"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_nodes.id
}

# 4. Security Group para Amazon RDS MySQL Multi-AZ
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-sg-rds"
  description = "Security Group para Amazon RDS MySQL Multi-AZ (Capa de Datos Privada)"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Acceso MySQL (3306) exclusivamente desde Worker Nodes / Pods de EKS"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  egress {
    description = "Salida restringida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-rds"
  }
}
