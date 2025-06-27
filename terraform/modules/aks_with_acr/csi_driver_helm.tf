resource "helm_release" "csi_secrets_store_provider" {
  provider  = helm
  name       = "secrets-store-csi-driver-provider-azure"
  repository = "https://azure.github.io/secrets-store-csi-driver-provider-azure/charts"
  chart      = "csi-secrets-store-provider-azure"
  namespace  = "kube-system"
  version    = "1.4.0" # Specify a stable version

  set = [
    {
      name  = "secrets-store-csi-driver.syncSecret.enabled"
      value = "true"
    },
    {
      name  = "secrets-store-csi-driver.enableSecretRotation"
      value = "true"
    },
    {
      name  = "rbac.enabled"
      value = "true"
    }
  ]
}