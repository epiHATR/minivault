#!/bin/bash -e

echo "storage account: $1"
echo "container name: $2"
echo "storage key: $3"

echo "-> Installing dependencies....."
apt-get install -y \
  apt-transport-https \
  build-essential \
  software-properties-common \
  unzip \
  curl \
  jq \
  git \
  less \
  vim \
  ca-certificates 

echo "-> Downloading Vault....."
cd /tmp && {
  curl -sfL -o vault.zip "https://releases.hashicorp.com/vault/1.14.0-rc1/vault_1.14.0-rc1_linux_amd64.zip"
  unzip -qq vault.zip
  sudo mv vault /usr/local/bin/vault
  sudo chmod +x /usr/local/bin/vault
  rm -rf vault.zip
}

echo "-> Writing profile....."
tee "/etc/profile.d/vault.sh" > /dev/null <<"EOF"
alias vault="vault"
export VAULT_ADDR="http://0.0.0.0:8200"
EOF
. "/etc/profile.d/vault.sh"

echo "-> Writing systemd unit....."
tee "/etc/systemd/system/vault.service" > /dev/null <<"EOF"
[Unit]
Description=Vault Server
Requires=network-online.target
After=network.target

[Service]
Environment=GOMAXPROCS=8
Environment=VAULT_ADDR=http://0.0.0.0:8200
Environment=VAULT_DEV_ROOT_TOKEN_ID=root
Restart=on-failure
ExecStart=/usr/local/bin/vault server -config=/var/lib/vault/config/vault_server_prod.hcl -config=/var/lib/vault/config/vault_server_common.hcl
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT

[Install]
WantedBy=multi-user.target
EOF

echo "Setting Vault server ..."
mkdir -p /var/lib/vault/data
mkdir -p /var/lib/vault/config

tee  "/var/lib/vault/config/vault_server_common.hcl" > /dev/null <<"EOF"
ui            = true
cluster_addr  = "http://0.0.0.0:8201"
api_addr      = "http://0.0.0.0:8200"
disable_mlock = true
log_level     = "Debug"
EOF

storage_account="$1"
storage_container="$2"
storage_key="$3"

tee  "/var/lib/vault/config/vault_server_prod.hcl" > /dev/null <<EOF
storage "azure" {
  accountName = "$storage_account"
  container   = "$storage_container"
  accountKey  = "$storage_key"
  environment = "AzurePublicCloud"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = "true"
}
EOF

echo "-> Starting vault....."
systemctl enable vault
systemctl start vault