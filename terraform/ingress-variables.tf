variable "ingress_configs" {
  description = "Configuration for different ingress resources"
  type = map(object({
    namespace   = string
    hostname    = string
    tls_enabled = bool
    allowed_ips = list(string)
    paths       = list(object({
      path           = string
      rewrite_target = string
      service_name   = string
      service_port   = number
    }))
  }))
  default = {
    dev = {
      namespace   = "dev"
      hostname    = "dev.nexus.local"
      tls_enabled = true
      allowed_ips = ["0.0.0.0/0"]  # Update with your allowed IPs
      paths = [
        {
          path           = "/"
          rewrite_target = "/"
          service_name   = "frontend-service"
          service_port   = 80
        },
        {
          path           = "/api"
          rewrite_target = "/"  # If your API expects requests at root
          service_name   = "api-service"
          service_port   = 8080
        }
      ]
    },
    staging = {
      namespace   = "staging"
      hostname    = "staging.nexus.local"
      tls_enabled = true
      allowed_ips = []  # Update with your allowed IPs
      paths = [
        {
          path           = "/"
          rewrite_target = "/"
          service_name   = "frontend-service"
          service_port   = 80
        }
      ]
    },
    prod = {
      namespace   = "production"
      hostname    = "nexus.local"
      tls_enabled = true
      allowed_ips = []  # Update with your allowed IPs
      paths = [
        {
          path           = "/"
          rewrite_target = "/"
          service_name   = "frontend-service"
          service_port   = 80
        }
      ]
    }
  }
}

variable "cert_manager_enabled" {
  description = "Whether to enable cert-manager integration"
  type        = bool
  default     = true
}

variable "cert_email" {
  description = "Email address for Let's Encrypt notifications"
  type        = string
  default     = "admin@nexus.local"  # Update with your email
}
