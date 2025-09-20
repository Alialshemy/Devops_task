##################################################  Networking #########################################################################
module "vpc" {
  for_each                 = { for vpc in var.vpcs : vpc.name => vpc }
  source                   = "../modules/vpc"
  vpc_cidr                 = each.value.vpc_cidr
  public_subnets_cidr      = each.value.public_subnets_cidr
  private_subnets_cidr     = each.value.private_subnets_cidr
  create_nate_gateway      = each.value.create_nate_gateway
  vpc_name                 = each.value.name
  map_public_ip_on_launch  = each.value.map_public_ip_on_launch
  vpc_tags                 = try(each.value.vpc_tags, null)
  igw_tags                 = try(each.value.igw_tags, null)
  public_subnet_tags       = try(each.value.public_subnet_tags, null)
  private_subnet_tags      = try(each.value.private_subnet_tags, null)
  public_route_table_tags  = try(each.value.public_route_table_tags, null)
  elastic_ips_tags         = try(each.value.elastic_ips_tags, null)
  nat_gateway_tags         = try(each.value.nat_gateway_tags, null)
  private_route_table_tags = try(each.value.private_route_table_tags, null)
  tags                     = try(each.value.tags, null)
}
############################################################## ECR ###########################################################################
module "ecr" {
  for_each = { for idx, val in var.ecr : val => val }
  source   = "../modules/ecr"
  name     = each.value
  tags = {
    "Name" : "${each.value}"
    "Environment" : "${var.Environment}"

  }
}##############################################################  EKS ###########################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.2.0"

  name               = "${local.app}-cluster"
  kubernetes_version = "1.33"
  create             = true
    security_group_tags ={
      "karpenter.sh/discovery" = "questcode-cluster"
    }
  addons = {
    coredns                = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy             = {}
    vpc-cni                = {
      before_compute = true
    }
  }

  endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true

  vpc_id                   = module.vpc["${local.app}"].vpc_id
  subnet_ids               = module.vpc["${local.app}"].private_subnets
  control_plane_subnet_ids = module.vpc["${local.app}"].private_subnets

  eks_managed_node_groups = {
    example = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["m5.xlarge"]
      min_size       = 2
      max_size       = 2
      desired_size   = 2
    }
  }

  tags = {
    Environment = "prod"
    Terraform   = "true"
    
  }

  depends_on = [module.vpc]
}

#####################################################################################  Karpenter ###########################################################################

module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"

  cluster_name = module.eks.cluster_name

  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = {
    Environment = "prod"
    Terraform   = "true"
  }
}

############################################################## Providers ###########################################################################

provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

############################################################## ArgoCD ###########################################################################

resource "helm_release" "argo_cd" {
  name       = "argo-cd"
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "8.3.9"

  create_namespace = true
  wait             = true

  values = [
    <<-EOT
    server:
      service:
        type: ClusterIP
    EOT
  ]
}

resource "kubernetes_manifest" "argocd_root_app" {
  depends_on = [helm_release.argo_cd]

  manifest = {
    "apiVersion" = "argoproj.io/v1alpha1"
    "kind"       = "Application"
    "metadata" = {
      "name"      = "root-app"
      "namespace" = "argocd"
      "finalizers" = ["resources-finalizer.argocd.argoproj.io"]
    }
    "spec" = {
      "project" = "default"
      "source" = {
        "repoURL"        = "https://github.com/Alialshemy/Devops_task.git"
        "targetRevision" = "main"
        "path"           = "apps"
      }
      "destination" = {
        "server"    = "https://kubernetes.default.svc"
        "namespace" = "argocd"
      }
      "syncPolicy" = {
        "automated" = {
          "prune"    = true
          "selfHeal" = true
        }
      }
    }
  }
}
