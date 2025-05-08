#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Setting up Vault for network device access management...${NC}"

# Function to check if Vault is initialized and unsealed
check_vault_status() {
    if ! vault-status | grep -q "Sealed.*false"; then
        echo -e "${RED}Error: Vault is not unsealed${NC}"
        exit 1
    fi
}

# Enable the KV secrets engine for network devices
echo -e "${YELLOW}Enabling KV secrets engine...${NC}"
vault secrets enable -version=2 -path=network-devices kv

# Create policies for device access
echo -e "${YELLOW}Creating access policies...${NC}"

# Cisco policy
cat > cisco-policy.hcl << EOF
path "network-devices/data/cisco/*" {
  capabilities = ["read", "list"]
}

path "network-devices/metadata/cisco/*" {
  capabilities = ["read", "list"]
}
EOF

# Palo Alto policy
cat > paloalto-policy.hcl << EOF
path "network-devices/data/paloalto/*" {
  capabilities = ["read", "list"]
}

path "network-devices/metadata/paloalto/*" {
  capabilities = ["read", "list"]
}
EOF

# Write policies
vault policy write cisco-access cisco-policy.hcl
vault policy write paloalto-access paloalto-policy.hcl

# Create roles for device access
echo -e "${YELLOW}Creating access roles...${NC}"
vault write auth/userpass/users/network-admin \
    password="changeme" \
    policies="cisco-access,paloalto-access"

# Create a script to manage device credentials
echo -e "${YELLOW}Creating device management script...${NC}"
cat > manage-devices.sh << 'EOF'
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
    echo "  add    - Add a new device"
    echo "  get    - Get credentials for a device"
    echo "  list   - List all devices"
    echo "  update - Update device credentials"
    echo "  delete - Delete a device"
    echo ""
    echo "Device Types:"
    echo "  cisco     - Cisco devices"
    echo "  paloalto  - Palo Alto Networks devices"
    exit 1
}

# Function to add a new device
add_device() {
    if [ $# -ne 5 ]; then
        echo -e "${RED}Error: Invalid number of arguments${NC}"
        echo "Usage: $0 add <device-type> <device-name> <username> <password>"
        exit 1
    fi
    
    device_type=$1
    device_name=$2
    username=$3
    password=$4
    
    # Validate device type
    if [[ "$device_type" != "cisco" && "$device_type" != "paloalto" ]]; then
        echo -e "${RED}Error: Invalid device type. Use 'cisco' or 'paloalto'${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Adding $device_type device: $device_name${NC}"
    vault kv put network-devices/$device_type/$device_name username=$username password=$password
    echo -e "${GREEN}Device added successfully${NC}"
}

# Function to get device credentials
get_device() {
    if [ $# -ne 2 ]; then
        echo -e "${RED}Error: Invalid number of arguments${NC}"
        echo "Usage: $0 get <device-type> <device-name>"
        exit 1
    fi
    
    device_type=$1
    device_name=$2
    
    # Validate device type
    if [[ "$device_type" != "cisco" && "$device_type" != "paloalto" ]]; then
        echo -e "${RED}Error: Invalid device type. Use 'cisco' or 'paloalto'${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Retrieving credentials for $device_type device: $device_name${NC}"
    vault kv get network-devices/$device_type/$device_name
}

# Function to list all devices
list_devices() {
    if [ $# -ne 1 ]; then
        echo -e "${RED}Error: Device type required${NC}"
        echo "Usage: $0 list <device-type>"
        exit 1
    fi
    
    device_type=$1
    
    # Validate device type
    if [[ "$device_type" != "cisco" && "$device_type" != "paloalto" ]]; then
        echo -e "${RED}Error: Invalid device type. Use 'cisco' or 'paloalto'${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Listing all $device_type devices:${NC}"
    vault kv list network-devices/$device_type/
}

# Function to update device credentials
update_device() {
    if [ $# -ne 5 ]; then
        echo -e "${RED}Error: Invalid number of arguments${NC}"
        echo "Usage: $0 update <device-type> <device-name> <username> <password>"
        exit 1
    fi
    
    device_type=$1
    device_name=$2
    username=$3
    password=$4
    
    # Validate device type
    if [[ "$device_type" != "cisco" && "$device_type" != "paloalto" ]]; then
        echo -e "${RED}Error: Invalid device type. Use 'cisco' or 'paloalto'${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Updating $device_type device: $device_name${NC}"
    vault kv put network-devices/$device_type/$device_name username=$username password=$password
    echo -e "${GREEN}Device updated successfully${NC}"
}

# Function to delete a device
delete_device() {
    if [ $# -ne 2 ]; then
        echo -e "${RED}Error: Invalid number of arguments${NC}"
        echo "Usage: $0 delete <device-type> <device-name>"
        exit 1
    fi
    
    device_type=$1
    device_name=$2
    
    # Validate device type
    if [[ "$device_type" != "cisco" && "$device_type" != "paloalto" ]]; then
        echo -e "${RED}Error: Invalid device type. Use 'cisco' or 'paloalto'${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Deleting $device_type device: $device_name${NC}"
    vault kv delete network-devices/$device_type/$device_name
    echo -e "${GREEN}Device deleted successfully${NC}"
}

# Main command processing
case "$1" in
    add)
        add_device "$2" "$3" "$4" "$5"
        ;;
    get)
        get_device "$2" "$3"
        ;;
    list)
        list_devices "$2"
        ;;
    update)
        update_device "$2" "$3" "$4" "$5"
        ;;
    delete)
        delete_device "$2" "$3"
        ;;
    *)
        usage
        ;;
esac
EOF

chmod +x manage-devices.sh

# Create a script to connect to devices
echo -e "${YELLOW}Creating connection script...${NC}"
cat > connect-device.sh << 'EOF'
#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if device type and name are provided
if [ $# -ne 2 ]; then
    echo -e "${RED}Error: Device type and name required${NC}"
    echo "Usage: $0 <device-type> <device-name>"
    echo "Device types: cisco, paloalto"
    exit 1
fi

device_type=$1
device_name=$2

# Validate device type
if [[ "$device_type" != "cisco" && "$device_type" != "paloalto" ]]; then
    echo -e "${RED}Error: Invalid device type. Use 'cisco' or 'paloalto'${NC}"
    exit 1
fi

# Get credentials from Vault
echo -e "${YELLOW}Retrieving credentials for $device_type device: $device_name...${NC}"
credentials=$(vault kv get -format=json network-devices/$device_type/$device_name)
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

chmod +x connect-device.sh

echo -e "${GREEN}Setup complete!${NC}"
echo -e "${YELLOW}To use the system:${NC}"
echo "1. Add a device: ./manage-devices.sh add <device-type> <device-name> <username> <password>"
echo "   Example: ./manage-devices.sh add cisco switch1 admin password123"
echo "   Example: ./manage-devices.sh add paloalto fw1 admin password123"
echo ""
echo "2. Connect to a device: ./connect-device.sh <device-type> <device-name>"
echo "   Example: ./connect-device.sh cisco switch1"
echo "   Example: ./connect-device.sh paloalto fw1"
echo ""
echo "3. List all devices: ./manage-devices.sh list <device-type>"
echo "   Example: ./manage-devices.sh list cisco"
echo "   Example: ./manage-devices.sh list paloalto"
echo ""
echo -e "${YELLOW}Note: Make sure to change the default password for the network-admin user${NC}"
echo "vault write auth/userpass/users/network-admin password=<new-password>" 