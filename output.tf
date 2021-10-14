output "k8s_cluster_vpc" {
  value = aws_vpc.k8s_cluster_vpc
}

output "k8s_cluster_vpc_public_subnet" {
  value = aws_subnet.k8s_cluster_vpc_public_subnet
}

output "k8s_cluster_vpc_gw" {
  value = aws_internet_gateway.k8s_cluster_vpc_gw
}

output "k8s_cluster_vpc_rt" {
  value = aws_default_route_table.k8s_cluster_vpc_rt
}
