# ==============================================================================
# Amazon EKS (Elastic Kubernetes Service) - Cluster y Node Group Multi-AZ
# Evaluacion EA2 / ARY1102 - Arquitectura Cloud
# ==============================================================================

# 1. Cluster EKS Administrado
resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-cluster"
  role_arn = data.aws_iam_role.lab_role.arn
  version  = var.eks_version

  vpc_config {
    subnet_ids              = concat(aws_subnet.public[*].id, aws_subnet.private_app[*].id)
    security_group_ids      = [aws_security_group.eks_cluster.id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  tags = {
    Name = "${var.project_name}-eks-cluster"
  }
}

# 2. EKS Managed Node Group (Worker Nodes en Subredes Privadas Multi-AZ)
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-node-group"
  node_role_arn   = data.aws_iam_role.lab_role.arn
  subnet_ids      = aws_subnet.private_app[*].id

  scaling_config {
    desired_size = var.eks_node_desired_size
    min_size     = var.eks_node_min_size
    max_size     = var.eks_node_max_size
  }

  instance_types = [var.eks_node_instance_type]
  ami_type       = var.eks_ami_type
  capacity_type  = "ON_DEMAND"
  disk_size      = 20

  labels = {
    role        = "worker"
    app         = var.project_name
    environment = "production"
  }

  tags = {
    Name                                           = "${var.project_name}-worker-node"
    "kubernetes.io/cluster/${var.project_name}-cluster" = "owned"
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_eks_cluster.main
  ]
}
