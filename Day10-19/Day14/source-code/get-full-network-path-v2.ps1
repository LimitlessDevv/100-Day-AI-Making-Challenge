# Azure Network Path Tracing v2 - Based on Effective Routes
# Uses NIC effective route table to determine actual packet path

param(
    [string]$ResourceGroup = "inyoung",
    [string]$VMName = "kali-linux",
    [string]$SourceIP = "10.0.0.4",
    [string]$DestIP = "172.16.2.4",
    [string]$DestPort = "22",
    [string]$Protocol = "TCP"
)

# IP가 CIDR 범위에 포함되는지 확인
function Test-IPInCIDR {
    param(
        [string]$IP,
        [string]$CIDR
    )

    if ($CIDR -eq "*") { return $true }

    try {
        $parts = $CIDR.Split('/')
        if ($parts.Count -ne 2) { return $false }

        $network = $parts[0]
        $prefixLength = [int]$parts[1]

        # Special case: 0.0.0.0/0 matches everything
        if ($network -eq "0.0.0.0" -and $prefixLength -eq 0) {
            return $true
        }

        # Convert IP to binary
        $ipParts = $IP.Split('.')
        $ipBinary = 0
        foreach ($part in $ipParts) {
            $ipBinary = ($ipBinary -shl 8) + [int]$part
        }

        # Convert network to binary
        $netParts = $network.Split('.')
        $netBinary = 0
        foreach ($part in $netParts) {
            $netBinary = ($netBinary -shl 8) + [int]$part
        }

        # Create mask (handle /0 case)
        if ($prefixLength -eq 0) {
            $mask = 0
        } else {
            $mask = [uint32]([uint32]::MaxValue -shl (32 - $prefixLength))
        }

        # Compare
        return (($ipBinary -band $mask) -eq ($netBinary -band $mask))
    } catch {
        return $false
    }
}

# Port range 확인 (예: "1-65535", "22", "*")
function Test-PortInRange {
    param(
        [string]$Port,
        [string]$RangeSpec
    )

    if ($RangeSpec -eq "*") { return $true }

    $portNum = [int]$Port

    if ($RangeSpec -like "*-*") {
        $parts = $RangeSpec.Split('-')
        $startPort = [int]$parts[0]
        $endPort = [int]$parts[1]
        return ($portNum -ge $startPort -and $portNum -le $endPort)
    } else {
        return ($RangeSpec -eq $Port)
    }
}

Write-Host "Starting network path tracing (v2 - Effective Routes)..." -ForegroundColor Cyan
Write-Host "VM: $VMName | Source: $SourceIP | Dest: ${DestIP}:${DestPort} ($Protocol)" -ForegroundColor Yellow
Write-Host ""

$pathNodes = @()
$stepNum = 1

# Step 1: VM Info
Write-Host "[$stepNum] Retrieving VM info..." -ForegroundColor Green
$vm = az vm show --resource-group $ResourceGroup --name $VMName --output json | ConvertFrom-Json
$pathNodes += @{
    step = $stepNum
    type = "Virtual Machine"
    name = $vm.name
    id = $vm.id
    location = $vm.location
    ip = $SourceIP
}
Write-Host "    OK: $($vm.name) ($SourceIP)" -ForegroundColor Cyan
$stepNum++
Write-Host ""

# Step 2: NIC Info
Write-Host "[$stepNum] Retrieving Network Interface..." -ForegroundColor Green
$nicId = $vm.networkProfile.networkInterfaces[0].id
$nic = az network nic show --ids $nicId --output json | ConvertFrom-Json
$nicName = $nic.name
$pathNodes += @{
    step = $stepNum
    type = "Network Interface"
    name = $nicName
    id = $nicId
    ip = $nic.ipConfigurations[0].privateIPAddress
    macAddress = $nic.macAddress
}
Write-Host "    OK: $nicName ($($nic.ipConfigurations[0].privateIPAddress))" -ForegroundColor Cyan
$stepNum++
Write-Host ""

# Step 3: Subnet Info
Write-Host "[$stepNum] Retrieving Subnet..." -ForegroundColor Green
$subnetId = $nic.ipConfigurations[0].subnet.id
$subnet = az network vnet subnet show --ids $subnetId --output json | ConvertFrom-Json
$subnetName = $subnet.name
$vnetId = $subnetId -replace "/subnets/.*", ""
$vnetName = $vnetId.Split('/')[-1]
$subnetResourceGroup = $subnetId.Split('/')[4]
$pathNodes += @{
    step = $stepNum
    type = "Subnet"
    name = $subnetName
    id = $subnetId
    vnet = $vnetName
    addressPrefix = $subnet.addressPrefix
    location = $subnet.location
}
Write-Host "    OK: $subnetName ($($subnet.addressPrefix)) in VNet: $vnetName" -ForegroundColor Cyan
$stepNum++
Write-Host ""

# Step 4: NSG Info
Write-Host "[$stepNum] Retrieving Network Security Group..." -ForegroundColor Green
$nsgId = $null
$nsgName = $null

if ($nic.networkSecurityGroup.id) {
    $nsgId = $nic.networkSecurityGroup.id
}

if (-not $nsgId -and $subnet.networkSecurityGroup.id) {
    $nsgId = $subnet.networkSecurityGroup.id
}

$nsgNode = $null
if ($nsgId) {
    $nsg = az network nsg show --ids $nsgId --output json | ConvertFrom-Json
    $nsgName = $nsg.name
    $nsgNode = @{
        step = $stepNum
        type = "Network Security Group"
        name = $nsg.name
        id = $nsgId
        rulesCount = $nsg.securityRules.Count
        location = $nsg.location
    }
    $pathNodes += $nsgNode
    Write-Host "    OK: $($nsg.name) (Rules: $($nsg.securityRules.Count))" -ForegroundColor Cyan
} else {
    Write-Host "    SKIP: NSG not found" -ForegroundColor Yellow
}
$stepNum++
Write-Host ""

# Step 5: VNet Info
Write-Host "[$stepNum] Retrieving Virtual Network..." -ForegroundColor Green
$vnet = az network vnet show --ids $vnetId --output json | ConvertFrom-Json
$pathNodes += @{
    step = $stepNum
    type = "Virtual Network"
    name = $vnet.name
    id = $vnetId
    addressSpace = $vnet.addressSpace.addressPrefixes
    subnets = $vnet.subnets.Count
    location = $vnet.location
}
Write-Host "    OK: $($vnet.name)" -ForegroundColor Cyan
Write-Host "        Address Space: $($vnet.addressSpace.addressPrefixes -join ', ')" -ForegroundColor Cyan
$stepNum++
Write-Host ""

# Step 6: Get Effective Routes
Write-Host "[$stepNum] Retrieving Effective Routes..." -ForegroundColor Green
$routeTableResult = az network nic show-effective-route-table --resource-group $ResourceGroup --name $nicName --output json | ConvertFrom-Json

# Extract the routes array
$effectiveRoutes = $routeTableResult.value
Write-Host "    Found $($effectiveRoutes.Count) routes" -ForegroundColor Cyan

# Debug: Print all routes
foreach ($r in $effectiveRoutes) {
    Write-Host "    Route: $($r.addressPrefix) -> $($r.nextHopType) (State: $($r.state))" -ForegroundColor DarkCyan
}

# Find the matching route for destination IP with longest prefix matching
$matchingRoute = $null
$longestPrefixLength = -1

foreach ($route in $effectiveRoutes) {
    # Only consider Active routes, skip Invalid/Blackhole routes
    if ($route.state -eq "Active" -and $route.nextHopType -ne "None") {
        $prefixArray = $route.addressPrefix

        # Handle both single string and array of prefixes
        $prefixes = @()
        if ($prefixArray -is [array]) {
            $prefixes = $prefixArray
        } else {
            $prefixes = @($prefixArray)
        }

        # Check all prefixes in this route
        foreach ($prefix in $prefixes) {
            $prefixParts = $prefix.Split('/')
            $prefixLength = [int]$prefixParts[1]

            # Check if destination matches this prefix using CIDR matching
            $matches = Test-IPInCIDR -IP $DestIP -CIDR $prefix

            # Use longest prefix match
            if ($matches -and $prefixLength -gt $longestPrefixLength) {
                $matchingRoute = $route
                $longestPrefixLength = $prefixLength
                Write-Host "    Route match: $prefix (prefix length: $prefixLength)" -ForegroundColor Cyan
            }
        }
    }
}

if ($matchingRoute) {
    $prefixArray = $matchingRoute.addressPrefix
    if ($prefixArray -is [array]) {
        $prefix = $prefixArray[0]
    } else {
        $prefix = $prefixArray
    }

    $nextHopIpArray = $matchingRoute.nextHopIpAddress
    if ($nextHopIpArray -is [array] -and $nextHopIpArray.Count -gt 0) {
        $nextHopIp = $nextHopIpArray[0]
    } else {
        $nextHopIp = $nextHopIpArray
    }

    Write-Host "    Matching Route: $prefix -> $($matchingRoute.nextHopType)" -ForegroundColor Cyan
    if ($nextHopIp) {
        Write-Host "    Next Hop IP: $nextHopIp" -ForegroundColor Cyan
    }

    # Get Route Table name if this is a User-defined route
    $routeTableName = "Default System Route"
    if ($matchingRoute.source -eq "User" -and $matchingRoute.name) {
        # Find the route table that contains this route
        $allRouteTables = az network route-table list --resource-group $ResourceGroup --output json | ConvertFrom-Json
        $owningTable = $allRouteTables | Where-Object {
            $_.routes | Where-Object { $_.name -eq $matchingRoute.name }
        } | Select-Object -First 1

        if ($owningTable) {
            $routeTableName = $owningTable.name
        }
    }

    $pathNodes += @{
        step = $stepNum
        type = "Effective Route"
        name = $routeTableName
        addressPrefix = $prefix
        nextHopType = $matchingRoute.nextHopType
        nextHopIpAddress = $nextHopIp
        source = $matchingRoute.source
        state = $matchingRoute.state
    }
} else {
    Write-Host "    No matching route found" -ForegroundColor Yellow
}
$stepNum++
Write-Host ""

# Step 7: Route handling based on Next Hop Type
if ($matchingRoute) {
    $nextHopType = $matchingRoute.nextHopType
    $nextHopIpArray = $matchingRoute.nextHopIpAddress
    if ($nextHopIpArray -is [array] -and $nextHopIpArray.Count -gt 0) {
        $nextHopIp = $nextHopIpArray[0]
    } else {
        $nextHopIp = $nextHopIpArray
    }

    if ($nextHopType -eq "VnetLocal") {
        Write-Host "[$stepNum] Destination (VNet Internal)" -ForegroundColor Green
        Write-Host "    Destination is in same VNet - direct routing within VNet" -ForegroundColor Cyan

        $pathNodes += @{
            step = $stepNum
            type = "Destination"
            ip = $DestIP
        }
        $stepNum++
        Write-Host ""

    } elseif ($nextHopType -eq "VirtualAppliance") {
        Write-Host "[$stepNum] Virtual Appliance (Next Hop)" -ForegroundColor Green
        Write-Host "    Next Hop IP: $nextHopIp" -ForegroundColor Cyan

        # Find the appliance (Firewall, LB, etc)
        $firewalls = az network firewall list --output json | ConvertFrom-Json
        $matchingFw = $null

        if ($firewalls) {
            $matchingFw = $firewalls | Where-Object {
                $_.ipConfigurations | Where-Object { $_.privateIPAddress -eq $nextHopIp }
            } | Select-Object -First 1
        }

        if ($matchingFw) {
            Write-Host "    Found Azure Firewall: $($matchingFw.name)" -ForegroundColor Cyan

            # Check Firewall Rules
            $fwRules = @()
            $fwRuleAllowed = $false
            $matchedFwRule = $null

            # Try to get Firewall Policy associated with this firewall
            $fwPolicy = $null
            $fwPolicy = az network firewall policy show --ids "$($matchingFw.id)/parent" --output json 2>$null | ConvertFrom-Json 2>$null

            if (-not $fwPolicy) {
                # Alternative: List all policies and find one referencing this firewall
                $allPolicies = az network firewall policy list --resource-group $ResourceGroup --output json | ConvertFrom-Json
                $fwPolicy = $allPolicies | Where-Object { $_.firewalls -and $_.firewalls.id -contains $matchingFw.id } | Select-Object -First 1
            }

            if ($fwPolicy) {
                Write-Host "        Found Firewall Policy: $($fwPolicy.name)" -ForegroundColor Cyan

                # Get Rule Collection Groups from Firewall Policy
                $ruleCollectionGroups = az network firewall policy rule-collection-group list --resource-group $ResourceGroup --policy-name $fwPolicy.name --output json | ConvertFrom-Json

                if ($ruleCollectionGroups -and $ruleCollectionGroups.Count -gt 0) {
                    Write-Host "        Found $($ruleCollectionGroups.Count) Rule Collection Group(s)" -ForegroundColor Yellow

                    foreach ($rcg in $ruleCollectionGroups) {
                        Write-Host "        Checking Rule Collection Group: $($rcg.name)" -ForegroundColor Yellow

                        # Each RCG has ruleCollections array
                        if ($rcg.ruleCollections) {
                            foreach ($collection in $rcg.ruleCollections) {
                                Write-Host "          Rule Collection: $($collection.name) (Action: $($collection.action.type))" -ForegroundColor Cyan

                                if ($collection.rules) {
                                    foreach ($rule in $collection.rules) {
                                        $ruleType = $rule.ruleType
                                        Write-Host "            Rule: $($rule.name) [$ruleType]" -ForegroundColor DarkCyan

                                        # Extract rule details based on type
                                        $sourceAddrs = @()
                                        $sourceIpGroups = @()
                                        $destAddrs = @()
                                        $destIpGroups = @()
                                        $destPorts = @()
                                        $protocols = @()
                                        $targetFqdns = @()

                                        if ($ruleType -eq "NetworkRule") {
                                            $sourceAddrs = if ($rule.sourceAddresses) { @($rule.sourceAddresses) } else { @() }
                                            $sourceIpGroups = if ($rule.sourceIpGroups) { @($rule.sourceIpGroups) } else { @() }
                                            $destAddrs = if ($rule.destinationAddresses) { @($rule.destinationAddresses) } else { @() }
                                            $destIpGroups = if ($rule.destinationIpGroups) { @($rule.destinationIpGroups) } else { @() }
                                            $destPorts = if ($rule.destinationPorts) { @($rule.destinationPorts) } else { @() }
                                            $protocols = if ($rule.ipProtocols) { @($rule.ipProtocols) } else { @() }
                                        } elseif ($ruleType -eq "ApplicationRule") {
                                            $sourceAddrs = if ($rule.sourceAddresses) { @($rule.sourceAddresses) } else { @() }
                                            $sourceIpGroups = if ($rule.sourceIpGroups) { @($rule.sourceIpGroups) } else { @() }
                                            $targetFqdns = if ($rule.targetFqdns) { @($rule.targetFqdns) } else { @() }
                                            $protocols = if ($rule.protocols) { @($rule.protocols | ForEach-Object { $_.protocolType }) } else { @() }
                                            $destPorts = if ($rule.protocols) { @($rule.protocols | Where-Object { $_.port } | ForEach-Object { [string]$_.port }) } else { @() }
                                        }

                                        Write-Host "              Source: $($sourceAddrs -join ',') (IpGroups: $($sourceIpGroups.Count))" -ForegroundColor DarkCyan
                                        Write-Host "              Dest: $($destAddrs -join ',') (IpGroups: $($destIpGroups.Count), FQDNs: $($targetFqdns -join ','))" -ForegroundColor DarkCyan
                                        Write-Host "              Port: $($destPorts -join ',')" -ForegroundColor DarkCyan
                                        Write-Host "              Protocol: $($protocols -join ',')" -ForegroundColor DarkCyan

                                        # Only add to fwRules if it could match (is not just a DENY rule for other traffic)
                                        $ruleObj = @{
                                            name = $rule.name
                                            type = $ruleType
                                            action = $collection.action.type
                                            sourceAddresses = $sourceAddrs
                                            sourceIpGroups = $sourceIpGroups
                                            destinationAddresses = $destAddrs
                                            destinationIpGroups = $destIpGroups
                                            destinationPorts = $destPorts
                                            protocols = $protocols
                                            targetFqdns = $targetFqdns
                                        }

                                        # Check if this rule matches our traffic (only for Allow rules)
                                        if ($collection.action.type -eq "Allow") {
                                            $portMatch = $false
                                            $protocolMatch = $false
                                            $destMatch = $false
                                            $sourceMatch = $false

                                            # Check Protocol
                                            foreach ($proto in $protocols) {
                                                if ($proto -eq "*" -or $proto -eq $Protocol) {
                                                    $protocolMatch = $true
                                                    break
                                                }
                                            }

                                            # Check Destination Port (with range support)
                                            if ($destPorts.Count -eq 0 -or $destPorts -contains "*") {
                                                $portMatch = $true
                                            } else {
                                                foreach ($port in $destPorts) {
                                                    if (Test-PortInRange -Port $DestPort -RangeSpec $port) {
                                                        $portMatch = $true
                                                        break
                                                    }
                                                }
                                            }

                                            # Check Destination Address
                                            if ($destAddrs.Count -eq 0 -and $destIpGroups.Count -eq 0 -and $targetFqdns.Count -gt 0) {
                                                # Application rule with only FQDN (skip IP matching)
                                                $destMatch = $false
                                            } else {
                                                if ($destAddrs -contains "*") {
                                                    $destMatch = $true
                                                } else {
                                                    foreach ($dest in $destAddrs) {
                                                        if (Test-IPInCIDR -IP $DestIP -CIDR $dest) {
                                                            $destMatch = $true
                                                            break
                                                        }
                                                    }
                                                }
                                            }

                                            # Check Source Address
                                            if ($sourceAddrs.Count -eq 0 -and $sourceIpGroups.Count -eq 0) {
                                                $sourceMatch = $false
                                            } else {
                                                if ($sourceAddrs -contains "*") {
                                                    $sourceMatch = $true
                                                } else {
                                                    foreach ($source in $sourceAddrs) {
                                                        if (Test-IPInCIDR -IP $SourceIP -CIDR $source) {
                                                            $sourceMatch = $true
                                                            break
                                                        }
                                                    }
                                                }
                                            }

                                            Write-Host "              Match Status - Proto: $protocolMatch, Port: $portMatch, Dest: $destMatch, Source: $sourceMatch" -ForegroundColor DarkCyan

                                            if ($portMatch -and $protocolMatch -and ($destMatch -or $destIpGroups.Count -gt 0) -and ($sourceMatch -or $sourceIpGroups.Count -gt 0)) {
                                                $fwRuleAllowed = $true
                                                $matchedFwRule = $rule.name
                                                $fwRules += $ruleObj
                                                Write-Host "            ✅ MATCHED: $($rule.name)" -ForegroundColor Green
                                                Write-Host "               Source: $($sourceAddrs -join ',')" -ForegroundColor Green
                                                Write-Host "               Dest: $($destAddrs -join ',')" -ForegroundColor Green
                                                Write-Host "               Port: $($destPorts -join ',')" -ForegroundColor Green
                                                Write-Host "               Protocol: $($protocols -join ',')" -ForegroundColor Green
                                            } else {
                                                # Only store matching rules, not all
                                                if ($portMatch -or $destMatch -or $sourceMatch) {
                                                    $fwRules += $ruleObj
                                                }
                                            }
                                        } elseif ($collection.action.type -eq "Deny") {
                                            # For DENY rules, add if they might match
                                            $fwRules += $ruleObj
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    Write-Host "        No Rule Collection Groups found in Firewall Policy" -ForegroundColor Yellow
                }
            } else {
                Write-Host "        No Firewall Policy found for this firewall" -ForegroundColor Yellow
            }

            # Add firewall info to path
            $fwNode = @{
                step = $stepNum
                type = "Azure Firewall"
                name = $matchingFw.name
                id = $matchingFw.id
                ip = $nextHopIp
                location = $matchingFw.location
                sku = $matchingFw.sku.name
                threatIntelMode = $matchingFw.threatIntelMode
                rules = $fwRules
                ruleAllowed = $fwRuleAllowed
                matchedRule = $matchedFwRule
            }
            $pathNodes += $fwNode

            if ($fwRuleAllowed) {
                Write-Host "        ✅ Traffic ALLOWED by Firewall Rule: $matchedFwRule" -ForegroundColor Green
            } else {
                Write-Host "        ⚠️  No matching Firewall rule found (may be blocked)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "    Virtual Appliance (IP: $nextHopIp)" -ForegroundColor Cyan
            $pathNodes += @{
                step = $stepNum
                type = "Virtual Appliance"
                ip = $nextHopIp
            }
        }
        $stepNum++
        Write-Host ""

        # After firewall, destination
        Write-Host "[$stepNum] Destination" -ForegroundColor Green
        Write-Host "    IP: $DestIP" -ForegroundColor Cyan
        $pathNodes += @{
            step = $stepNum
            type = "Destination"
            ip = $DestIP
            port = $DestPort
            protocol = $Protocol
        }
        $stepNum++
        Write-Host ""

    } elseif ($nextHopType -eq "Internet") {
        Write-Host "[$stepNum] Internet Gateway" -ForegroundColor Green
        Write-Host "    Destination: $DestIP (External)" -ForegroundColor Cyan
        $pathNodes += @{
            step = $stepNum
            type = "Destination"
            ip = $DestIP
            port = $DestPort
            protocol = $Protocol
            description = "Internet"
        }
        $stepNum++
        Write-Host ""
    }
}

# Step 8: NSG Rule Validation (Outbound for same VNet)
if ($nsgNode) {
    Write-Host "[$stepNum] Validating NSG Rules..." -ForegroundColor Green

    $nsgRules = az network nsg rule list --resource-group $ResourceGroup --nsg-name $nsgName --output json | ConvertFrom-Json
    Write-Host "    NSG Rules found: $($nsgRules.Count)" -ForegroundColor Cyan

    # Get default outbound rule
    $defaultOutboundRule = @{
        name = "AllowAllOutbound"
        access = "Allow"
        direction = "Outbound"
        protocol = "*"
        sourceAddressPrefixes = @("*")
        destinationAddressPrefixes = @("*")
        sourcePortRanges = @("*")
        destinationPortRanges = @("*")
    }

    # For outbound traffic, check OUTBOUND rules
    # Azure NSG has implicit default allow outbound rule
    $outboundDeny = $false
    $matchedRule = $null
    $allRules = @($nsgRules) + @($defaultOutboundRule)

    # Check for explicit DENY rules first
    foreach ($rule in $nsgRules) {
        if ($rule.direction -eq "Outbound" -and $rule.access -eq "Deny") {
            $destPorts = $rule.destinationPortRanges
            if ($destPorts -is [string]) {
                $destPorts = @($destPorts)
            }

            $portMatch = $destPorts -contains "*" -or $destPorts -contains $DestPort

            if ($portMatch) {
                $outboundDeny = $true
                $matchedRule = $rule
                break
            }
        }
    }

    # If no DENY rule found, check for explicit ALLOW rules
    if (-not $outboundDeny -and -not $matchedRule) {
        foreach ($rule in $nsgRules) {
            if ($rule.direction -eq "Outbound" -and $rule.access -eq "Allow") {
                $destPorts = $rule.destinationPortRanges
                if ($destPorts -is [string]) {
                    $destPorts = @($destPorts)
                }

                $portMatch = $destPorts -contains "*" -or $destPorts -contains $DestPort

                if ($portMatch) {
                    $matchedRule = $rule
                    break
                }
            }
        }
    }

    # If still no match, use default allow outbound
    if (-not $matchedRule) {
        $matchedRule = $defaultOutboundRule
    }

    $allowed = -not $outboundDeny
    $reason = if ($outboundDeny) { "Denied by rule: $($matchedRule.name)" } else { "Allowed by rule: $($matchedRule.name)" }

    # Add validation info to NSG node (include all rules + matched rule)
    $nsgNode.validation = @{
        allowed = $allowed
        reason = $reason
        allRules = @($nsgRules | Select-Object -Property name, access, direction, protocol, destinationPortRanges)
        matchedRule = $matchedRule.name
        matchedRuleDetails = @{
            name = $matchedRule.name
            access = $matchedRule.access
            direction = $matchedRule.direction
            protocol = $matchedRule.protocol
            destinationPortRanges = $matchedRule.destinationPortRanges
        }
    }

    if ($allowed) {
        Write-Host "    ✅ Outbound traffic ALLOWED by rule: $($matchedRule.name)" -ForegroundColor Green
    } else {
        Write-Host "    ❌ Outbound traffic DENIED by rule: $($matchedRule.name)" -ForegroundColor Red
    }
    $stepNum++
    Write-Host ""
}

# Generate JSON
Write-Host "Generating JSON output..." -ForegroundColor Green
$pathJson = @{
    metadata = @{
        timestamp = Get-Date -Format "yyyy-MM-dd'T'HH:mm:ss'Z'"
        sourceVm = $VMName
        resourceGroup = $ResourceGroup
        sourceIp = $SourceIP
        destinationIp = $DestIP
        destinationPort = $DestPort
        protocol = $Protocol
        routingMethod = $matchingRoute.nextHopType
    }
    path = $pathNodes
} | ConvertTo-Json -Depth 10

$pathJson | Write-Host
$pathJson | Set-Content -Path "network-path-full.json" -Encoding UTF8

Write-Host ""
Write-Host "Success: network-path-full.json saved" -ForegroundColor Green
