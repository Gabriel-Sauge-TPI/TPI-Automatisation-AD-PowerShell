Add-Type -AssemblyName System.Web
Import-Module ActiveDirectory

# Chemin vers le CSV minimaliste
$csvPath = ".\Template-Users-AD.csv"

# Chemin vers le fichier de log
$LogPath = ".\ADCreation-Log.txt"

# Importer les utilisateurs depuis CSV
$users = Import-Csv -Path $csvPath -Delimiter ','

foreach ($user in $users) {

    # Génération automatique des attributs
    $GivenName = $user.GivenName
    $Surname = $user.Surname
    $Description = $user.Description
    $employeeID = $user.employeeID
    $employeeNumber = $user.employeeNumber
    $Groups = $user.groups.Split(';')

    # Définition de l'UPN et mailNickname selon type de compte
    $UPNSuffix = "tpi.bs.ch"
    if ($Description -like "*Student*") {
        $UserPrincipalName = ($GivenName + "_" + $Surname + "@" + $UPNSuffix).ToLower()
        $mailNickname = ($GivenName + "_" + $Surname).ToLower()
        $extensionAttribute9 = "Student, Nord Anglia Test School 01"
        $extensionAttribute10 = "Office365_A5_Students_withExchangeOnline"
        $OU = "OU=Students,OU=Users,OU=TPI BS,DC=tpi,DC=bs,DC=ch"
    }
    elseif ($Description -like "*Teacher*") {
        $UserPrincipalName = ($GivenName + "." + $Surname + "@" + $UPNSuffix).ToLower()
        $mailNickname = ($GivenName + "." + $Surname).ToLower()
        $extensionAttribute9 = "Teacher, Nord Anglia Test School 01"
        $extensionAttribute10 = "Office365_A5_Teachers_withExchangeOnline"
        $OU = "OU=Teachers,OU=Users,OU=TPI BS,DC=tpi,DC=bs,DC=ch"
    }
    elseif ($Description -like "*Administration*") {
        $UserPrincipalName = ($GivenName + "." + $Surname + "@" + $UPNSuffix).ToLower()
        $mailNickname = ($GivenName + "." + $Surname).ToLower()
        $extensionAttribute9 = "Administration, Nord Anglia Test School 01"
        $extensionAttribute10 = "Office365_A5_Admins_withExchangeOnline"
        $OU = "OU=Administration,OU=Users,OU=TPI BS,DC=tpi,DC=bs,DC=ch"
    }

    # Autres attributs automatiques
    $Email = $UserPrincipalName
    $Cn = "$GivenName $Surname"
    $proxyAddresses = "SMTP:" + $Email
    $msRTCSIPPrimaryUserAddress = "sip:" + $Email
    $targetAddress = $Email
    $legacyExchangeDN = "/o=BeauSoleil/ou=Exchange Administrative Group/cn=" + $mailNickname
    $Password = ([System.Web.Security.Membership]::GeneratePassword(12,3))

    # Vérification optionnelle du sAMAccountName
    if ($user.sAMAccountName -and $user.sAMAccountName -ne "") {
        $SamAccountName = $user.sAMAccountName
    } else {
        $SamAccountName = $mailNickname
    }

    # Création utilisateur AD
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
            mailNickname=$mailNickname;
            proxyAddresses=$proxyAddresses;
            targetAddress=$targetAddress;
            msRTCSIPPrimaryUserAddress=$msRTCSIPPrimaryUserAddress;
            legacyExchangeDN=$legacyExchangeDN;
            extensionAttribute9=$extensionAttribute9;
            extensionAttribute10=$extensionAttribute10;
            msExchRecipientTypeDetails=128;
            msExchPoliciesExcluded="{26491cfc-9e50-4857-861b-0cb8df22b5d7}";
            msExchHideFromAddressLists=$false
        }

    # Ajout aux groupes AD
    foreach ($group in $Groups) {
        Add-ADGroupMember -Identity $group -Members $SamAccountName
    }

    # Affichage pour confirmation
    Write-Host "Utilisateur créé : $Cn | UPN: $UserPrincipalName | Mot de passe : $Password"

    # Écriture dans le fichier log
    $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | Utilisateur créé : $Cn | UPN : $UserPrincipalName | sAMAccountName : $SamAccountName | Groupes : $($Groups -join ',')"
    Add-Content -Path $LogPath -Value $logEntry
}
