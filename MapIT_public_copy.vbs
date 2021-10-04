'This script was written by Hector Abreu October 3rd 2021
'Hack as needed but please do not remove these commends
'$$Declaring variables$$
Dim strDriveLetter, strUserName, strUNCpath, strUser, objShell, objNetwork, fso

'$$Settings system + network env$$
Set objShell = CreateObject("WScript.Shell")
Set objNetwork = CreateObject("WScript.Network")

'$$Assigning var values$$
strDriveLetter = "X:"
strUNCpath = "path_to_network_folder\".. e.g. "\\server\shares$\"

'$$Getting username + mappiong drive$$
strUser =objNetwork.UserName
On Error Resume Next
objNetwork.MapNetworkDrive strDriveLetter, strUNCpath & struser, True

'$$Getting list of groups user is memberof$$
Set fso = CreateObject("Scripting.FileSystemObject")
Set objUser = CreateObject("ADSystemInfo")
Set objCurrentUser = GetObject("LDAP://" & objUser.UserName)
strGroup = LCase(Join(objCurrentUser.MemberOf))

'$$ Map printer depending on user group membership$$
If InStr(strGroup, lcase("name_of_1st_group")) And InStr(strGroup,lcase("name_of_2nd_group")) Then
objNetwork. Addwindowsprinterconnection "\\printerserver\print_share_name"
objNetwork.SetDefaultPrinter "\\printerserver\print_share_name"
End If

'$$ claning up Vars$$
set objNetwork = Nothing
set strDriveLetter = Nothing
set strUserName = Nothing
set strUNCpath = Nothing
set strUser = Nothing
set fso = Nothing
set objShell = Nothing
