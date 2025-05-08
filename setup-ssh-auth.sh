#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Setting up SSH authentication with Vault...${NC}"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if required packages are installed
if ! command_exists vault; then
    echo -e "${YELLOW}Installing Vault...${NC}"
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update && sudo apt install vault
fi

# Install required packages
echo -e "${YELLOW}Installing required packages...${NC}"
sudo apt-get update
sudo apt-get install -y libpam0g-dev libssl-dev

# Create Vault SSH helper directory
echo -e "${YELLOW}Creating Vault SSH helper directory...${NC}"
sudo mkdir -p /usr/local/bin/vault-ssh-helper

# Download and compile Vault SSH helper
echo -e "${YELLOW}Downloading and compiling Vault SSH helper...${NC}"
cd /tmp
git clone https://github.com/hashicorp/vault-ssh-helper.git
cd vault-ssh-helper
make
sudo cp bin/vault-ssh-helper /usr/local/bin/

# Create Vault SSH helper configuration
echo -e "${YELLOW}Creating Vault SSH helper configuration...${NC}"
sudo tee /etc/vault-ssh-helper.d/config.hcl << EOF
vault_addr = "http://localhost:8200"
ssh_mount_point = "ssh"
tls_skip_verify = true
allowed_roles = "*"
EOF

# Configure PAM
echo -e "${YELLOW}Configuring PAM...${NC}"
sudo tee /etc/pam.d/sshd << EOF
# PAM configuration for the Secure Shell service

# Standard Un*x authentication.
@include common-auth

# Disallow non-root logins when /etc/nologin exists.
account    required     pam_nologin.so

# Uncomment and edit /etc/security/access.conf if you need to set complex
# access limits that are hard to express in sshd_config.
# account  required     pam_access.so

# Standard Un*x authorization.
@include common-account

# Vault SSH authentication
auth required pam_exec.so quiet expose_authtok /usr/local/bin/vault-ssh-helper -dev -config=/etc/vault-ssh-helper.d/config.hcl
auth required pam_unix.so use_first_pass

# Standard Un*x session setup and teardown.
@include common-session

# Print the message of the day upon successful login.
# This includes a dynamically generated part from /run/motd.dynamic
# and a static (admin-editable) part from /etc/motd.
session    optional     pam_motd.so  motd=/run/motd.dynamic
session    optional     pam_motd.so noupdate

# Print the status of the user's mailbox upon successful login.
session    optional     pam_mail.so standard noenv # [1]

# Set up user limits from /etc/security/limits.conf.
session    required     pam_limits.so

# Read environment variables from /etc/environment and
# /etc/security/pam_env.conf.
session    required     pam_env.so # [1]
# In Debian 4.0 (etch), locale-related environment variables were moved to
# /etc/default/locale, so read that as well.
session    required     pam_env.so user_readenv=1 envfile=/etc/default/locale

# Standard Un*x password updating.
@include common-password
EOF

# Configure SSH
echo -e "${YELLOW}Configuring SSH...${NC}"
sudo tee -a /etc/ssh/sshd_config << EOF

# Vault SSH Configuration
PubkeyAuthentication yes
PasswordAuthentication yes
ChallengeResponseAuthentication yes
UsePAM yes
EOF

# Restart SSH service
echo -e "${YELLOW}Restarting SSH service...${NC}"
sudo systemctl restart sshd

echo -e "${GREEN}SSH authentication setup complete!${NC}"
echo -e "${YELLOW}Now you need to configure Vault's SSH secrets engine.${NC}"
echo -e "${YELLOW}Run these commands in your Vault container:${NC}"
echo -e "${YELLOW}1. vault secrets enable ssh${NC}"
echo -e "${YELLOW}2. vault write ssh/roles/otp_key_role key_type=otp default_user=ubuntu cidr_list=0.0.0.0/0${NC}"
echo -e "${YELLOW}3. vault write ssh/creds/otp_key_role ip=<target-ip>${NC}" 