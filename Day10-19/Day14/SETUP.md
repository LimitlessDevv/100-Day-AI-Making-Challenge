# Installation and Setup Guide (Detailed)

## 📋 Prerequisites Check

### 1. Check Node.js
```powershell
node --version
npm --version
```

**Required Versions**:
- Node.js v18 or higher
- npm v9 or higher

If not installed, download from [nodejs.org](https://nodejs.org)

### 2. Check PowerShell
```powershell
$PSVersionTable.PSVersion
```

**Required Versions**:
- PowerShell v7 or higher (recommended)
- Windows PowerShell 5.1 also works, but v7+ preferred

### 3. Check Azure CLI
```powershell
az --version
```

If not installed:
```powershell
# Windows (Chocolatey)
choco install azure-cli

# Or manual installation
# https://learn.microsoft.com/cli/azure/install-azure-cli-windows
```

### 4. Check Azure Login
```powershell
az account show
```

If not logged in:
```powershell
az login
```

## 🔧 Installation Steps

### Step 1: Clone Repository
```powershell
git clone https://github.com/yourusername/azure-network-path-tracer.git
cd azure-network-path-tracer
```

Or download ZIP and extract.

### Step 2: Install Dependencies
```powershell
npm install
```

This command installs:
- `express`: REST API server
- `cors`: Cross-Origin Resource Sharing
- `body-parser`: JSON parsing

Generated files:
- `node_modules/`: Dependency directory (included in `.gitignore`)
- `package-lock.json`: Exact version tracking

### Step 3: Verify Icons Folder
```powershell
# Check if icons folder exists
ls -R icons/
```

If missing, create it:
```powershell
mkdir icons
# Place SVG files in the icons folder
```

**Required SVG Files**:
- `virtual-machine.svg`
- `network-interfaces.svg`
- `subnet.svg`
- `network-security-groups.svg`
- `virtual-networks.svg`
- `route-tables.svg`
- `firewalls.svg`

Or use emojis in `topology-viz.html` as fallback.

## 🚀 Running the Application

### Method 1: Run with npm
```powershell
npm start
```

Output:
```
Server running at http://localhost:3001
```

### Method 2: Run with Node.js directly
```powershell
node server.js
```

### Method 3: Run on specific port
```powershell
# Modify PORT in server.js or:
$env:PORT=3002
npm start
```

## 🌐 Access in Browser

Once server starts, open:
```
http://localhost:3001
```

## 📝 Usage Examples

### Example 1: Verify SSH Communication within Same VNet

#### Input Parameters
```
Resource Group: inyoung
VM Name: kali-linux
Source IP: 10.0.0.4
Destination IP: 172.16.2.4
Port: 22
Protocol: TCP
```

#### Expected Result
```
Path:
kali-linux → NIC → Subnet → NSG (✅ ALLOWED) → VNet → Destination

Routing: 🌐 Local VNet Delivery
NSG: ✅ ALLOWED (AllowAllOutbound rule)
```

### Example 2: External DNS Query (Through Firewall)

#### Input Parameters
```
Resource Group: inyoung
VM Name: kali-linux
Source IP: 10.0.0.4
Destination IP: 8.8.8.8
Port: 53
Protocol: UDP
```

#### Expected Result
```
Path:
kali-linux → NIC → Subnet → NSG → VNet → Route Table → Firewall → Destination

Routing: 🔥 Via Firewall
NSG: ✅ ALLOWED
Firewall: ✅ ALLOWED (rule: test)
```

---

**Tip: Click Firewall icon to see matched rule details.**

## 🐛 Troubleshooting

### Issue 1: "Cannot GET /"
**Cause**: Server cannot find static files

**Solution**:
```powershell
# Verify folder location
pwd
# output: C:\...\azure-network-path-tracer

# Check if topology-viz.html exists
ls topology-viz.html

# If present, restart server
npm start
```

### Issue 2: "Error: listen EADDRINUSE"
**Cause**: Port 3001 already in use

**Solution**:
```powershell
# Kill process on port
Get-NetTCPConnection -LocalPort 3001 -State Listen | Stop-Process -Force

# Restart
npm start
```

Or use a different port:
```powershell
# Modify PORT in server.js to 3002, then:
npm start
```

### Issue 3: "PowerShell Script Execution Policy Error"
**Cause**: Windows restricts external script execution

**Solution**:
```powershell
# Allow for current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or process-level bypass
powershell -ExecutionPolicy Bypass -Command "..."
```

### Issue 4: "az: command not found"
**Cause**: Azure CLI not installed or not in PATH

**Solution**:
```powershell
# Check Azure CLI
az --version

# If not installed
choco install azure-cli

# Or manual installation
# https://learn.microsoft.com/cli/azure/install-azure-cli-windows
```

### Issue 5: "Not authorized to perform action"
**Cause**: Azure account lacks required permissions

**Solution**:
```powershell
# 1. Check account
az account show

# 2. List subscriptions
az account list

# 3. Switch subscription
az account set --subscription "subscription-ID"

# 4. Check permissions
# Go to Azure Portal → Resource Group → IAM
# Required role: "Network Contributor" or higher
```

### Issue 6: Modal not appearing
**Cause**: JavaScript error

**Solution**:
```powershell
# 1. Open browser developer console (F12)
# 2. Check Console tab for errors
# 3. Screenshot error and submit GitHub Issue
```

## 🔍 Viewing Logs

### Server Logs
```powershell
# View directly in terminal
npm start
```

### PowerShell Script Detailed Logs
```powershell
# Run script directly
.\get-full-network-path-v2.ps1 `
  -ResourceGroup "inyoung" `
  -VMName "kali-linux" `
  -SourceIP "10.0.0.4" `
  -DestIP "8.8.8.8" `
  -DestPort "53" `
  -Protocol "UDP"

# Output:
# [1] Retrieving VM info...
# [2] Retrieving Network Interface...
# ...
```

### View JSON Results
```powershell
# Check network-path-full.json
cat network-path-full.json | ConvertFrom-Json | ConvertTo-Json -Depth 10
```

## 📊 Performance & Optimization

### When Performance is Slow
- **Many Firewall rules**: Query time increases (proportional to Rule Collection Group count)
- **Large Resource Groups**: All Route Tables must be queried

### Optimization Tips
1. **Specify exact Resource Group**: Avoid querying unnecessary resources
2. **Local development**: Start with small-scale test environment
3. **Caching**: Don't query same path multiple times

## 🔐 Security Considerations

### Development Environment
- ✅ Use `localhost:3001` for local development only
- ✅ Azure authentication via `az login` (local machine only)

### Production Deployment Checklist
- ❌ CORS: Remove `origin: '*'` and restrict to specific domains
- ❌ Enable HTTPS
- ❌ Store sensitive info in environment variables
- ❌ Implement rate limiting
- ❌ Enhance input validation

## 📚 References

- [Azure CLI Documentation](https://learn.microsoft.com/cli/azure/)
- [Azure Network Watcher](https://learn.microsoft.com/azure/network-watcher/)
- [PowerShell Scripting](https://learn.microsoft.com/powershell/scripting/)
- [Express.js Guide](https://expressjs.com/)

---

**If issues persist, please report on GitHub Issues!**
