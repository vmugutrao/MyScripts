#Script to monitor services and corresponding log file.

$Services = $null
$Services = (@{ServiceName="server";LogPath="c:\temp\server.txt"},`
@{ServiceName="Dnscache";LogPath="c:\temp\Dnscache.txt"})
$Services = $Services | ForEach-Object { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru }

foreach($S in $Services)
    {
    $SrvCheck = $null
    $SrvCheck = Get-Service $($S.ServiceName) -ErrorAction SilentlyContinue
    if($SrvCheck.Status -eq 'Running')
        {
         Write-Host "$($S.ServiceName) is running"
         $modifycheck = Get-ChildItem $($S.LogPath)
         If($modifycheck.LastWriteTime -ge (Get-Date).AddMinutes('-10'))
            {
            Write-Host "Log file for $($S.ServiceName) is working"
            }
        else {
              Write-Host "Log file for $($S.ServiceName) is not working"
            
        }
    }
    else {
         Write-Host "$($S.ServiceName) is not running"
    }

    }