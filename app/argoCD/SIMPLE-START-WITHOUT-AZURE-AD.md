# Simple Start Without Azure AD

## 🚀 Quick Start for Testing

If you want to test ArgoCD first without Azure AD complexity, here's a simplified approach:

### Option 1: Local Admin Only (Simplest)

Edit `argocd-dev-values.yaml` and disable Dex:

```yaml
## Dex (OIDC) - Disabled for initial testing
dex:
  enabled: false  # Disable Azure AD for now
```

**Access Method:**
1. Get admin password: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
2. Login with username: `admin` and the password from step 1

### Option 2: Service Principal Authentication (Advanced)

If you prefer to use your existing service principal approach, you can configure ArgoCD to use it for repository access:

```yaml
configs:
  repositories:
    - type: git
      url: https://github.com/your-org/your-repo
      name: your-repo
      project: default
      # Use service principal for Git access
      username: your-service-principal-id
      password: your-service-principal-secret
```

### Option 3: Hybrid Approach

1. **Start with local admin** for initial setup
2. **Add Azure AD later** when you're ready
3. **Keep service principal** for repository access

## 🔄 Migration Path

1. **Deploy with local admin** (dex disabled)
2. **Test ArgoCD functionality** 
3. **Set up Azure AD groups** when ready
4. **Enable Dex** and redeploy
5. **Test Azure AD login**
6. **Disable local admin** for security

## 🛡️ Security Note

**Local admin is fine for:**
- Initial testing and learning
- POC environment
- Small teams with shared access

**Azure AD is recommended for:**
- Production environments
- Team-based access control
- Audit requirements
- Enterprise compliance

Would you like to start with the simple local admin approach first?
