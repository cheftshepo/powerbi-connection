#!/usr/bin/env bash
# lib_sp.sh — source this, then call load_sp_creds
# Sets SP_CLIENT_ID, SP_CLIENT_SECRET, SP_TENANT_ID in the current shell.

load_sp_creds() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local local_creds="$script_dir/sp_creds.local.env"

  if [ -f "$local_creds" ]; then
    source "$local_creds"
    echo "Loaded SP creds from sp_creds.local.env — client id: ${SP_CLIENT_ID:0:8}..."
    return
  fi

  : "${KEY_VAULT_NAME:?Set in config.env}"
  : "${KV_SECRET_NAME_CLIENT_ID:?Run 00_list_keyvault_secrets.sh and fill into config.env}"
  : "${KV_SECRET_NAME_CLIENT_SECRET:?Run 00_list_keyvault_secrets.sh and fill into config.env}"
  : "${KV_SECRET_NAME_TENANT_ID:?Run 00_list_keyvault_secrets.sh and fill into config.env}"

  SP_CLIENT_ID=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "$KV_SECRET_NAME_CLIENT_ID" --query value -o tsv)
  SP_CLIENT_SECRET=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "$KV_SECRET_NAME_CLIENT_SECRET" --query value -o tsv)
  SP_TENANT_ID=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "$KV_SECRET_NAME_TENANT_ID" --query value -o tsv)

  echo "Loaded SP creds from Key Vault — client id: ${SP_CLIENT_ID:0:8}... | secret retrieved: $([ -n "$SP_CLIENT_SECRET" ] && echo yes || echo no)"
}
