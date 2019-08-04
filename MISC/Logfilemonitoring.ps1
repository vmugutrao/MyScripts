#Script to monitor services and corresponding log file.

$Services = $null
$Services = (@{ServiceName="server";LogPath="c:\temp\server.txt"},`
@{ServiceName="Dnscache";LogPath="c:\temp\Dnscache.txt"})
$Services = $Services | ForEach-Object { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru }
$Output = @()
$Properties = @{ServiceName='';Service_Status='';LogFile_Status=''} 

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

if(($Output.Service_Status -contains '*Not*') -or ($Output.LogFile_Status -contains 'Not'))
    {
    Write-Host 'Sending email'
}
