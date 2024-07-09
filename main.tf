provider "aws" {
  region = "ap-northeast-2"
}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "new_vpc" {
  cidr_block = "10.1.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "new-vpc"
  }
}

resource "aws_subnet" "new_public" {
  count = 2
  vpc_id = aws_vpc.new_vpc.id
  cidr_block = cidrsubnet(aws_vpc.new_vpc.cidr_block, 8, count.index)
  map_public_ip_on_launch = true
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  tags = {
    Name = "new-public-subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "new_gw" {
  vpc_id = aws_vpc.new_vpc.id
  tags = {
    Name = "new-igw"
  }
}

resource "aws_route_table" "new_public" {
  vpc_id = aws_vpc.new_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.new_gw.id
  }
  tags = {
    Name = "new-public-rt"
  }
}

resource "aws_route_table_association" "new_public" {
  count = 2
  subnet_id = aws_subnet.new_public[count.index].id
  route_table_id = aws_route_table.new_public.id
}

resource "aws_iam_role" "new_eks_role" {
  name = "new-eks-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "new_eks_policy_attachment" {
  role = aws_iam_role.new_eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "new_eks_vpc_resource_controller_policy" {
  role = aws_iam_role.new_eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

resource "aws_eks_cluster" "new_hanalink_cluster" {
  name = "new-hanalink-cluster"
  role_arn = aws_iam_role.new_eks_role.arn

  vpc_config {
    subnet_ids = aws_subnet.new_public.*.id
  }

  depends_on = [
    aws_iam_role_policy_attachment.new_eks_policy_attachment,
    aws_iam_role_policy_attachment.new_eks_vpc_resource_controller_policy,
  ]
}

resource "aws_iam_role" "new_node_role" {
  name = "new-eks-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "new_node_policy_attachment" {
  role = aws_iam_role.new_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "new_node_policy_attachment_ecr" {
  role = aws_iam_role.new_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "new_node_policy_attachment_cni" {
  role = aws_iam_role.new_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_eks_node_group" "new_node_group" {
  cluster_name = aws_eks_cluster.new_hanalink_cluster.name
  node_group_name = "new-standard-workers"
  node_role_arn = aws_iam_role.new_node_role.arn
  subnet_ids = aws_subnet.new_public.*.id

  scaling_config {
    desired_size = 3
    max_size = 5
    min_size = 1
  }

  instance_types = ["t3.medium"]

  depends_on = [
    aws_eks_cluster.new_hanalink_cluster,
    aws_iam_role_policy_attachment.new_node_policy_attachment,
    aws_iam_role_policy_attachment.new_node_policy_attachment_ecr,
    aws_iam_role_policy_attachment.new_node_policy_attachment_cni,
  ]
}