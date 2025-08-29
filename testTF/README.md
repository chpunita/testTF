RBAC Audit Script (PowerShell)
Use this script to:
- List all role assignments in your subscription
- Expand group memberships to show individual users
- Export results to JSON, CSV, or XML



Connect-AzureRmAccount Set-AzureRmContext -Subscription 'e614c005-fbcf-4e74-809b-f099ff6f5246'

connect-AxureRmAccount is deprecated and replaced with Connect-AzAccount. needs to install below module.

Install-Module -name Az -AllowClobber -Scope CurrentUser

# Run audit
$rbacAudit = .\Invoke-AzureRmSubscriptionRBACAudit.ps1

# Export to JSON
$rbacAudit | ConvertTo-Json -Depth 5 | Out-File .\rbacAudit.json
