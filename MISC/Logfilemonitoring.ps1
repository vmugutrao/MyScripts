#Define Variables
$To = 'vishalmugutrao@outlook.com'
$From = 'vishalmugutrao@outlook.com'
$Subject = "Service monitoring On $(Get-date -Format "dd-MMM-yy HH:mm:ss" )"
$SMTP = 'smtp-mail.outlook.com'
$Cred = Get-Credential -Message 'For email'

$Remiderfile ='C:\Temp\logmonitor.txt'
if(!(Test-Path $Remiderfile))
    {
    Set-Content $Remiderfile -Value 0 -Confirm:$false -Force -ErrorAction Stop
    }
$Remindercount = Get-Content $Remiderfile

#Variable for MS Teams Webhook notification

$Notification = @"
{
    "@context": "https://schema.org/extensions",
    "@type": "MessageCard",

    "sections": [
        {
            "facts": [
                {
                    "name": "ServerName:",
                    "value": "<ServerName>"
                },
                {
                    "name": "Services:",
                    "value": "<ServiceName>"
                },
                {
                    "name": "Reminder:",
                    "value": "<Reminder>"
                }
            ],
            "text": "Zelis compass Service & Log file monitoring alert"
        }
    ],
    "summary": "Zelis compass Service & Log file monitoring alert",
    "themeColor": "0072C6",
    "title": "Zelis Healthcare"
}
"@
#$TargetChannel = 'https://outlook.office.com/webhook/bf668094-ca33-4b88-8a13-c8e929876982@2829b063-3f75-4df6-b16d-605d30d1b7a2/IncomingWebhook/b4486ae7eeb64f65b047b47c5020626c/e198fedc-ac83-4573-bb6f-e4d8ed2a5747' #Add webhook


$ServerName = $env:COMPUTERNAME
$Services = $null
$Services = (@{ServiceName="server";LogPath="D:\Logs\Benchmark.log"},`
@{ServiceName="wuauserv";LogPath="D:\Logs\ClaimPass.log"},`
@{ServiceName="themes";LogPath="D:\Logs\SendFax.log"})
$Services = $Services | ForEach-Object { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru }
$Output = @()
$Properties = @{ServiceName='';Service_Status='NA';LogFile_Status='NA';LogTimestamp='NA';'LastWrite(in min)'='NA'}

#Validating services and log fine
foreach($S in $Services)
    {
    $Lastlog = $null
    $Current = $null
    $obj = $null
    $obj = New-Object -TypeName psobject -Property $Properties
    $obj.ServiceName = $($S.ServiceName) 
    $SrvCheck = $null
    $SrvCheck = Get-Service $($S.ServiceName) -ErrorAction SilentlyContinue
    if($SrvCheck.Status -eq 'Running')
        {
        $Current = (Get-Date).AddMinutes('-10')
        Write-Verbose "$($S.ServiceName) is running"
        $obj.Service_Status = 'Running'
        if(!(Test-Path $S.LogPath))
            {
            $obj.LogFile_Status = 'Critical - Log not found'
            }
        Else
            {
            $modifycheck = Get-ChildItem $($S.LogPath) -ErrorAction SilentlyContinue
            $Lastlog = (Get-Content $($S.LogPath) -ErrorAction SilentlyContinue | Select-Object -Last 1).split('.')[0]
            If(($modifycheck.LastWriteTime -ge $Current.DateTime) -and ($Lastlog  -ge $Current.ToString("yyyy-MM-dd HH:mm:ss")))
                {
            Write-Verbose "Log file for $($S.ServiceName) is working"
            $obj.LogFile_Status = 'Healthy'
            $obj.LogTimestamp = $Lastlog
            [int]$obj.'LastWrite(in min)' = (New-TimeSpan $Lastlog (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")).TotalMinutes
        }
            else 
                {
            Write-Verbose "Log file for $($S.ServiceName) is not working"
            $obj.LogFile_Status = 'Critical'
            $obj.LogTimestamp = $Lastlog
            [int]$obj.'LastWrite(in min)' = (New-TimeSpan $Lastlog (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")).TotalMinutes
        }
        }
    }
    else 
        {
         Write-Verbose "$($S.ServiceName) is not running"
         $obj.Service_Status = 'Not Running'
    }
    $Output += $obj
}

#Sending Email and Teams notification if any problem
$ProblematicServ = ($Output | Where-Object {($_.Service_Status -like 'Not') -or {$_.LogFile_Status -like 'Not'}}).ServiceName -join ', '

$style = "<style>BODY{font-family: Cambria; font-size: 10pt;}"
$style = $style + "TABLE{border: 1px solid black; border-collapse: collapse;}"
$style = $style + "TH{border: 2px solid black; background: #0099ff; padding: 6px; }"
$style = $style + "TD{border: 1px solid black; padding: 6px; }"
$style = $style + "</style>"
$Body = $Output | ConvertTo-HTML -head $style -body "<H2>Service & Log monitoring</H2>"
if(($Output.Service_Status -like 'Not Running*') -or ($Output.LogFile_Status -like '*Critical*'))
    {
    Try
       {
        $NotificationBody = $Notification.Replace("<ServerName>","$ServerName").Replace("<ServiceName>","$ProblematicServ").Replace("<Reminder>","$Remindercount")
        Invoke-RestMethod -Uri "$TargetChannel" -Method 'Post' -Body $NotificationBody
        }
    Catch
        {
        $Subject = "$Subject - Error with teams notification"
        }
    Write-Host 'Sending email'
    if($Remindercount -gt 0)
        {
        Send-MailMessage -To $To -From $From -Credintia $Cred -Subject "$Subject - Reminder$([int]$Remindercount)" -Body ($Body | Out-String) -BodyAsHtml -SmtpServer $SMTP -Priority High
        Set-Content $Remiderfile -Value "$([int]$Remindercount+1)" -Confirm:$false -Force
        
        }
    Else
        {
        Send-MailMessage -To $To -From $From -Credintial $Cred -Subject "$Subject" -Body ($Body | Out-String) -BodyAsHtml -SmtpServer $SMTP -Priority High
        Set-Content $Remiderfile -Value "$([int]$Remindercount+1)" -Confirm:$false -Force
        }

}
Else
    {
    Set-Content $Remiderfile -Value 0 -Confirm:$false -Force
    }