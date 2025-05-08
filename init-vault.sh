#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting Vault initialization process...${NC}"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if docker and docker-compose are installed
if ! command_exists docker; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    exit 1
fi

if ! command_exists docker-compose; then
    echo -e "${RED}Error: Docker Compose is not installed${NC}"
    exit 1
fi

# Create required directories
echo -e "${YELLOW}Creating required directories...${NC}"
mkdir -p vault/config

# Start the services
echo -e "${YELLOW}Starting services...${NC}"
docker-compose up -d

# Wait for services to be ready
echo -e "${YELLOW}Waiting for services to be ready...${NC}"
sleep 30

# Initialize Vault
echo -e "${YELLOW}Initializing Vault...${NC}"
INIT_RESPONSE=$(docker exec -it vault vault operator init -format=json)

# Extract unseal keys and root token
UNSEAL_KEY_1=$(echo $INIT_RESPONSE | jq -r '.unseal_keys_b64[0]')
UNSEAL_KEY_2=$(echo $INIT_RESPONSE | jq -r '.unseal_keys_b64[1]')
UNSEAL_KEY_3=$(echo $INIT_RESPONSE | jq -r '.unseal_keys_b64[2]')
ROOT_TOKEN=$(echo $INIT_RESPONSE | jq -r '.root_token')

# Save keys to a file
echo -e "${YELLOW}Saving keys to vault-keys.txt...${NC}"
cat > vault-keys.txt << EOL
=== VAULT KEYS - KEEP THESE SAFE ===
Unseal Key 1: ${UNSEAL_KEY_1}
Unseal Key 2: ${UNSEAL_KEY_2}
Unseal Key 3: ${UNSEAL_KEY_3}
Root Token: ${ROOT_TOKEN}
EOL

# Unseal Vault
echo -e "${YELLOW}Unsealing Vault...${NC}"
docker exec -it vault vault operator unseal $UNSEAL_KEY_1
docker exec -it vault vault operator unseal $UNSEAL_KEY_2
docker exec -it vault vault operator unseal $UNSEAL_KEY_3

# Login to Vault
echo -e "${YELLOW}Logging into Vault...${NC}"
docker exec -it vault vault login $ROOT_TOKEN

# Enable KV secrets engine
echo -e "${YELLOW}Enabling KV secrets engine...${NC}"
docker exec -it vault vault secrets enable -version=2 kv

# Create a test secret
echo -e "${YELLOW}Creating test secret...${NC}"
docker exec -it vault vault kv put kv/test-secret message="Vault is initialized and working!"

# Verify the secret
echo -e "${YELLOW}Verifying test secret...${NC}"
docker exec -it vault vault kv get kv/test-secret

echo -e "${GREEN}Vault initialization complete!${NC}"
echo -e "${YELLOW}Your keys have been saved to vault-keys.txt${NC}"
echo -e "${YELLOW}You can access the Vault UI at http://localhost:8200${NC}"
echo -e "${YELLOW}To check Vault status, run: docker exec -it vault vault status${NC}"
echo -e "${YELLOW}To check etcd cluster health, run: docker exec -it etcd1 etcdctl cluster-health${NC}" 