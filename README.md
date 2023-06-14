# Minivault Terraform
For deploying HCP Vault on Azure using Terraform, this template support 2 different deployment kind:
- On Azure Kubernetes AKS cluster
- On a single Azure Virtual Machine

# Prerequisites
- Terraform 1.3+
- azure cli 2.2+

# 1. HCP Vault Server in Azure VM
Follow this instruction to start creating your HCP Vault server on Azure VM.
Download this repository
```bash
git clone https://github.com/epiHATR/minivault
```
Run Terraform command
```bash
cd single-vm
terraform init
terraform plan
terraform apply
```
#### Note
After ```terraform apply``` completed, let grab VM SSH private key and access to the VM by
```bash
terraform output tls_private_key > ssh_key.pem
chmod 600 ssh_key.pem
ssh -i ssh_key.pem azureuser@<ipaddress of VM>
```

Then run ```vault operator init``` to grab ```unseal keys``` and ```initial root token```

# 2. HCP Vault Server in AKS