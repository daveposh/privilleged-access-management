#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Setting up Vault for Cisco device access management...${NC}"

# Function to check if Vault is initialized and unsealed
check_vault_status() {
    if ! vault-status | grep -q "Sealed.*false"; then
        echo -e "${RED}Error: Vault is not unsealed${NC}"
        exit 1
    fi
}

# Enable the KV secrets engine for Cisco credentials
echo -e "${YELLOW}Enabling KV secrets engine...${NC}"
vault secrets enable -version=2 -path=cisco kv

# Create a policy for Cisco device access
echo -e "${YELLOW}Creating Cisco access policy...${NC}"
cat > cisco-policy.hcl << EOF
path "cisco/data/*" {
  capabilities = ["read", "list"]
}

path "cisco/metadata/*" {
  capabilities = ["read", "list"]
}
EOF

vault policy write cisco-access cisco-policy.hcl

# Create a role for Cisco device access
echo -e "${YELLOW}Creating Cisco access role...${NC}"
vault write auth/userpass/users/cisco-admin \
    password="changeme" \
    policies="cisco-access"

# Create a script to manage Cisco credentials
echo -e "${YELLOW}Creating Cisco credential management script...${NC}"
cat > manage-cisco-creds.sh << 'EOF'
#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to display usage
usage() {
    echo "Usage: $0 [command] [options]"
    echo "Commands:"
    echo "  add    - Add a new Cisco device"
    echo "  get    - Get credentials for a device"
    echo "  list   - List all devices"
    echo "  update - Update device credentials"
    echo "  delete - Delete a device"
    exit 1
}

# Function to add a new device
add_device() {
    if [ $# -ne 4 ]; then
        echo -e "${RED}Error: Invalid number of arguments${NC}"
        echo "Usage: $0 add <device-name> <username> <password>"
        exit 1
    fi
    
    device_name=$1
    username=$2
    password=$3
    
    echo -e "${YELLOW}Adding device: $device_name${NC}"
    vault kv put cisco/$device_name username=$username password=$password
    echo -e "${GREEN}Device added successfully${NC}"
}

# Function to get device credentials
get_device() {
    if [ $# -ne 1 ]; then
        echo -e "${RED}Error: Invalid number of arguments${NC}"
        echo "Usage: $0 get <device-name>"
        exit 1
    fi
    
    device_name=$1
    echo -e "${YELLOW}Retrieving credentials for: $device_name${NC}"
    vault kv get cisco/$device_name
}

# Function to list all devices
list_devices() {
    echo -e "${YELLOW}Listing all devices:${NC}"
    vault kv list cisco/
}

# Function to update device credentials
update_device() {
    if [ $# -ne 4 ]; then
        echo -e "${RED}Error: Invalid number of arguments${NC}"
        echo "Usage: $0 update <device-name> <username> <password>"
        exit 1
    fi
    
    device_name=$1
    username=$2
    password=$3
    
    echo -e "${YELLOW}Updating device: $device_name${NC}"
    vault kv put cisco/$device_name username=$username password=$password
    echo -e "${GREEN}Device updated successfully${NC}"
}

# Function to delete a device
delete_device() {
    if [ $# -ne 1 ]; then
        echo -e "${RED}Error: Invalid number of arguments${NC}"
        echo "Usage: $0 delete <device-name>"
        exit 1
    fi
    
    device_name=$1
    echo -e "${YELLOW}Deleting device: $device_name${NC}"
    vault kv delete cisco/$device_name
    echo -e "${GREEN}Device deleted successfully${NC}"
}

# Main command processing
case "$1" in
    add)
        add_device "$2" "$3" "$4"
        ;;
    get)
        get_device "$2"
        ;;
    list)
        list_devices
        ;;
    update)
        update_device "$2" "$3" "$4"
        ;;
    delete)
        delete_device "$2"
        ;;
    *)
        usage
        ;;
esac
EOF

chmod +x manage-cisco-creds.sh

# Create a script to connect to Cisco devices
echo -e "${YELLOW}Creating Cisco connection script...${NC}"
cat > connect-cisco.sh << 'EOF'
#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if device name is provided
if [ $# -ne 1 ]; then
    echo -e "${RED}Error: Device name required${NC}"
    echo "Usage: $0 <device-name>"
    exit 1
fi

device_name=$1

# Get credentials from Vault
echo -e "${YELLOW}Retrieving credentials for $device_name...${NC}"
credentials=$(vault kv get -format=json cisco/$device_name)
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to retrieve credentials${NC}"
    exit 1
fi

# Extract username and password
username=$(echo $credentials | jq -r '.data.data.username')
password=$(echo $credentials | jq -r '.data.data.password')

# Connect to the device using SSH
echo -e "${YELLOW}Connecting to $device_name...${NC}"
sshpass -p "$password" ssh -o StrictHostKeyChecking=no $username@$device_name
EOF

chmod +x connect-cisco.sh

echo -e "${GREEN}Setup complete!${NC}"
echo -e "${YELLOW}To use the system:${NC}"
echo "1. Add a device: ./manage-cisco-creds.sh add <device-name> <username> <password>"
echo "2. Connect to a device: ./connect-cisco.sh <device-name>"
echo "3. List all devices: ./manage-cisco-creds.sh list"
echo ""
echo -e "${YELLOW}Note: Make sure to change the default password for the cisco-admin user${NC}"
echo "vault write auth/userpass/users/cisco-admin password=<new-password>" 