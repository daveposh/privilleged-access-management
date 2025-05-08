storage "etcd" {
  address = "http://etcd1:2379,http://etcd2:2379,http://etcd3:2379"
  etcd_api = "v3"
  ha_enabled = "true"
}

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = 1  # Note: In production, you should enable TLS
}

api_addr = "http://0.0.0.0:8200"
cluster_addr = "https://0.0.0.0:8201"

ui = true

# Seal configuration (for production, you should use a proper seal)
seal "transit" {
  address = "http://127.0.0.1:8200"
  token = "s.xxxxxxxxxxxxxxxxxxxx"  # Replace with your actual token
  disable_renewal = "false"
  key_name = "autounseal"
  mount_path = "transit/"
  tls_skip_verify = "true"
} 