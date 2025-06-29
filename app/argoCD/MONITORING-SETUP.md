# ArgoCD Full Monitoring Setup

## 📊 What You'll Get

Your ArgoCD now has **full monitoring** enabled with metrics for:
- **Application Controller** - Manages your apps (Port 8082)
- **Server** - Web UI and API (Port 8083)  
- **Repository Server** - Git operations (Port 8084)
- **Dex** - Authentication (Port 5558)
- **Redis** - Cache and data (Redis exporter)
- **HAProxy** - Load balancer for Redis

## 🎯 Monitoring Stack Options

### Option 1: Prometheus + Grafana (Recommended)

**Deploy Prometheus Stack:**
```bash
# Add Prometheus community helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create monitoring namespace
kubectl create namespace monitoring

# Install Prometheus Stack (includes Grafana)
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set grafana.adminPassword=admin123
```

**Access Grafana:**
```bash
# Port forward to Grafana
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80

# Open: http://localhost:3000
# Username: admin
# Password: admin123
```

### Option 2: Azure Monitor (Azure Native)

**Enable Container Insights:**
```bash
# In Azure Portal: Your AKS cluster > Monitoring > Insights > Enable
# OR via CLI:
az aks enable-addons -a monitoring -n nexus-cluster -g Nexus
```

**Setup Log Analytics:**
- ArgoCD metrics will be automatically collected
- View in Azure Portal > Monitor > Metrics
- Create custom dashboards

## 📈 ArgoCD Grafana Dashboards

**Import these dashboard IDs in Grafana:**

1. **ArgoCD Operational** - Dashboard ID: `14584`
   - Application sync status
   - Controller performance
   - Resource usage

2. **ArgoCD Application** - Dashboard ID: `19974`  
   - Per-application metrics
   - Deployment history
   - Health status

3. **Redis** - Dashboard ID: `763`
   - Redis performance
   - Memory usage
   - Command statistics

**How to Import:**
1. Grafana > "+" > Import
2. Enter dashboard ID
3. Select Prometheus data source
4. Import

## 🔍 Key Metrics to Monitor

### Application Controller
```
# Sync operations per second
rate(argocd_app_sync_total[5m])

# Applications out of sync
argocd_app_health_status{health_status!="Healthy"}

# Controller memory usage
container_memory_usage_bytes{pod=~"argocd-application-controller.*"}
```

### Server Performance
```
# API request rate
rate(argocd_server_api_requests_total[5m])

# Login attempts
rate(argocd_server_login_attempts_total[5m])

# Active users
argocd_server_connected_users
```

### Repository Server
```
# Git operations rate
rate(argocd_git_request_total[5m])

# Git operation duration
histogram_quantile(0.95, argocd_git_request_duration_seconds_bucket)

# Repository health
argocd_repo_connection_status
```

## 🚨 Alerting Rules

**Create these alerts in Prometheus:**

### Critical Alerts
```yaml
# ArgoCD Application Controller Down
- alert: ArgoCDControllerDown
  expr: up{job="argocd-application-controller-metrics"} == 0
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "ArgoCD Application Controller is down"

# Applications Out of Sync
- alert: ArgoCDAppsOutOfSync
  expr: argocd_app_sync_total{phase!="Succeeded"} > 0
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: "ArgoCD applications are out of sync"

# High Memory Usage
- alert: ArgoCDHighMemoryUsage
  expr: container_memory_usage_bytes{pod=~"argocd.*"} / container_spec_memory_limit_bytes > 0.8
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "ArgoCD component using high memory"
```

## 🔧 Manual Metrics Access

**Without Prometheus, you can access metrics directly:**

```bash
# Controller metrics
kubectl port-forward -n argocd svc/argocd-application-controller-metrics 8082:8082
curl http://localhost:8082/metrics

# Server metrics  
kubectl port-forward -n argocd svc/argocd-server-metrics 8083:8083
curl http://localhost:8083/metrics

# Repository server metrics
kubectl port-forward -n argocd svc/argocd-repo-server-metrics 8084:8084
curl http://localhost:8084/metrics

# Dex metrics
kubectl port-forward -n argocd svc/argocd-dex-server-metrics 5558:5558
curl http://localhost:5558/metrics
```

## 📊 Quick Health Check

**Check ArgoCD health:**
```bash
# All ArgoCD pods
kubectl get pods -n argocd

# Resource usage
kubectl top pods -n argocd

# Service status
kubectl get svc -n argocd

# Application status
kubectl get applications -n argocd
```

## 🐛 Troubleshooting Monitoring

### ServiceMonitor Not Working
```bash
# Check if Prometheus Operator is installed
kubectl get crd servicemonitors.monitoring.coreos.com

# Check ServiceMonitor creation
kubectl get servicemonitor -n argocd

# Check Prometheus targets
# Grafana > Prometheus > Status > Targets
```

### Metrics Not Appearing
```bash
# Verify metrics endpoints
kubectl get endpoints -n argocd | grep metrics

# Check pod annotations
kubectl describe pod argocd-server-xxx -n argocd | grep prometheus

# Test metrics endpoint
kubectl exec -n argocd argocd-server-xxx -- curl localhost:8083/metrics
```

### High Resource Usage
```bash
# Check resource limits
kubectl describe pod argocd-application-controller-xxx -n argocd

# Monitor resource usage over time
kubectl top pod argocd-application-controller-xxx -n argocd --use-protocol-buffers
```

## 🎯 Monitoring Checklist

**After ArgoCD deployment:**

✅ **Deploy Prometheus Stack**
```bash
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring
```

✅ **Verify ServiceMonitors**
```bash
kubectl get servicemonitor -n argocd
```

✅ **Import Grafana Dashboards**
- ArgoCD Operational (14584)
- ArgoCD Application (19974)
- Redis (763)

✅ **Setup Alerts**
- Controller down
- Apps out of sync
- High resource usage

✅ **Test Monitoring**
- Deploy a test application
- Check metrics in Grafana
- Verify alerts trigger

This gives you enterprise-level observability for your ArgoCD POC!
