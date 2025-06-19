resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.8.3"  # Pinned version for stability
  namespace        = "ingress-nginx"
  create_namespace = true

  values = [
    <<-EOT
    controller:
      replicaCount: 2
      service:
        type: LoadBalancer
        externalTrafficPolicy: Local
        annotations:
          service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path: /healthz
      
      resources:
        requests:
          cpu: 100m
          memory: 128Mi
        limits:
          cpu: 200m
          memory: 256Mi
      
      metrics:
        enabled: true
        serviceMonitor:
          enabled: true
          additionalLabels:
            release: prometheus
      
      autoscaling:
        enabled: true
        minReplicas: 2
        maxReplicas: 5
        targetCPUUtilizationPercentage: 80
      
      config:
        enable-real-ip: "true"
        use-forwarded-headers: "true"
        compute-full-forwarded-for: "true"
        
      allowSnippetAnnotations: false
    EOT
  ]

  depends_on = [
    module.aks
  ]
}

# Get the Ingress Controller IP once it's assigned
data "kubernetes_service" "ingress_nginx" {
  metadata {
    name      = "${helm_release.ingress_nginx.name}-controller"
    namespace = helm_release.ingress_nginx.namespace
  }

  depends_on = [
    helm_release.ingress_nginx
  ]
}

# Deploy cert-manager if enabled
resource "helm_release" "cert_manager" {
  count = var.cert_manager_enabled ? 1 : 0

  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "v1.13.2"
  namespace        = "cert-manager"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  depends_on = [
    helm_release.ingress_nginx
  ]
}

# Create ClusterIssuer for Let's Encrypt if cert-manager is enabled
resource "kubectl_manifest" "cluster_issuer" {
  count = var.cert_manager_enabled ? 1 : 0
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: ${var.cert_email}
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
YAML

  depends_on = [
    helm_release.cert_manager
  ]
}

# Create Ingress Resources for each environment
resource "kubernetes_ingress_v1" "ingresses" {
  for_each = var.ingress_configs

  metadata {
    name      = "${each.key}-ingress"
    namespace = each.value.namespace    annotations = merge(
      {
        "kubernetes.io/ingress.class" = "nginx"
      },
      each.value.allowed_ips != [] ? {
        "nginx.ingress.kubernetes.io/whitelist-source-range" = join(",", each.value.allowed_ips)
      } : {},
      var.cert_manager_enabled && each.value.tls_enabled ? {
        "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
      } : {},
      # Add rewrite target annotations for each path
      { for idx, path in each.value.paths :
        "nginx.ingress.kubernetes.io/rewrite-target${idx == 0 ? "" : "-${idx}"}" => path.rewrite_target
      }
    )
  }
  spec {
    rule {
      host = each.value.hostname
      http {
        dynamic "path" {
          for_each = each.value.paths
          content {
            path      = path.value.path
            path_type = "Prefix"
            backend {
              service {
                name = each.value.service_name
                port {
                  number = each.value.service_port
                }
              }
            }
          }
        }
      }
    }

    dynamic "tls" {
      for_each = each.value.tls_enabled ? [1] : []
      content {
        hosts       = [each.value.hostname]
        secret_name = "${each.key}-tls-cert"
      }
    }
  }

  depends_on = [
    helm_release.ingress_nginx,
    kubectl_manifest.cluster_issuer
  ]
}

# Output the Load Balancer IP
output "ingress_ip" {
  description = "Load Balancer IP of NGINX Ingress Controller"
  value       = data.kubernetes_service.ingress_nginx.status.0.load_balancer.0.ingress.0.ip
}
