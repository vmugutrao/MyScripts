
$Check = $null
$Installpath = "\\mybeast\Fileshare\Common\Deployments\CompassConsole\UAT\Releases\Setup.exe"
$RegPath = "HKCU:Software\Microsoft\Windows\CurrentVersion\Uninstall\CompassConsoleUAT"
$Logfile = "$($env:USERPROFILE)\Desktop\Compassinstall.log"

Add-Content $Logfile "$(Get-Date) : Comppas Console app installation Started !!!" -Force -ErrorAction SilentlyContinue
$Check
If(Test-Path $RegPath)
    {
    Add-Content $Logfile "$(Get-Date) : Comppas Console app is already installed, No action Taken !! " -Force -ErrorAction SilentlyContinue
    }
Else
    {
    Try 
        { 
         & $Installpath
         Add-Content $Logfile "$(Get-Date) : Comppas Console app installed successfully" -Force -ErrorAction SilentlyContinue
        }
     Catch
        {
        Add-Content $Logfile "$(Get-Date) : Comppas Console app installation Failed" -Force -ErrorAction SilentlyContinue
        Add-Content $Logfile "Error: $($Error[0].Exception.InnerException)" -Force -ErrorAction SilentlyContinue
        }
    }

    
