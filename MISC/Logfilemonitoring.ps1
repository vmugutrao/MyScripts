#Script to monitor services and corresponding log file.

#Define Variables
$To = 'to@abc.com'
$From = 'from@abc.com'
$Subject = "Service monitoring On $(Get-date -Format dd-MMM-yy )"
$SMTP = 'mail.abc.com'

$Services = $null
$Services = (@{ServiceName="server";LogPath="c:\temp\server.txt"},`
@{ServiceName="Dnscache";LogPath="c:\temp\Dnscache.txt"})
$Services = $Services | ForEach-Object { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru }
$Output = @()
$Properties = @{ServiceName='';Service_Status='';LogFile_Status=''}

#Validating services and log fine
foreach($S in $Services)
    {
    $obj = $null
    $obj = New-Object -TypeName psobject -Property $Properties
    $obj.ServiceName = $($S.ServiceName) 
    $SrvCheck = $null
    $SrvCheck = Get-Service $($S.ServiceName) -ErrorAction SilentlyContinue
    if($SrvCheck.Status -eq 'Running')
        {
        Write-Verbose "$($S.ServiceName) is running"
        $obj.Service_Status = 'Running'
        $modifycheck = Get-ChildItem $($S.LogPath)
        If($modifycheck.LastWriteTime -ge (Get-Date).AddMinutes('-10'))
            {
            Write-Verbose "Log file for $($S.ServiceName) is working"
            $obj.LogFile_Status = 'Okay'
        }
        else 
            {
            Write-Verbose "Log file for $($S.ServiceName) is not working"
            $obj.LogFile_Status = 'Not Okay'
        }
    }
    else {
         Write-Verbose "$($S.ServiceName) is not running"
         $obj.Service_Status = 'Not Running'
         $obj.LogFile_Status = 'Not Okay'
    }
    $Output += $obj
}

#Sending Email if any problem
$style = "<style>BODY{font-family: Cambria; font-size: 10pt;}"
$style = $style + "TABLE{border: 1px solid black; border-collapse: collapse;}"
$style = $style + "TH{border: 2px solid black; background: #0099ff; padding: 6px; }"
$style = $style + "TD{border: 1px solid black; padding: 6px; }"
$style = $style + "</style>"
$Body = $Output | ConvertTo-HTML -head $style -body "<H2>Service & Log monitoring</H2>"
if(($Output.Service_Status -like 'Not Running*') -or ($Output.LogFile_Status -contains 'Not Okay'))
    {
    Write-Host 'Sending email'
    Send-MailMessage -To $To -From $From -Subject $Subject -Body ($Body | Out-String) -BodyAsHtml -SmtpServer $SMTP -Priority High
}
