# Vault-based Privileged Access Management (PAM)

A secure Privileged Access Management system built using HashiCorp Vault with etcd as the backend storage. This system provides secure SSH authentication and secrets management for Linux systems.

## Features

- HashiCorp Vault for secrets management
- 3-node etcd cluster for high availability storage
- Docker-based deployment
- SSH authentication integration
- PAM integration for Linux systems
- Automated setup scripts
- Convenient shell aliases

## Prerequisites

- Docker
- Docker Compose
- Debian-based Linux system (for SSH/PAM integration)
- Git
- Make
- Go (for compiling vault-ssh-helper)

## Quick Start

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/vault-pam.git
   cd vault-pam
   ```

2. Initialize the system:
   ```bash
   ./init-vault.sh
   ```

3. Source the aliases (add to your shell config for persistence):
   ```bash
   source vault-aliases.sh
   ```

4. Set up SSH authentication (on target Debian system):
   ```bash
   ./setup-ssh-auth.sh
   ```

## Architecture

```
┌─────────────────┐     ┌─────────────────┐
│                 │     │                 │
│  HashiCorp Vault│◄────┤  etcd Cluster  │
│                 │     │  (3 nodes)      │
└────────┬────────┘     └─────────────────┘
         │
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│                 │     │                 │
│  SSH/PAM        │◄────┤  Linux Systems  │
│  Integration    │     │                 │
└─────────────────┘     └─────────────────┘
```

## Components

### Vault Server
- Manages secrets and authentication
- Provides SSH OTP generation
- Handles access policies

### etcd Cluster
- 3-node consensus cluster
- High availability storage
- Persistent data storage

### SSH/PAM Integration
- Vault SSH helper
- PAM configuration
- One-time password authentication

## Usage

### Basic Vault Operations

1. Check Vault status:
   ```bash
   vault-status
   ```

2. Store a secret:
   ```bash
   vault-kv-put kv/my-secret username=admin password=secret123
   ```

3. Retrieve a secret:
   ```bash
   vault-kv-get kv/my-secret
   ```

### SSH Authentication

1. Enable SSH secrets engine:
   ```bash
   vault secrets enable ssh
   ```

2. Create SSH role:
   ```bash
   vault write ssh/roles/otp_key_role \
       key_type=otp \
       default_user=ubuntu \
       cidr_list=0.0.0.0/0
   ```

3. Generate OTP:
   ```bash
   vault write ssh/creds/otp_key_role ip=<target-ip>
   ```

## Security Considerations

1. **Production Deployment**
   - Enable TLS for all communications
   - Use proper seal configuration
   - Implement proper authentication methods
   - Set up audit logging
   - Configure proper access policies

2. **Key Management**
   - Securely store unseal keys
   - Regularly rotate credentials
   - Implement key backup procedures

3. **Network Security**
   - Restrict access to Vault API
   - Use proper firewall rules
   - Implement network segmentation

## Maintenance

### Backup and Restore

1. Backup etcd data:
   ```bash
   etcd-backup
   ```

2. Restore etcd data:
   ```bash
   etcd-restore
   ```

### Monitoring

1. Check Vault status:
   ```bash
   vault-status
   ```

2. Check etcd cluster health:
   ```bash
   etcd-health
   ```

3. View logs:
   ```bash
   vault-logs
   ```

## Troubleshooting

1. **Vault Issues**
   - Check Vault status: `vault-status`
   - View logs: `vault-logs`
   - Verify etcd connection: `etcd-health`

2. **SSH Authentication Issues**
   - Check PAM configuration
   - Verify Vault SSH helper
   - Check SSH logs

3. **Common Problems**
   - Vault unsealing issues
   - etcd cluster health
   - SSH connection problems

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- HashiCorp Vault
- etcd
- Docker
- Linux PAM 