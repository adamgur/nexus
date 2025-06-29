# Azure Active Directory Integration Setup

## 🤔 Service Principal vs App Registration - What's the Difference?

**You mentioned using a Service Principal for Azure access. That's different from what ArgoCD needs:**

| Purpose | What You Have | What ArgoCD Needs |
|---------|---------------|-------------------|
| **Service Principal** | ✅ For automation (CI/CD, Terraform, scripts) | ❌ Not for user authentication |
| **App Registration** | ❓ Probably not set up yet | ✅ Required for user login to ArgoCD |
| **Azure AD Groups** | ❓ Probably not set up yet | ✅ Required for role-based access |

**In Simple Terms:**
- Your **Service Principal** = Robot access for automation
- **App Registration** = Allows ArgoCD to authenticate human users
- **Azure AD Groups** = Defines which users get admin vs developer access

## 🏢 Prerequisites

1. **Azure AD Admin Access** - You need to create an App Registration (separate from your service principal)
2. **Azure AD Groups** - Create groups for ArgoCD roles (recommended for team access)

## 📝 Step 1: Create Azure AD App Registration

### 1.1 Create App Registration
```bash
# Via Azure Portal: https://portal.azure.com
# Go to: Azure Active Directory > App registrations > New registration
```

**Settings:**
- **Name**: `ArgoCD-Nexus`
- **Supported account types**: `Accounts in this organizational directory only`
- **Redirect URI**: 
  - Type: `Web`
  - Value: `https://argocd.nexus.local/api/dex/callback`

### 1.2 Get Required Values
After creating the app registration, collect these values:

```bash
# From Overview page
AZURE_TENANT_ID="your-tenant-id"
AZURE_CLIENT_ID="your-client-id"

# From Certificates & secrets > New client secret
AZURE_CLIENT_SECRET="your-client-secret"
```

### 1.3 Configure API Permissions
Add these permissions:
- **Microsoft Graph > User.Read** (Delegated)
- **Microsoft Graph > GroupMember.Read.All** (Delegated)

Then click **"Grant admin consent"**

## 👥 Step 2: Create Azure AD Groups (Recommended)

```bash
# Via Azure Portal: Azure Active Directory > Groups > New group
```

**Create these groups:**
1. **ArgoCD-Admins** - Full access to ArgoCD
2. **ArgoCD-Developers** - Read/sync access to applications

**Get Group Object IDs:**
```bash
# From each group's Overview page, copy the "Object ID"
ADMIN_GROUP_ID="12345678-1234-1234-1234-123456789012"
DEVELOPER_GROUP_ID="87654321-4321-4321-4321-210987654321"
```

## ⚙️ Step 3: Update ArgoCD Configuration

Replace these placeholders in `argocd-dev-values.yaml`:

```yaml
# In the dex.config section
clientID: "YOUR_AZURE_APP_CLIENT_ID"        # Replace with AZURE_CLIENT_ID
clientSecret: "YOUR_AZURE_APP_CLIENT_SECRET" # Replace with AZURE_CLIENT_SECRET
tenant: "YOUR_AZURE_TENANT_ID"              # Replace with AZURE_TENANT_ID

# In the groups section
groups:
  - "12345678-1234-1234-1234-123456789012"  # Replace with ADMIN_GROUP_ID
  - "87654321-4321-4321-4321-210987654321"  # Replace with DEVELOPER_GROUP_ID

# In the RBAC policy.csv section
g, "12345678-1234-1234-1234-123456789012", role:admin      # Replace with ADMIN_GROUP_ID
g, "87654321-4321-4321-4321-210987654321", role:developer  # Replace with DEVELOPER_GROUP_ID
```

## 🚀 Step 4: Deploy ArgoCD

```powershell
# Deploy with Azure AD integration
./deploy-argocd-dev.ps1
```

## 🔐 Step 5: Test Authentication

### 5.1 Access ArgoCD
```bash
# Go to: https://argocd.nexus.local
# You'll see two login options:
# 1. "LOG IN VIA MICROSOFT" (Azure AD)
# 2. "Local admin" (emergency access)
```

### 5.2 Add Users to Groups
```bash
# In Azure Portal: Azure Active Directory > Groups
# Select "ArgoCD-Admins" or "ArgoCD-Developers"
# Add members > Select users
```

## 🔍 Quick Check - What You Need to Get

If you already have access to Azure AD, run these PowerShell commands to get started:

```powershell
# Install Azure AD PowerShell module (if not already installed)
Install-Module AzureAD -Force

# Connect to Azure AD (will prompt for login)
Connect-AzureAD

# Get your tenant information
$tenant = Get-AzureADTenantDetail
Write-Host "Your Azure Tenant ID: $($tenant.ObjectId)"
Write-Host "Your Tenant Domain: $($tenant.VerifiedDomains[0].Name)"

# Check if you have any existing Azure AD groups
$groups = Get-AzureADGroup | Where-Object {$_.DisplayName -like "*ArgoCD*" -or $_.DisplayName -like "*Kubernetes*"}
if ($groups) {
    Write-Host "Existing groups that might be relevant:"
    $groups | Select-Object DisplayName, ObjectId
} else {
    Write-Host "No existing ArgoCD or Kubernetes groups found. You'll need to create them."
}

# Check your current user's admin permissions
$currentUser = Get-AzureADCurrentSessionInfo
Write-Host "You're logged in as: $($currentUser.Account)"
```

**What This Will Tell You:**
- Your Azure Tenant ID (needed for ArgoCD config)
- Whether you have existing groups to use
- Your current access level

## 🛠️ Troubleshooting

### Common Issues

**1. "OIDC login failed"**
```bash
# Check ArgoCD logs
kubectl logs -n argocd deployment/argocd-server

# Common causes:
# - Wrong redirect URI in Azure AD
# - Incorrect client ID/secret
# - Missing API permissions
```

**2. "User authenticated but has no permissions"**
```bash
# Check RBAC configuration
kubectl get configmap argocd-rbac-cm -n argocd -o yaml

# Verify user's groups in Azure AD
# Make sure group Object IDs match the configuration
```

**3. "Cannot access callback URL"**
```bash
# Verify DNS resolution
nslookup argocd.nexus.local

# Check ingress configuration
kubectl get ingress -n argocd
```

## 🔄 Fallback: Emergency Admin Access

If Azure AD login fails, you can still use local admin:

```bash
# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Login at: https://argocd.nexus.local
# Use "Local admin" option
# Username: admin
# Password: (from above command)
```

## 📋 User Experience

**For Admin Users:**
1. Go to https://argocd.nexus.local
2. Click "LOG IN VIA MICROSOFT"
3. Login with Azure AD credentials
4. Full access to all ArgoCD features

**For Developer Users:**
1. Same login process
2. Can view applications
3. Can sync/refresh applications
4. Cannot create/delete applications

## 🔧 Advanced Configuration

### Custom Roles
You can create more granular roles by modifying the RBAC policy:

```yaml
policy.csv: |
  # Read-only role for viewers
  p, role:viewer, applications, get, */*, allow
  p, role:viewer, repositories, get, *, allow
  
  # App-specific permissions
  p, role:app-owner, applications, *, my-namespace/*, allow
  
  # Map to Azure AD groups
  g, "viewer-group-id", role:viewer
  g, "app-owner-group-id", role:app-owner
```

This setup gives you proper enterprise authentication while keeping the configuration simple for your POC!
