// Network

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.62"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_vpc" "k8s_cluster_vpc" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
}

resource "aws_subnet" "k8s_cluster_vpc_public_subnet" {
  count                   = var.public_subnet_count
  cidr_block              = cidrsubnet(aws_vpc.k8s_cluster_vpc.cidr_block, 4, count.index)
  vpc_id                  = aws_vpc.k8s_cluster_vpc.id
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "k8s_cluster_vpc_gw" {
  vpc_id = aws_vpc.k8s_cluster_vpc.id
}

resource "aws_default_route_table" "k8s_cluster_vpc_rt" {
  default_route_table_id = aws_vpc.k8s_cluster_vpc.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k8s_cluster_vpc_gw.id
  }
}

// Kubernetes 

resource "aws_eks_cluster" "k8s_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.k8s_cluster_role.arn

  vpc_config {
    subnet_ids = aws_subnet.k8s_cluster_vpc_public_subnet[*].id
  }
}

resource "aws_eks_node_group" "k8s_cluster_node_group" {
  cluster_name    = aws_eks_cluster.k8s_cluster.name
  node_group_name = "${var.cluster_name}_node_group"
  node_role_arn   = aws_iam_role.k8s_node_group_role.arn
  subnet_ids      = aws_subnet.k8s_cluster_vpc_public_subnet[*].id

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.k8s_node_group_policy_attachment_worker,
    aws_iam_role_policy_attachment.k8s_node_group_policy_attachment_cni,
    aws_iam_role_policy_attachment.k8s_node_group_policy_attachment_registry,
    aws_eks_cluster.k8s_cluster,
  ]
}

provider "kubernetes" {
  host                   = aws_eks_cluster.k8s_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.k8s_cluster.certificate_authority[0]["data"])
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
    command     = "aws"
  }
}

// Roles

resource "aws_iam_role" "k8s_cluster_role" {
  name = "${var.cluster_name}_cluster_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "k8s_cluster_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.k8s_cluster_role.name
}

resource "aws_iam_role" "k8s_node_group_role" {
  name = "${var.cluster_name}_node_group_role"
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "k8s_node_group_policy_attachment_worker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.k8s_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "k8s_node_group_policy_attachment_registry" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.k8s_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "k8s_node_group_policy_attachment_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.k8s_node_group_role.name
}
