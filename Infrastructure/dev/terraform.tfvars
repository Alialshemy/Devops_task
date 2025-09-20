region = "us-east-1"
vpcs = [
  {
    vpc_cidr             = "10.80.0.0/16"
    public_subnets_cidr  = ["10.80.0.0/20", "10.80.16.0/20" ]
    private_subnets_cidr = ["10.80.48.0/20", "10.80.64.0/20"]
    create_nate_gateway      = true
    create_vpc_peering_route = false
    map_public_ip_on_launch  = true
    name                     = "questcode"
    tags = {
      "Environment"  = "dev"
      "creator"      = "terrafrom"
      "karpenter.sh/discovery"                  = "questcode-cluster" 
      "kubernetes.io/cluster/questcode-cluster" = "share" 
    }
  }
]
ecr = ["backendapp", "frontendapp"]
Environment = "dev"