output "egress_pip_id" {
  value = azurerm_public_ip.egress_pip.id
}

output "cluster_subnet_id" {
  value = azurerm_subnet.cluster_subnet.id
}