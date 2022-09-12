<#
This code simply deletes departing uer's data from file server
make sure both AD + o365 modules are instaled

Code written by: Hector Abreu, September 13th, 2022

#>
clear-host
#This code sets TLS protocol
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

write-warning "THIS CODE WILL DELETE ALL DEPARTING USER'S DATA FROM THE SERVER!!!"
write-host ""
read-host "Press <ENTER> to continue, or press <Ctrl + C> to CANCEL this madness"

function Load-Module ($m) {

    # If module is imported say that and do nothing
    if (Get-Module | Where-Object {$_.Name -eq $m}) {
        write-host "Module $m is already imported."
    }
    else {

        # If module is not imported, but available on disk then import
        if (Get-Module -ListAvailable | Where-Object {$_.Name -eq $m}) {
            Import-Module $m
        
        } else {
            # If module is not imported, not available on disk, but is in online gallery then install and import
            if (Find-Module -Name $m | Where-Object {$_.Name -eq $m}) {
                Install-Module -Name $m -Force -Verbose -Scope CurrentUser
                Import-Module $m
                }
            else {
                # If the module is not imported, not available and not in the online gallery then abort
                write-host "Module $m not imported, not available and not in an online gallery, exiting."
                EXIT 1
                }
        }
    }
}

#Calling load-module function 2x
write-host "Loading required modules"
Load-Module "ActiveDirectory"


#Checking if already connected to Msol
Get-MsolDomain -ErrorAction SilentlyContinue | out-null
if($?){
    write-host  "A connection  to Office365 already exists"
    }
else{
    write-host "Connecting to Office365..."
    Connect-MsolService
    }

$username = read-host "Enter name of user to offboard, e.g. [Bruce.lee]"
$ExistingADUser = Get-ADUser -Filter "SamAccountName -eq '$username'"

if($null -eq $ExistingADUser){
    write-host "SamAccountName '$username' does not exist in active directory" 
    exit 1
} else {

#set domain vars
$domain = "@domainname.xyz"
$upn = "$username$domain"

#set departing user data source path vars
write-host ""
write-host "Setting vars to ", $username, "s network folders"
$home_dir = "\\fileserver\users$\$username"
$Desktop_dir = "\\fileserver\desktop\$username"
$Document_dir = "\\fileserver\documents\$username"

write-host ""
write-host "Deleting network folders..."
$home_dir, $Desktop_dir, $Document_dir | where {(Test-Path $_)} | foreach {Remove-Item $_  -force -Recurse -Confirm:$false | out-null}

#remove user from o365
write-host ""
write-host "Removing ",$username,"'s office365 lics if assigned, then blocking access"
(get-MsolUser -UserPrincipalName $upn).licenses.AccountSkuId |
foreach{
    Set-MsolUserLicense -UserPrincipalName $upn -RemoveLicenses $_
    Set-MsolUser -UserPrincipalName $upn -BlockCredential $true
    }
    write-host ""
    write-host "Done deleting lics and blocking user access"
    write-host ""
 
write-host""
write-host "Hiding ", $username, " from GAL"   
set-aduser -identity $username -add @{msExchHideFromAddressLists = "TRUE"}

#make sure the path and ps file exists
Write-host""
write-host "Synching changes with Office 365"
 powershell -file "C:\AzureDirectoryConnectSync\execute_dirsync.ps1"

<#
write-host""
write-host "Removing ",$username, " from all groups"
Get-ADPrincipalGroupMembership $username| foreach {Remove-ADGroupMember $_ -Members $username -Confirm:$false}
#>
<#
write-host ""
write-host "Deleting user from AD"
Remove-ADUser -Identity $username -Confirm:$False
#>

write-host $username," network files have been deleted..."

}