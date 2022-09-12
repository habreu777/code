clear-host

<#
$f = new-object System.IO.FileStream c:\temp\test.dat, Create, ReadWrite
$f.SetLength(100MB)
$f.Close()
#>

clear-host

<#
$f = new-object System.IO.FileStream c:\temp\test.dat, Create, ReadWrite
$f.SetLength(100MB)
$f.Close()
#>

$src = "\\tools\Software\eClinicalWorks\"
$dest = "c:\temp\"

Write-Output "Backups started at $(Get-Date)"
$StartDate=(GET-DATE)
Robocopy /mir $src $dest /e /w:1 /r:1 /tee /np /XO
$EndDate=(GET-DATE)
Write-Output "Backups completed at $(Get-Date)"

$diff = NEW-TIMESPAN -Start $StartDate -End $EndDate
Write-Output "Time difference is: $diff"
$diff
#time it took to copy the folder
write-host "Copying the folder took: ",$diff.Minutes, "minutes and ", $diff.Seconds, " seconds"