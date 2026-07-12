# AI Making Challenge - Day 14

## 💡 Topic : Azure Network Path Tracer - Network Visualization & Rule Validation

## 🎯 Objective
As an Azure Cloud Engineer, I frequently encounter network connectivity issues:
- "Why can't VM A communicate with VM B?"
- "Is it blocked by NSG? Firewall? Route Table?"
- "Which rule is denying the traffic?"

Manually checking each network resource (VM → NIC → Subnet → NSG → VNet → Route Table → Firewall → Destination) is time-consuming and error-prone.

So I decided to build an **automated network path tracing and visualization tool** that:
1. **Traces the complete network path** from source VM to destination
2. **Validates NSG & Firewall rules** to determine if traffic is allowed/denied
3. **Visualizes the path** in an interactive diagram
4. **Shows rule details** when clicking on each resource

## 📚 Background Knowledge

### Network Path Components
```
Source VM (10.0.0.4)
    ↓
Network Interface (NIC)
    ↓
Subnet (10.0.0.0/24)
    ↓
Network Security Group (NSG) - Validates outbound rules
    ↓
Virtual Network (VNet)
    ↓
Route Table - Determines next hop using longest-prefix matching
    ↓
Firewall (Optional) - Validates Network & Application rules
    ↓
Destination (8.8.8.8:22)
```

### Key Algorithms

**1. Longest Prefix Matching (Routing Decision)**
```
Destination IP: 8.8.8.8
Routes:
  - 10.0.0.0/24 → VnetLocal (prefix: 24)
  - 0.0.0.0/0 → VirtualAppliance (prefix: 0)

Result: 8.8.8.8 doesn't match 10.0.0.0/24
        → Matches 0.0.0.0/0 (default route)
        → Routes to Firewall ✅
```

**2. CIDR Range Matching**
```
Test-IPInCIDR -IP "10.0.0.4" -CIDR "10.0.0.0/24"

1. Convert to binary: 10.0.0.4 → 0x0A000004
2. Apply /24 mask: 0xFFFFFF00
3. Compare: (0x0A000004 & 0xFFFFFF00) = 0x0A000000 ✅ Match
```

**3. Rule Matching Validation**
```
Checklist:
  ☑ Protocol match (TCP/UDP/*)
  ☑ Port in range (22, 80-443, *)
  ☑ Source CIDR match (10.0.0.0/8, *)
  ☑ Destination CIDR match (0.0.0.0/0, *)

All True → Rule matched ✅
```

## 🛠️ Tech Stack

| Component | Technology |
|-----------|-----------|
| Frontend | HTML5 + CSS3 + Vanilla JavaScript |
| Backend | Node.js + Express.js |
| Scripting | PowerShell 7 + Azure CLI |
| Cloud | Azure (Network Watcher, Resource Graph, Firewall Policy) |

## 📊 Results

### Example 1: Same VNet Communication (Local Delivery)
```
Input:
  Source: kali-linux (10.0.0.4)
  Destination: 172.16.2.4
  Port: 22, Protocol: TCP

Output:
  Path: VM → NIC → Subnet → NSG (✅ ALLOWED) → VNet → Destination
  
  Routing: 🌐 Local VNet Delivery
  NSG Status: ✅ ALLOWED (AllowAllOutbound rule)
  Result: Communication possible ✅
```

### Example 2: External Internet Communication (Via Firewall)
```
Input:
  Source: kali-linux (10.0.0.4)
  Destination: 8.8.8.8 (Google DNS)
  Port: 53, Protocol: UDP

Output:
  Path: VM → NIC → Subnet → NSG (✅ ALLOWED) 
        → VNet → Route Table → Firewall (✅ ALLOWED) 
        → Internet

  Routing: 🔥 Via Firewall (Virtual Appliance)
  NSG Status: ✅ ALLOWED
  Firewall Status: ✅ ALLOWED (test rule: * → * : *)
  Result: Communication possible ✅
```

### Interactive UI Features
- ✅ Network topology visualization with icons
- ✅ Routing method badges (🌐 Local VNet, 🔗 Peering, 🔥 Firewall, 🌍 Internet)
- ✅ Status indicators (✅ ALLOWED / ❌ DENIED) for NSG & Firewall
- ✅ Click nodes to see rule details in modal
- ✅ Light/Dark theme support

## 🏗️ Architecture

```
┌─────────────────────────┐
│   Browser (localhost:3001)
│  topology-viz.html
└──────────────┬──────────┘
               │ HTTP POST /api/trace-network
               ↓
┌─────────────────────────┐
│  Express.js Server
│  server.js
└──────────────┬──────────┘
               │ PowerShell execution
               ↓
┌─────────────────────────┐
│  PowerShell Script
│  get-full-network-path-v2.ps1
└──────────────┬──────────┘
               │ Azure CLI calls
               ↓
┌─────────────────────────┐
│  Azure Resources
│  - VMs, NICs, Subnets
│  - NSGs, VNets
│  - Route Tables, Firewalls
└─────────────────────────┘
```

## 💻 Usage

### Quick Start
```bash
# 1. Install dependencies
npm install

# 2. Start server
npm start

# 3. Open browser
http://localhost:3001
```

### Input Parameters
```
Resource Group: inyoung
VM Name: kali-linux
Source IP: 10.0.0.4
Destination IP: 8.8.8.8
Port: 22
Protocol: TCP
```

### Result Interpretation
- **Routing Type**: Shows path method (Local VNet, Peering, Firewall, Internet)
- **Node Status**: ✅ ALLOWED or ❌ DENIED badges
- **Rule Details**: Click NSG/Firewall nodes to see matched rules

## 📁 Project Structure

```
Day14-Azure-Network-Tracer/
├── Day14.md                    # This file
├── README.md                   # Project overview
├── QUICK_START.md              # 5-minute quick start
├── SETUP.md                    # Detailed installation guide
│
├── source-code/
│   ├── server.js               # Express backend
│   ├── topology-viz.html        # Frontend UI
│   ├── get-full-network-path-v2.ps1  # PowerShell script
│   ├── package.json            # Dependencies
│   └── icons/                  # Network resource icons
│
└── docs/
    ├── LICENSE
    ├── .gitignore
    ├── CONTRIBUTING.md
    └── FILES_CHECKLIST.md
```

## 🔧 Key Implementation Details

### 1. Effective Routes Analysis
```powershell
az network nic show-effective-route-table \
  --resource-group $rg \
  --name $nicName
```
Returns active routes with next-hop information for exact routing decisions.

### 2. NSG Rule Validation
- Checks **Outbound rules** for same-VNet communication
- Supports CIDR range matching (10.0.0.0/24, 0.0.0.0/0)
- Supports port ranges (22, 80-443, *)
- Falls back to default "AllowAllOutbound" rule

### 3. Firewall Policy Rule Matching
- Queries **Rule Collection Groups** from Firewall Policy
- Handles **Network Rules** (Layer 3/4)
- Handles **Application Rules** (Layer 7)
- Filters matching rules by source/dest/port/protocol

## ⚠️ Known Limitations

### Current Version
1. **IP Group members not resolved** - Shows group count only
2. **FQDN matching incomplete** - No DNS resolution
3. **Complex routing** - Partial support for UDR + NSG combinations
4. **Performance** - Large Firewall Policies may take longer

### Future Improvements
- [ ] IP Group member resolution
- [ ] Actual network connectivity tests (ping, TCP)
- [ ] Route change history tracking
- [ ] Performance optimization (rule caching)
- [ ] Mobile UI responsiveness

## 🔐 Security Considerations

### Current Setup
- ✅ Local development only (localhost:3001)
- ✅ Azure authentication via `az login`
- ⚠️ CORS: `origin: '*'` (development only)

### Production Checklist
- [ ] HTTPS enabled
- [ ] CORS restricted to specific domains
- [ ] Authentication/Authorization added
- [ ] Rate limiting implemented
- [ ] Input validation enhanced
- [ ] Logging and monitoring setup

## 📝 Reflection

Building this tool made me realize how **network troubleshooting can be automated and visualized**. What used to take 15+ minutes of manual checking across Azure Portal can now be done in seconds.

The key insight is understanding that **network validation follows predictable, rule-based logic**:
1. Route selection = Longest-prefix matching
2. Rule matching = Boolean logic (Protocol AND Port AND Source AND Destination)
3. Traffic flow = Following the matching rules in order

This is exactly the kind of **deterministic, rule-based problem-solving** that AI and automation excel at. By codifying these rules into algorithms, I've created a tool that is:
- ✅ **Faster**: Seconds instead of minutes
- ✅ **Accurate**: No human error in rule matching
- ✅ **Scalable**: Works for any size network
- ✅ **Auditable**: Complete path documentation

The future of cloud engineering will likely involve **more automation of diagnostic tasks** like this, freeing engineers to focus on architecture and optimization rather than repetitive troubleshooting.

## 🎓 Skills Developed

- ✅ **PowerShell scripting** - Automating Azure CLI calls
- ✅ **Network algorithms** - CIDR matching, longest-prefix routing
- ✅ **Full-stack development** - Node.js backend, vanilla JavaScript frontend
- ✅ **Azure services** - Network Watcher, Firewall Policy, Resource Graph
- ✅ **UI/UX design** - Interactive visualization with modals
- ✅ **Problem decomposition** - Breaking complex network problems into steps

## 📚 References

- [Azure Network Watcher Documentation](https://learn.microsoft.com/en-us/azure/network-watcher/)
- [Network Security Groups](https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview)
- [Azure Firewall](https://learn.microsoft.com/en-us/azure/firewall/)
- [User Defined Routes](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-udr-overview)

---

**Next Steps**: Deploy to Azure App Service, add IP Group resolution, implement real network connectivity tests.
