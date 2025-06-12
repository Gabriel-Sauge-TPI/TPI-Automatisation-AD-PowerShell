
Add-Type -AssemblyName System.Web
Import-Module ActiveDirectory

$csvPath = ".\Template-Users-AD.csv"
$LogPath = ".\ADCreation-Log.txt"

$users = Import-Csv -Path $csvPath -Delimiter ','

foreach ($user in $users) {
    $GivenName = $user.GivenName
    $Surname = $user.Surname
    $Description = $user.Description
    $employeeID = $user.employeeID
    $employeeNumber = $user.employeeNumber
    $Groups = $user.groups.Split(';')

    $UPNSuffix = "tpi.bs.ch"
    if ($Description -like "*Student*") {
        $UserPrincipalName = ($GivenName + "_" + $Surname + "@" + $UPNSuffix).ToLower()
        $extensionAttribute9 = "Student, Nord Anglia Test School 01"
        $extensionAttribute10 = "Office365_A5_Students_withExchangeOnline"
        $OU = "OU=Students,OU=Users,OU=TPI BS,DC=tpi,DC=bs,DC=ch"
    }
    elseif ($Description -like "*Teacher*") {
        $UserPrincipalName = ($GivenName + "." + $Surname + "@" + $UPNSuffix).ToLower()
        $extensionAttribute9 = "Teacher, Nord Anglia Test School 01"
        $extensionAttribute10 = "Office365_A5_Teachers_withExchangeOnline"
        $OU = "OU=Teachers,OU=Users,OU=TPI BS,DC=tpi,DC=bs,DC=ch"
    }
    elseif ($Description -like "*Administration*") {
        $UserPrincipalName = ($GivenName + "." + $Surname + "@" + $UPNSuffix).ToLower()
        $extensionAttribute9 = "Administration, Nord Anglia Test School 01"
        $extensionAttribute10 = "Office365_A5_Admins_withExchangeOnline"
        $OU = "OU=Administration,OU=Users,OU=TPI BS,DC=tpi,DC=bs,DC=ch"
    }

    $Email = $UserPrincipalName
    $Cn = "$GivenName $Surname"
    $Password = ([System.Web.Security.Membership]::GeneratePassword(12,3))

    if ($user.sAMAccountName -and $user.sAMAccountName -ne "") {
        $SamAccountName = $user.sAMAccountName
    } else {
        $SamAccountName = ($GivenName.Substring(0,1) + $Surname).ToLower()
    }

    $mailNickname = $SamAccountName
    $proxyAddresses = "SMTP:" + $Email
    $legacyExchangeDN = "/o=ExchOrg/ou=Exchange Administrative Group/cn=Recipients/cn=" + $SamAccountName
    $targetAddress = "SMTP:" + $Email
    $msRTCSIPPrimaryUserAddress = "sip:" + $Email

    New-ADUser -Name $Cn `
        -GivenName $GivenName `
        -Surname $Surname `
        -Description $Description `
        -UserPrincipalName $UserPrincipalName `
        -EmailAddress $Email `
        -EmployeeID $employeeID `
        -EmployeeNumber $employeeNumber `
        -Path $OU `
        -SamAccountName $SamAccountName `
        -AccountPassword (ConvertTo-SecureString $Password -AsPlainText -Force) `
        -Enabled $true `
        -OtherAttributes @{
            msRTCSIPPrimaryUserAddress=$msRTCSIPPrimaryUserAddress;
            extensionAttribute9=$extensionAttribute9;
            extensionAttribute10=$extensionAttribute10;
            mailNickname=$mailNickname;
            proxyAddresses=$proxyAddresses;
            legacyExchangeDN=$legacyExchangeDN;
            targetAddress=$targetAddress
        }

    foreach ($group in $Groups) {
        if ($group -and $SamAccountName) {
            Add-ADGroupMember -Identity $group -Members $SamAccountName
        } else {
            Write-Warning "Utilisateur ou groupe manquant : SamAccountName='$SamAccountName', Groupe='$group'"
        }
    }

    Write-Host "Utilisateur créé : $Cn | UPN: $UserPrincipalName | Mot de passe : $Password"

    $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | Utilisateur créé : $Cn | UPN : $UserPrincipalName | sAMAccountName : $SamAccountName | Groupes : $($Groups -join ',')"
    Add-Content -Path $LogPath -Value $logEntry
}
