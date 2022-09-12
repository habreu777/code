<# 
The idea for this project was inspired from:
https://adamtheautomator.com/powershell-menu/

The example on this blog is only a sketch without logic. Mine is a fully functional / practical implementation


This code may help expedite AD user onboarding / offboarding process.

DISCLAMER: NEVER run ANY / THIS code on a production environment withour first
making 100000% certain you understand ans agree, that by running this code, you may loose data, and other
back-end server settings...

so, check the code, check it again, then again...


putting this code together has taken me over a year. Yes, I am slow as hell!!

Please fix anything you find that is wrong; it is redundant, or that it is not needed.

Use this line to customize colors:
$input = $(Write-Host "Please, type your Name" -NoNewLine) + $(Write-Host " EX: Praveen Kumar " -ForegroundColor yellow -NoNewLine; Read-Host) 


#>

#warn the user
write-warning "I am 100# responsible for any data / settings lost as a result of running this code"
write-host "I have read and understood the code"
write-host""
read-host "Press <ENTER> to agree to the terms and continue, or press <Ctrl + C> to exit this madness"

#The functionality of this depends on this system having an active internet connection. let's make sure we are connated
while (!(test-connection 8.8.8.8 -Count 1 -Quiet)) {
    write-warning "No active Internet connection detected. Trying again"
    start-sleep 5
    }
read-host "Internet conectin detected. Press enter to continie"


Set-StrictMode -Off
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass


#Making sure PS session was opened with elevated permission
#the who are you functuion declaration
Function whoareyou {
    $isadmin = (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not ($isadmin)){
        #clear-host
        write-host 'Hey "William James Sidis", you MUST open PowerShell as an admin. You should consider becoming a farmer.' -fore DarkYellow
        Exit
    } else {
        clear-host
        write-warning "Running this program can result in data loss. Be careful!!"
        Read-Host -Prompt "Press <ENTER> to continue, or press <CTRL+C> to terminate program"
        }
    }
#calls the whoareyiu function
whoareyou

#this code returns the name / path of the active script
function PSscript {
  $scriptname = Get-Item $MyInvocation.ScriptName
  Return $scriptname.name
}


#We now declare the function responsible for building the menu
function Show-Menu {
    param ([string]$title = (& {psscript}))
    
    Clear-Host
    
    write-host""
    Write-Host "========= Script: $title =========" -foregroundcolor black -backgroundcolor yellow
    Write-Host
    Write-Host " Press 'C' To Create user account" -fore white
    write-host""
    Write-Host " Press 'T' To Terminate  user account" -fore red
    write-host""
    Write-Host " Press 'A' To Assign licenses to a user" -fore cyan
    write-host""
    Write-Host " Press 'V' To View licenses assigned to a user" -fore white
    write-host""
    Write-Host " Press 'G' To View groups user is member of" -fore gray
    write-host""
    Write-Host " Press 'M' To reset user MFA number" -fore cyan
    write-host""
    Write-Host " Press 'X' To copy group memberships" -fore yellow
    Write-Host""
    write-host " Press 'R' To reset spooler on all print servers (PRINTSERVER1, PRINTSERVER2, PRINTSERVER3...)" -fore gray
    write-host""
    Write-Host " Press 'Q' To Quit this madness" -fore cyan
    Write-Host""
    
    Write-Host "========= By Grand master 'Hector Abreu' =========" -foregroundcolor black -backgroundcolor yellow
    Write-Host ""
}#bracket for function

function Module_Check ($m) {
    clear-host
    # If module is imported say that and do nothing
    if (Get-Module | Where-Object { $_.Name -eq $m }){
        }
    else {
        # If module is not imported, but available on disk then import
        if (Get-Module -ListAvailable | Where-Object { $_.Name -eq $m }){
            write-host "Module $m is installed but not loaded. Importing module"
            Import-Module $m
            }
        else {
            # If module is neither imported, not available on disk, but is in online gallery then install and import
            if (Find-Module -Name $m | Where-Object { $_.Name -eq $m }){
                write-host "Module $m was not fpund on disk. We are downloading and installing it. Please wait.."
                Install-Module -Name $m -Force -Scope CurrentUser
                Import-Module $m
                }
            else {
                # If the module is not installed, imported, nor available online, then quit with message
                write-host "We did not find module $m on disk nor online. Program ended."
                EXIT 1
                }
            }
        }
    }


#Call function module_check, to make sure both AD +  O365 modules are installed and imported
write-host "Check wether both AD + MSOL modules are installed and loaded"
Module_Check "activedirectory"
Module_Check "MSOnline"  

#if no active Office 365 connection then establish a connection
Get-MsolDomain -ErrorAction SilentlyContinue | Out-Null
if ($?){
    write-host "We've detected an active Office 365 connection. Please wait..."
    }
else {
    write-host "No active office 365 connection detected. Connecting now.."
    Connect-MSolService
    }

#module that shows menu

do {
    
    Show-Menu
    Do { $selection = (Read-Host 'Please make a selection').ToUpper() } While ($selection -notmatch "C|T|A|V|G|M|X|R|Q")
    switch ($selection) {

        'C' {'New user setup moduled invoked'
            read-host "Get new user details and press enter to get started"

            try {
                #Remove error message that says can't add to group, even though it does add it successfully.
                $ErrorActionPreference = 'SilentlyContinue'
                Write-Host -BackgroundColor DarkGreen "Make sure new user info are spelled correctly.."

                # Arrays for the script
                $domain = "@yourdomain.xyz"
                $FirstName = Read-Host "Enter First Name"
                $Surname = Read-Host "Enter Last Name"
                $Username = ("$Firstname.$Surname").ToLower()

                #Make sure new user id does not already exists or is blank
                do {
                    $usercheck = read-host "Confirm user's name [e.g. bruce.lee]"
                    $User = $(try { Get-ADUser $usercheck } catch { $null })
                    If ($User -ne $Null){
                        write-host $usercheck," already has an account in AD. Select a different login name"
                        }
                    Else {
                        write-host "Great!: ",$Username," is available to use for new user account"
                        }
                    }
                while ($user)

                
                #$adpcode = Read-host "Enter new user adp code"
                $ADgroups = Read-Host "Give ",$UserCheck, " the same group membership as "
                $Password = Read-Host "Enter a Password for ",$usercheck | ConvertTo-SecureString -AsPlainText -Force


                #creates base AD account
                write-host  -BackgroundColor DarkGreen "Creating account for ",$username," Please stand by..."
                New-ADUser `
                    -Name "$FirstName $Surname" `
                    -GivenName $FirstName `
                    -Surname $Surname `
                    -SamAccountName $Username `
                    -UserPrincipalName $Username$domain `
                    -Displayname "$FirstName $Surname" `
                    -Path "CN=Users,DC=projectrenewal,DC=org" `
                    -AccountPassword $Password 

                # Set additional account attributes
                Set-ADUser $Username -Enabled $True
                Set-ADUser $Username -ChangePasswordAtLogon $True 
                Set-ADUser $Username -EmailAddress "$Username@yourdomain.xyz"
                Set-ADUser $Username -Add @{homeDirectory = "\\fileserver\users$\$username"}
                set-aduser $username -Add @{homeDrive = "H"}
                set-aduser $username -mailNickname "$username"
                #set-aduser $username -add @{extensionAttribute1 = "$adpcode"}
                set-aduser $username -add @{proxyAddresses = "SMTP:$username$domain"} 
                Start-Sleep -s 10

                Write-Host -BackgroundColor DarkGreen "Copying ",$ADgroups, " groups to ",$Username," ...."

                # Copy groups membership from source user to target user
                Get-ADUser -Identity $ADgroups -Properties memberof | Select-Object -ExpandProperty memberof |  Add-ADGroupMember -Members $Username
                Start-Sleep -s 10
                write-host -BackgroundColor DarkGreen "Done copying groups"
                write-host ""

                #code that copy new user to correct OU
                write-host -BackgroundColor DarkGreen "Copying new user to correct OU"
                $oupath = Get-AdUser -Identity $adgroups -Properties CanonicalName
                $newuserOU = "OU="+($oupath.DistinguishedName -split ",OU=",2)[1]
                Get-ADUser -Identity $username | Move-ADObject -TargetPath $newuserOU
                write-host -BackgroundColor DarkGreen 'Done copying user' #, $username, 'to ', $newuserOU, 'OU'


                #### This code runs only once new user shows up in O365 portal
                Write-Host -BackgroundColor DarkGreen "Waiting for '$username' to show up in office 365. This could take upto 10 minutes.."
                $upn = "$username$domain"

                #module to Synch AD with AAD / MSOLS + assign office 365 lics
                #depending on what suscription lics are available
                #edit the active units, consummed units, warning units ect, to match your lic settings in o365
                Do {
                    powershell -file "C:\AzureDirectoryConnectSync\execute_dirsync.ps1"
                    Start-Sleep -s 300
                    $User = Get-MsolUser -UserPrincipalName "$upn" -ErrorAction SilentlyContinue
                } while ($Null -eq $user) #once user show in office 365 then assign the lics

                Set-MsolUser -UserPrincipalName "$upn" -UsageLocation US

               $e3= Get-MsolAccountSku | Where AccountSkuId -Contains domainname:ENTERPRISEPACK
               $e2= Get-MsolAccountSku | Where AccountSkuId -Contains domainname:STANDARDWOFFPACK
               $win10_Ent = Get-MsolAccountSku | Where AccountSkuId -Contains domainname:Win10_VDA_E3
               $def_plan1 = Get-MsolAccountSku | Where AccountSkuId -Contains domainname:DEFENDER_ENDPOINT_P1m


               if( $e3.ConsumedUnits -lt $e3.WarningUnits){
                   Write-Host -BackgroundColor DarkGreen "Aplying E3 lic"
                   Set-MsolUserLicense -UserPrincipalName "$upn" -AddLicenses $e3.AccountSkuId  
                   }

                elseif( $e3.ConsumedUnits -ge $e3.WarningUnits -and $e2.ConsumedUnits -lt $e2.ActiveUnits){
                    Write-Host -BackgroundColor DarkGreen "Applying E2 lic"
                    Set-MsolUserLicense -UserPrincipalName "$upn" -AddLicenses $e2.AccountSkuId
                    }

                else{
                    Write-host "No active E2 or E3 Licenses available  for the current tenant"
                    }

                if( $win10_Ent.ConsumedUnits -lt $win10_Ent.WarningUnits){
                    Write-Host -BackgroundColor DarkGreen "Aplying Win 10 Ent lic"
                    Set-MsolUserLicense -UserPrincipalName "$upn" -AddLicenses $win10_Ent.AccountSkuId  
                    }
                else{Write-Warnin "No Win 10 Ent lics available. Try assigning it manually"}


                if( $def_plan1.ConsumedUnits -lt $def_plan1.WarningUnits){
                    Write-Host -BackgroundColor DarkGreen "Aplying Win defender plan 1 lic"
                    Set-MsolUserLicense -UserPrincipalName "$upn" -AddLicenses $def_plan1.AccountSkuId  
                    }


                #play morse code sound to alert new user showed in O365 portal
                #make sure you have the cli version of vlc installed and that the 
                #audio files are in the correct path; with the same name
                & "C:\Program Files (x86)\VideoLAN\VLC\vlc.exe" --qt-start-minimized --play-and-exit --qt-notification=0 ".\finishim.mp3"

                & "C:\Program Files (x86)\VideoLAN\VLC\vlc.exe"th  --qt-start-minimized --play-and-exit --qt-notification=0 ".\morse.mp3"
                Start-Sleep -s 15

                #view lics applied to new user
                write-host -BackgroundColor DarkGreen "displaying lics applied to ", $Username
                (Get-MsolUser -UserPrincipalName "$upn").Licenses.accountskuid
                read-host "Press a key to continue"

            } catch { 
                $message = $_
                Write-Warning "Crap!, ran into an issue", $message
                Read-Host "press enter to continue"
                }

        }#end bracket for  create new user or choice 1


###############end of module 'Create new account'########################




######################start of module 'Terminate' #########################

        'T' {"Terminate user module invoked"
        write-warning "Carefully review the departing user form before you contnue"
        write-host""
        read-host "Press <ENTER> to continue"

        Do {
            $departing_username = (Read-Host "Enter username to terminate, e.g. [Bruce.Lee]")
            }
        While ([string]::IsNullOrWhiteSpace($departing_username) -or [string]::IsNullOrEmpty($departing_username))
        
         #Clear-Host
        do {
            $departing_username = (Read-Host "Please confirm username to terminate, e.g. [Robert Kirby]")
            try{
                $marcopolo = get-aduser $departing_username -ErrorAction Silentlycontinue
                write-verbose "Username '$departing_username' exists in AD. Proceeding with user offboarding processs" -Verbose
                }
            catch{
                write-warning "User: '$departing_username' was not found in AD. Check name and try again."
                }
                }
        until($marcopolo)

        
        #code dealing with departing user's mailbox
        do{

            $keep_mailbox = (read-host "Are we keeping / sharing departing user's mailbox (Y/N)").ToUpper()
            }
        while ("Y","N" -notcontains $keep_mailbox)
        if ($Keep_mailbox -eq 'Y'){
            $dom = "@yourdomain.xyz"
            $prefix  = "Departed_"
            $departeddate = (Get-Date).ToString("yyMMdd")
                    
            $obj = get-aduser $departing_username -Properties * | Select-Object  displayname
            $display_name = ($obj | Select -ExpandProperty "displayname")
            $new_display_name = "$departeddate"+"_"+"$display_name"
            $new_upn = "$prefix$departing_username$dom"

            $User_update = Get-ADUser -Identity $departing_username -Properties displayName,mail
            $User_update.mail = "$new_upn"
            $User_update.displayName = "$new_display_name"
            Set-ADUser -Instance $User_update

            set-aduser -identity $departing_username -add @{msExchHideFromAddressLists = "TRUE"}
            Set-ADUser -Identity $departing_username -remove @{ ProxyAddresses = ""} -Debug -Verbose
            set-aduser -identity $departing_username -add @{proxyAddresses = "SMTP:$new_upn"}
            set-ADUser -Identity $departing_username -Add @{mailNickname = "$departing_username"}

            #synch ad with aad + O365
            #make sure the ps file in in this path
            powershell -file "C:\AzureDirectoryConnectSync\execute_dirsync.ps1"

                     
                    <# uncomment this section if you want to allow HD staff to manage departing user's mailboxexchange then 

                    Do {
                        $usercheck = read-host "Who should we share this mailbox with [e.g. bruce.lee]"
                        
                        $namecheck = $(try { Get-ADUser $usercheck } catch { $null })

                        if ($namecheck -eq $Null){

                            write-host "An AD account for $namecheck was not found. Try again"

                            }

                        else {

                            write-host "Account for $namecheck was found"
                            #code here show several ways to handle departing use's mailbox
                            #HACK THIS CODE TO MEET YOUR NEEDS
                            
                            
                            $userCredential = Get-Credential
                            $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection  Import-PSSession $session 
                            Add-MailboxPermission -Identity emailaddress -User emailaddress -AccessRights FullAccess -AutoMapping:$true
                            Add-MailboxPermission -Identity "Shared Mailbox" -User "User to Add" -AccessRight FullAccess -InheritanceType All -AutoMapping $True
                            Add-MailboxPermission -Identity emailaddress -User emailaddress -AccessRights FullAccess -InheritanceType All -AutoMapping:$true
                            Add-MailboxPermission -Identity "Terry Adams" -User "Kevin Kelly" -AccessRights FullAccess -InheritanceType All
                            
                            SHare this code with Luis to help deal with departing user mailboxes if kept
                            


                            }

                        }

                    while (-!($usercheck))

                    #>

                    }



                if ($keep_mailbox -eq 'N'){
                    #code here to remove departing user's mailbox
                    write-host "Departing user's email will be deleted; all O365 lics removed"

                     #Remove departing user's o365 lics
                    (get-MsolUser -UserPrincipalName $Samaccountname).licenses.AccountSkuId | foreach{
                        Set-MsolUserLicense -UserPrincipalName $Samaccountname -RemoveLicenses $_
                        }
                    Remove-ADUser -Identity $departing_username -Confirm:$False
                    Remove-MsolUser -Identity $Samaccountname "$Samaccountname" -Force
                    }

                    #synch ad + office365
                    powershell -file "C:\AzureDirectoryConnectSync\execute_dirsync.ps1"
                    
                 #}
                

        #code to deal with departing user data       
        do{
            $keepdata = (read-host "Are we keeping departing user's data (Y/N)").ToUpper()
            }
        while ("Y","N" -notcontains $keepdata)
        $Samaccountname = $departing_username+"@yourdomain.xyz"
        $hades = "Departed Users"
        
        if ($KeepData -eq 'Y'){

            Do {
                $data_destination = (read-host "Who should we copy departing user's data to [e.g. Bruce.Lee]")
                if ($data_destination -eq $departing_username){
                    write-warning "Really? Departing user and user to copy data to are one and the same? Stupid M@#$%^&*!!"
                    Exit 1
                    }
                $namecheck = $(try { Get-ADUser $data_destination } catch { $null })
                if ($namecheck -eq $Null){
                    write-host "An AD account for $data_destination was not found. Try again"
                    Exit 1
                    }
                else {
                    write-host "Account for $data_destination was found"
                    read-warning "About to move $departing_username's data to $data_destination's H drive"
                    write-host "Press <ENTER> to continue or press (Ctrl + C) to abort"
                    
                    #set vars for fileserver share paths
                    $file_server = "FILESERVER"
                    $file_server_home_unc = "\\FILESERVER\users$\"
                    $file_server_desktop_unc = "\\FILESERVER\Desktop\"
                    $file_server_documents_unc = "\\FILESERVER\Documents\"
                    
                    $departed_home_unc = "$file_server_home_unc$departing_username"
                    $departed_desktop_unc = "$file_server_desktop_unc$departing_username"
                    $departed_documents_unc = "$file_server_documents_unc$departing_username"

                    #set var for destination user data paths
                    $destination_user_home = "$file_server_home_unc$data_destination"
                    
                    #create token and connect to file server
                    $s = New-PSSession -ComputerName $file_server -Credential $env:Userdomain\$env:UserName
                    Invoke-Command -ComputerName $file_server -Credential $s -ScriptBlock {
                        
                        #Create a folder on destination user's H drive
                        New-Item -ItemType directory -Path $destination_user_home$departing_username
                        
                        #confirm that destination folder exists, copy departing user's data
                        #then delete source data
                        if (Test-Path $destination_user_home$departing_username){
                            $copyto = "$destination_user_home$departing_username"
                            $departed_home_unc, $departed_desktop_unc, $departed_documents_unc | where {(Test-Path $_)} | foreach {Copy-Item $_  -Destination $copyto -force -Recurse -Confirm:$false | out-null}
                            $departed_home_unc, $departed_desktop_unc, $departed_documents_unc | where {(Test-Path $_)} | foreach {Remove-Item $_  -force -Recurse -Confirm:$false | out-null}
                            write-host""
                            read-host $departing_username+"'s data have been copied into "+ $data_destination +"'s H drive"
                            write-host""
                            Write-host ... $Samaccountname is member of these AD Groups -fore Yellow
                            Get-ADPrincipalGroupMembership -Identity  $Samaccountname | Format-Table -Property name -ErrorAction SilentlyContinue
                            Write-host -BackgroundColor DarkGreen "Removing the Group Membership" -fore DarkYellow
                            Get-ADPrincipalGroupMembership $Samaccountname | foreach { Remove-ADGroupMember $_ -Members $Samaccountname -Confirm:$false } -ErrorAction SilentlyContinue
                            write-host -BackgroundColor DarkGreen "Disabling account"
                            Disable-ADAccount -Identity $Samaccountname

                            # Generate random password
                            $Password = ([char[]]([char]33..[char]95) + ([char[]]([char]97..[char]126)) + 0..9 | sort { Get-Random })[0..11] -join ''
                            
                            # Set random password for user
                            Set-ADAccountPassword -Identity $departing_username -NewPassword (ConvertTo-SecureString -AsPlainText "$Password" -Force)
                            #set user change pass at nextlogon
                            write-host -BackgroundColor DarkGreen"Setting user must change password at next logon"
                            Set-ADUser -Identity $departing_username -ChangePasswordAtLogon $true
                            
                            #move account to departed users OU
                            write-host -BackgroundColor DarkGreen"Moving ", $departing_username, " to Departed Users OU"
                            Get-ADUser -Identity $departing_username | Move-ADObject -TargetPath "OU=$hades,DC=projectrenewal,DC=org"
                            Write-Host -BackgroundColor DarkGreen"User ", $departing_username, " disabled"
                            read-host "Mail procesing is next. Press Enter to continue.."
                            
                            #Remove-Variable * -ErrorAction SilentlyContinue
                            }
                            } 
                            return
                            }
                        }
            while (-!($namecheck))
                }
                
                if ($KeepData -eq 'N'){
                    #code here to remove departing user's data
                    write-warning "All $departing_username's data will be deleted"
                    read-host "Press <ENTER> to continue or press <CTRL + C> to cancel"

                    $Samaccountname = "$departing_username@yourdomain.xyz"

                    #vars for the file server paths
                    $server_home_dir = "\\FILESERVER\users$\"
                    $server_desktop_dir = "\\FILESERVER\destops\"
                    $server_docs_dir = "\\FILESERVER\documents\"

                    write-host ""
                    write-host "Setting vars to $departing_username's network folders"
                    $home_dir = "$server_home_dir$departing_username"
                    $Desktop_dir = "$server_destktop_dir$departing_username"
                    $Document_dir = "$server_docs_dir$departing_username"
                    
                    write-host ""
                    write-host "Deleting $departing_username's network folders..."
                    $home_dir, $Desktop_dir, $Document_dir | where {(Test-Path $_)} | foreach {Remove-Item $_  -force -Recurse -Confirm:$false | out-null}

                     write-host -BackgroundColor DarkGreen " Done deleting ",$departing_username, "'s data"
                }
                               
     } #bracket for term choice
    
################# end of user off-boarding ################


############ Choice 'A'  Add lic module is run ########

        'A' {'Adding O365 lic module invoked'
        do {

            try {
                $upn = read-host "Email Address to add office365 lic to, e.g. 'bruce.lee@yourdomain.xyz'"

                write-host -BackgroundColor DarkGreen"checking if $upn exist"
                $User = Get-MsolUser -UserPrincipalName $upn -ErrorAction SilentlyContinue
                If ($User -ne $Null){ 

                    Set-MsolUser -UserPrincipalName  "$upn" -UsageLocation US
                    Set-MsolUserLicense -UserPrincipalName "$upn" -AddLicenses "YOURDOMAIN:Win10_VDA_E3" 
                    Set-MsolUserLicense -UserPrincipalName "$upn" -AddLicenses "YOURDOMAIN:ATP_ENTERPRISE" 
                    Set-MsolUserLicense -UserPrincipalName "$upn" -AddLicenses "YOURDOMAIN:ENTERPRISEPACK"
                    Set-MsolUserLicense -UserPrincipalName "$upn" -AddLicenses "YOURDOMAIN:DEFENDER_ENDPOINT_P1"

                    Start-Sleep -s 10

                    write-host -BackgroundColor DarkGreen "displaying lics applied to $upn"
                    (Get-MsolUser -UserPrincipalName $upn).licenses.accountskuid
                    Start-Sleep -s 10

                    }
                Else {
                    write-host "Sorry but $upn was not found. Check your speeling and try again. Good bye"
                    Start-Sleep -s 10
                    }
                }
            catch { 
                $message = $_
                Write-Warning "Crap!, ran into an issue $message"
                Start-Sleep -s 10
            }
            }
        while ($upn -eq $Null)
        


        }#end bracket for choice 3
################### End office 365 lic module ##############

 
################  start O365 Licenses retrieval module ###########
        'V' {'O365 lic retrieval module invoked'
           
            do {
                try {
                    
                    $upn1 = (read-host "Enter username to view assigned lics for, e.g. [Bruce.Lee]")
                    $domain = "@yourdomain.xyz"
                    $upn2 = "$upn1$domain"
                    write-host ""
                    $User = Get-MsolUser -UserPrincipalName $upn2 -ErrorAction SilentlyContinue
                    If ($user -ne $Null){ 
                        write-host -BackgroundColor DarkGreen "User: $upn1 is an active user, and has the following O365 lics applied:"
                        write-host""
                        (Get-MsolUser -UserPrincipalName $upn2).licenses.accountskuid
                        read-host "Press <Enter> to go back to main menu"
                        }
                    Else {
                        write-host "$upn1 not found. Check your spelling and try again." 
                        read-host "Press <Enter> to go back to main menu"
                        }
                    }
                Catch {
                    $message = $_
                    Write-Warning "$upn1 not found. Or maybe: $message"
                    }
                }
            while ($upn1 -eq $Null)
        
        }#4th choice end bracket




######## start of choice that lists groups memberships ########

          'G' {'Group membership module invoked'
          
          do {
            
              try {
                $gpname = (read-host "Enter username to view group memberships for, e.g. [Bruce.Lee]")

                $User = $(try {Get-ADUser $gpname} catch {$null})
                If ($User -ne $Null) {
                    Get-ADPrincipalGroupMembership $gpname | select-object name
                    write-host "back to menu in 10 secs"
                    start-sleep -s 10


                } Else {
                    "User not found in AD"}
                    Start-Sleep -s 5

                }                     
              Catch {
                    $message = $_
                    Write-Host $gpname, " not found. Or maybe: ", $message
                    read-host "some shit happened"
                    
                }
            }
            
              
        while ($user -eq $Null)

          } #end of module show groups members
          
        

####### End of group list module #############




#######copy group module starts here ###########
        'X' {'Group copy module invoked'
        write-host "This script helps you copy groups membershipt from user1 to user2." -BackgroundColor DarkYellow
        write-host""
        $copyFrom = read-host "Copy group membership from user, e.g. [Joe.Jackson]"
        $copyTo = read-host "Paste $copyfrom groups to, e.g. [Shintaro.Katsu]"
        $source = $(try {Get-ADUser $copyfrom} catch {$Null})
        $dest = $(try {Get-ADUser $copyto} catch {$Null})
        If ($source -ne $Null -and ($dest -ne $Null)){
            Get-ADUser -Identity $copyFrom -Properties memberof -Verbose | Select-Object -ExpandProperty memberof -Verbose | Add-ADGroupMember -Members $copyTo -PassThru -Verbose
            clear-host
            write-host "List of groups ", $CopyFrom, " is a member of:" -BackgroundColor DarkGreen
            Get-ADPrincipalGroupMembership $copyFrom | select name
            write-host""
            write-host "List of users ", $copyTo, " is a member of:" -BackgroundColor DarkGreen
            Get-ADPrincipalGroupMembership $copyTo | select name
            } 
        Else {
            write-host "Sorry but both $copyfrom and $copyto must exist in AD" -BackgroundColor DarkRed
            }

        
        } #Group copy choice closing bracket
        
############### end of group copy module ############


    #reset MFS module
    'M' {"MFA Reset module invoked"
    $mfauser = read-host "Enter username to reset MFA for e.g. [Bruce.Lee]"

    $mfacheck = $(try {Get-ADUser $mfauser} catch {$Null})
        If ($mfacheck -ne $Null){

            $upn = "$mfauser@yourdomain.xyz"
            $u=Get-MsolUser -UserPrincipalName "$upn"
            $u.StrongAuthenticationMethods
            write-host "Strong authentication methods are shown above"
            $p=@()
            Set-MsolUser -UserPrincipalName "$upn"-StrongAuthenticationMethods $p
            $u=Get-MsolUser -UserPrincipalName "$upn"
            $u.StrongAuthenticationMethods
            write-host
            write-host "Strong authentication methods should return no value"
             write-host
             Write-Host "Now ask user to go to https://aka.ms/mfasetup"
             write-host
             write-host "and register a new MFA number"
            }
        else {
            clear-host
            wriite-host "$mfauser not found. Chech name and try again"
            }
        } ### end of MFA reset module ###########


#start of spooler clearing module

'R' {"Spooler reset module invoked"

clear-host
write-host "Brought to you by the 176 years old: Hector Abreu"

write-host ""

Write-Warning "This program will clean-up the spooler on all print servers." -WarningAction Inquire

$servers = "printserver1","printserver2","printserver3"
$root = (Get-ChildItem Env:\USERNAME).Value
write-host""

Invoke-Command -ComputerName $servers  -Credential $root -ScriptBlock  {
    & {
     Get-Service *spool* | Stop-Service -Force -Verbose
     Start-Sleep -Seconds 90
     $path = $env:SystemRoot + "\system32\spool\printers\"
     Get-ChildItem $path -File | Remove-Item -Force -Verbose
     Start-Sleep -Seconds 180
     Get-Service Spooler | Start-Service -Verbose
     start-sleep -seconds 60
    }}


write-host""
write-host "spooler service restarted on all print servers."
write-host""
write-host "Check with users to make sure they are able to print."
write-host""
write-host "George Orwell - 1984"
write-host""
write-host "War is peace" -ForegroundColor black -BackgroundColor green
write-host""
write-host "Freedom is slavery" -ForegroundColor blue -BackgroundColor white
write-host""
write-host "Ignorance is strength" -ForegroundColor white -BackgroundColor blue
write-host""
Start-Sleep -Seconds 60
} #end of print spooler cleaning


     ##Start of 'Back; menu option
     
    #reset MFS module
    'B' {"Back to menu module invoked"
            clear-host
            show-menu
        } ### end of 'Back  module ###########


    } 
    clear-host
    write-host -BackgroundColor DarkGreen "Program ended by user."

    write-host""

} Until ($selection -eq 'q')


#uncoment the following line to clear MsolService session on program exit
#[Microsoft.Online.Administration.Automation.ConnectMsolService]::ClearUserSessionState()


<#
as you can see there is a lot of code here. I did the best I could to document any section
I thought may need explaining.

You can stay with VBS or any other scripting code as long as it allowes you to do what you need.

It is all in the results.  If a few lines of CPM code allowes you to do what you need, then CPM away!

If you need me to look / review your code just let me know.

LASTLY: IMPROVE AND SHARE. NEVER BE AFRAID OF SHOWING THAT YOU DO NOT KNOW SOMETHING.

I'VE LIVED WITH MY GOOD FRIEND 'JACK' ALL OF MY LIFE, BUT SOMETIMES I ASK MYSELF:

"DO I REALLY KNOW HIM?"

THE ANSWER IS 'NO', I DO NOT KNOW 'JACK'

LAST LESSON: "HERE TODAY. GONE TOMORROW". MOST OF WHAT YOU AND I TAKE SO SERIOUSLY; AND OFTTEN
BACK-STABB OTHERS FOR, MEANS 'NOTHING'. THE ONE STANDING IN FRONT OF YOU IS YOUR TEACHER YOU ST#$%^&*& MO#$%^&* FU%^&!!

ENJOY YOUR SHORT LIFE, RESPECT AND CARE FOR THE PEOPLE AROUND YOU.. AND, AND.. BE GRATEFUL
THAT YOU FOUND A PARTNER WHO PUTS UP WITH YOUR BS. YOU'LL SOON BE DEAD AND FORGOTTEN.

HACK THIS CODE AND THEN SHARE WITH ME SO I CAN LEARN FROM YOU.

HECTOR ABREU, SEPTEMBER 12TH, 2022
#>