$ErrorActionPreference = "silentlycontinue"
$userinput = ".\userlist.csv"
$report = ".\user_creation_report.csv"
$configfile = ".\config.cfg"

$ou = ((Get-Content $configfile | Select-String 'OUName=') -split 'OUName=')[-1]
$domain = ((Get-Content $configfile | Select-String 'DomainName') -split '=')[-1]


$scriptpath = $PSScriptRoot
set-location $scriptpath
$userlist = import-csv $userinput

'"SamAccountName","Password","Remark"' | Out-File $report -Encoding utf8

function New-Password {
    [CmdletBinding()]
    [OutputType([String])]
    Param()
    [int]$PasswordLength = 8
    [String[]]$InputStrings = @('abcdefghijklmnopqrstuvwxyz','ABCEFGHJKLMNPQRSTUVWXYZ', '23456789' , '#@%!')
    Function Get-Seed{
            $RandomBytes = New-Object -TypeName 'System.Byte[]' 4
            $Random = New-Object -TypeName 'System.Security.Cryptography.RNGCryptoServiceProvider'
            $Random.GetBytes($RandomBytes)
            [BitConverter]::ToUInt32($RandomBytes, 0)
            }
    $Password = @{}
    $CharGroups = $InputStrings
    $AllChars = $CharGroups | ForEach-Object {[Char[]]$_}
    Foreach($Group in $CharGroups) 
            {
                    if($Password.Count -lt $PasswordLength) {
                        $Index = Get-Seed
                        While ($Password.ContainsKey($Index)){
                        $Index = Get-Seed                        
                    }
                    $Password.Add($Index,$Group[((Get-Seed) % $Group.Count)])
                }
            }
    for($i=$Password.Count;$i -lt $PasswordLength;$i++) {
    $Index = Get-Seed
    While ($Password.ContainsKey($Index)){
    $Index = Get-Seed                        
    }
    $Password.Add($Index,$AllChars[((Get-Seed) % $AllChars.Count)])
    }
    [String]$Pass = $(-join ($Password.GetEnumerator() | Sort-Object -Property Name | Select-Object -ExpandProperty Value))
    return $Pass
}

$userlist | foreach {

    $FirstName = $_.FirstName
    $LastName = $_.LastName
    $department = $_.Department
    $Description = $_.Description
    $pass = New-Password
    $Secure_String_Pwd = ConvertTo-SecureString $pass -AsPlainText -Force
    $username = $FirstName + " " + $LastName
    $samaccountname = $FirstName + "." + $LastName
    $userprincipalname = $samaccountname + "@$domain"
    $userexists = $null
    $userexists = Get-ADUser $samaccountname
    if($userexists -eq $null)
    {
        New-ADUser -Name $username -DisplayName $username `
             -GivenName $FirstName -Surname $LastName `
             -SamAccountName $samaccountname `
             -UserPrincipalName $userprincipalname `
             -Department $department  `
             -Path $ou `
             -AccountPassword $Secure_String_Pwd `
             -Description $Description `
             -Enabled $true `
             -ChangePasswordAtLogon $true

        $usercheck = $null
        $usercheck = Get-ADUser $samaccountname
        if($usercheck -eq $null)
        {
            """$samaccountname"","""",""Failed To Create User"""| out-file $report -Append -Encoding utf8
        }
        else
        {
            $sam = $usercheck.SamAccountName
            """$sam"",""$pass"",""Success""" | out-file $report -Append -Encoding utf8

        }

    }
    else
    {
        """$samaccountname"","""",""User already Exists""" | out-file $report -Append -Encoding utf8

    }

}