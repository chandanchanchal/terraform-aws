# AWS Provider Configuration
provider "aws" {
  region = "us-east-1"
}

# IAM Role for EKS
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# IAM Policy Attachment for EKS Cluster Role
resource "aws_iam_role_policy_attachment" "eks_cluster_role_attachment" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# IAM Role for EKS Worker Nodes
resource "aws_iam_role" "eks_worker_node_role" {
  name = "eks-worker-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# IAM Policy Attachments for Worker Nodes
resource "aws_iam_role_policy_attachment" "eks_worker_node_role_attachment" {
  role       = aws_iam_role.eks_worker_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy_attachment" {
  role       = aws_iam_role.eks_worker_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSCNIPolicy"
}

# EKS Cluster
resource "aws_eks_cluster" "my_eks_cluster" {
  name     = "my-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [aws_subnet.my_subnet_1.id, aws_subnet.my_subnet_2.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_role_attachment
  ]
}

# EKS Node Group (Worker Nodes)
resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.my_eks_cluster.name
  node_group_name = "my-node-group"
  node_role_arn   = aws_iam_role.eks_worker_node_role.arn
  subnet_ids      = [aws_subnet.my_subnet_1.id, aws_subnet.my_subnet_2.id]
  instance_types  = ["t3.medium"]
  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }
}

# Kubernetes Provider Configuration
provider "kubernetes" {
  host                   = aws_eks_cluster.my_eks_cluster.endpoint
  token                  = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate = base64decode(aws_eks_cluster.my_eks_cluster.certificate_authority[0].data)
}

# Deploy Voting Application to EKS
resource "kubernetes_deployment" "voting_app" {
  metadata {
    name = "voting-app"
    labels = {
      app = "voting"
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "voting"
      }
    }
    template {
      metadata {
        labels = {
          app = "voting"
        }
      }
      spec {
        container {
          name  = "voting-app"
          image = "example/voting-app:latest"
          ports {
            container_port = 80
          }
        }
      }
    }
  }
}

# Kubernetes Service for Voting Application
resource "kubernetes_service" "voting_app_service" {
  metadata {
    name = "voting-app-service"
    labels = {
      app = "voting"
    }
  }

  spec {
    selector = {
      app = "voting"
    }
    type = "LoadBalancer"
    ports {
      port        = 80
      target_port = 80
    }
  }
}
