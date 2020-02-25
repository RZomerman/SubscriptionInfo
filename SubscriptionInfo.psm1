


Function FindUser ($UPN) {
        if ($Userlist -and $UserList.userprincipalname.Contains($UPN)) {
            $Object = $UserList |where {$_.UserPrincipalName -eq $UPN}
            $DisplayName=$Object.DisplayName
            return  $DisplayName
        }else {
            $userObject=Get-AzureADUser -SearchString $UPN
            $UserList.add($userObject)
            [string]$DisplayName=$userObject.DisplayName 
            return $DisplayName           
        }
    
}





Function FindOwners {
    $UserList = New-Object System.Collections.ArrayList

    $Modules = Get-Module
    If ($Modules -notcontains "AzureAD") {Import-Module AzureAD}
    If ($Modules -notcontains "Az.Compute") {Import-Module Az}


    Try {
        Get-AzureADCurrentSessionInfo
    }catch{
        Connect-AzureAD
        #"Get-AzureADCurrentSessionInfo : You must call the Connect-AzureAD cmdlet before calling any other cmdlets"
    }


    Try {
        Get-AzSubscription
    }catch{
        Add-AzAccount
    }
    $Subscriptions=Get-AzSubscription
    ForEach ($Subsciption in $Subscriptions) {
        write-host "-------------------------------------------------------------------" -ForegroundColor Green
        $SubscriptionId=$Subsciption.SubscriptionId
        $scope = ('/subscriptions/' + $SubscriptionId )
        $OwnerOrContributors=Get-AzRoleAssignment -Scope $scope  |where {$_.RoleDefinitionName -eq 'Owner' -or $_.RoleDefinitionName -eq 'Contributor'}

        write-host "Subscription  : " $Subsciption.Name -ForegroundColor Cyan
        write-host "SubscriptionID: " $SubscriptionId  -ForegroundColor Cyan
        $List=$OwnerOrContributors | where {$_.ObjectType -eq "user"} 
        #$OwnerOrContributors | where {$_.ObjectType -eq "user"}  | select SignInName, RoleDefinitionName
##
        $tabName = "NetworkOutput"
        $table = New-Object system.Data.DataTable '$tabName'
        $col1 = New-Object system.Data.DataColumn Role,([string])
        $col2 = New-Object system.Data.DataColumn UPN,([string])
        $col3 = New-Object system.Data.DataColumn DisplayName,([string])
        $table.columns.add($col1)
        $table.columns.add($col2)
        $table.columns.add($col3)
##



        ForEach ($Role in $List){
            $row = $table.NewRow()
            [string]$DisplayName=FindUser $Role.SignInName
            $row.Role = $Role.RoleDefinitionName
            $row.UPN = $Role.SignInName
            $row.DisplayName = $DisplayName
            $table.Rows.Add($row)
            <#
            Write-host $Role.RoleDefinitionName "`t`t" -NoNewline 
            If ($Role.RoleDefinitionName -eq 'Owner') {write-host "`t" -NoNewline}

            write-host $Role.SignInName "`t" -NoNewline
            write-host $DisplayName -ForegroundColor Cyan
            #>
        }
        $table | format-table -AutoSize
    }
}

Function FindAllVMs {
    $Subscriptions=Get-AzSubscription
    ForEach ($Subsciption in $Subscriptions) {
        #Switch context to each subscription
        $Vnet=$null
        $VMs=$null
        $IPsPerVNET=0

##
    $tabName = "NetworkOutput"
    $table = New-Object system.Data.DataTable '$tabName'
    $col1 = New-Object system.Data.DataColumn NetworkName,([string])
    $col2 = New-Object system.Data.DataColumn AddressSpace,([string])
    $col3 = New-Object system.Data.DataColumn IPsInUse,([string])
    $table.columns.add($col1)
    $table.columns.add($col2)
    $table.columns.add($col3)
##

        $Context=Set-AzContext  -SubscriptionId $Subsciption.SubscriptionId
        write-host $Context.Name -ForegroundColor Green
        $Vnets=Get-AzVirtualNetwork
        If ($Vnets) {
            ForEach ($Vnet in $vnets){
                $row = $table.NewRow()
                $Subnets=$Vnet.Subnets
                Foreach ($Subnet in $Subnets) {
                    $IPsPerVNET = $IPsPerVNET + $Subnet.ipconfigurations.count
                }
                $AddressSpaces=$Vnet.AddressSpace.AddressPrefixes -join ' ^ '
                $row.NetworkName = $Vnet.name
                $row.AddressSpace = $AddressSpaces
                $row.IPsInUse = $IPsPerVNET

                $table.Rows.Add($row)
                #Write-host " "$Vnet.name "`t`t" -ForegroundColor Cyan -NoNewline
                #Write-host $Vnet.AddressSpace.AddressPrefixes -ForegroundColor Yellow -NoNewline
                #write-host "`t`t" $IPsPerVNET -ForegroundColor Yellow -NoNewline
                #write-host " addresses in use"

            }
            $Vms=Get-AzVM
            [array]$LinuxVM=$VMs | where {$_.OSProfile.LinuxConfiguration}
            [array]$WindowsVM=$VMs | where {$_.OSProfile.WindowsConfiguration}
            Write-host " Linux hosts in Subscription  " $LinuxVM.Count 
            Write-host " Windows hosts in Subscription" $WindowsVM.Count 

            $table | format-table -AutoSize
        }else{
            Write-host " no virtual networks" -ForegroundColor Gray
        }
       
        write-host "-------------------------------------------------------------------" -ForegroundColor Green
        write-host ""
        write-host ""
    }
        #getAllVnets
        #get all the VM's and their details
        #Printout #Windows / #Linux
}
