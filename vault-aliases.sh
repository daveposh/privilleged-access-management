#!/bin/bash

# Vault Status and Health
alias vault-status='docker exec -it vault vault status'
alias vault-health='docker exec -it vault vault operator health'
alias etcd-health='docker exec -it etcd1 etcdctl cluster-health'

# Vault Authentication
alias vault-login='docker exec -it vault vault login'
alias vault-unseal='docker exec -it vault vault operator unseal'

# Vault Secrets Management
alias vault-list='docker exec -it vault vault secrets list'
alias vault-enable='docker exec -it vault vault secrets enable'
alias vault-disable='docker exec -it vault vault secrets disable'

# KV Secrets Engine Operations
alias vault-kv-put='docker exec -it vault vault kv put'
alias vault-kv-get='docker exec -it vault kv get'
alias vault-kv-delete='docker exec -it vault vault kv delete'
alias vault-kv-list='docker exec -it vault vault kv list'

# Vault Policies
alias vault-policy-list='docker exec -it vault vault policy list'
alias vault-policy-read='docker exec -it vault vault policy read'
alias vault-policy-write='docker exec -it vault vault policy write'

# Vault Audit
alias vault-audit-list='docker exec -it vault vault audit list'
alias vault-audit-enable='docker exec -it vault vault audit enable'
alias vault-audit-disable='docker exec -it vault vault audit disable'

# Vault Auth Methods
alias vault-auth-list='docker exec -it vault vault auth list'
alias vault-auth-enable='docker exec -it vault vault auth enable'
alias vault-auth-disable='docker exec -it vault vault auth disable'

# Container Management
alias vault-restart='docker-compose restart vault'
alias vault-logs='docker-compose logs -f vault'
alias vault-stop='docker-compose stop vault'
alias vault-start='docker-compose start vault'

# etcd Operations
alias etcd-status='docker exec -it etcd1 etcdctl member list'
alias etcd-backup='docker exec -it etcd1 etcdctl snapshot save /etcd-data/backup.db'
alias etcd-restore='docker exec -it etcd1 etcdctl snapshot restore /etcd-data/backup.db'

# Quick Access to Vault UI
alias vault-ui='open http://localhost:8200'

# Helper Functions
vault-init() {
    ./init-vault.sh
}

vault-seal() {
    docker exec -it vault vault operator seal
}

vault-unseal-all() {
    if [ -f vault-keys.txt ]; then
        echo "Unsealing Vault with saved keys..."
        KEY1=$(grep "Unseal Key 1" vault-keys.txt | cut -d':' -f2 | tr -d ' ')
        KEY2=$(grep "Unseal Key 2" vault-keys.txt | cut -d':' -f2 | tr -d ' ')
        KEY3=$(grep "Unseal Key 3" vault-keys.txt | cut -d':' -f2 | tr -d ' ')
        vault-unseal $KEY1
        vault-unseal $KEY2
        vault-unseal $KEY3
    else
        echo "Error: vault-keys.txt not found"
    fi
}

# Print available commands
vault-help() {
    echo "Available Vault Commands:"
    echo "  Status and Health:"
    echo "    vault-status    - Check Vault status"
    echo "    vault-health    - Check Vault health"
    echo "    etcd-health     - Check etcd cluster health"
    echo ""
    echo "  Authentication:"
    echo "    vault-login     - Login to Vault"
    echo "    vault-unseal    - Unseal Vault"
    echo "    vault-seal      - Seal Vault"
    echo "    vault-unseal-all - Unseal Vault using saved keys"
    echo ""
    echo "  Secrets Management:"
    echo "    vault-kv-put    - Store a secret"
    echo "    vault-kv-get    - Retrieve a secret"
    echo "    vault-kv-delete - Delete a secret"
    echo "    vault-kv-list   - List secrets"
    echo ""
    echo "  Container Management:"
    echo "    vault-restart   - Restart Vault container"
    echo "    vault-logs      - View Vault logs"
    echo "    vault-stop      - Stop Vault container"
    echo "    vault-start     - Start Vault container"
    echo ""
    echo "  UI Access:"
    echo "    vault-ui        - Open Vault UI in browser"
    echo ""
    echo "  Help:"
    echo "    vault-help      - Show this help message"
} 