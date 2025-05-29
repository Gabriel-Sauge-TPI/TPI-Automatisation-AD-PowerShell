# ==============================================
# Script : Create-ADUsers.ps1
# Auteur : Gabriel Sauge
# Objectif : Automatisation création utilisateurs
# dans Active Directory depuis un fichier CSV.
# ==============================================

# Importer les utilisateurs depuis un fichier CSV
$users = Import-Csv -Path "C:\Users\Administrator\Downloads\TPI\Template-Users-AD.csv"

# Boucle sur chaque utilisateur du fichier CSV
foreach ($user in $users) {

    # Importation de l'assembly nécessaire pour générer les mots de passe
    Add-Type -AssemblyName System.Web

    # Vérification si un mot de passe est spécifié dans le CSV
    if ([string]::IsNullOrWhiteSpace($user.Password)) {
        # Génération automatique du mot de passe sécurisé (12 caractères, complexe)
        $generatedPassword = [System.Web.Security.Membership]::GeneratePassword(12, 3)
        Write-Host "Mot de passe généré pour $($user.Cn) :" $generatedPassword -ForegroundColor Yellow
    }
    else {
        # Utilisation du mot de passe spécifié dans le CSV
        $generatedPassword = $user.Password
        Write-Host "Mot de passe spécifié pour $($user.Cn) :" $generatedPassword -ForegroundColor Cyan
    }

    # Détermination du type de compte (student ou staff) pour appliquer la nomenclature exigée
    if ($user.groups -like "*students_CBS*") {
        # Format prenom_nom pour les élèves
        $accountName = ($user.GivenName + "_" + $user.Surname).ToLower()
    }
    else {
        # Format prenom.nom pour les membres du staff
        $accountName = ($user.GivenName + "." + $user.Surname).ToLower()
    }

    # Construction automatique des attributs AD selon la nomenclature
    $userPrincipalName = "$accountName@tpi.bs.ch"
    $emailAddress = $userPrincipalName

    # Conversion du mot de passe en SecureString requis par Active Directory
    $SecurePwd = ConvertTo-SecureString $generatedPassword -AsPlainText -Force

    # Paramètres complets pour la création du compte utilisateur
    $NewADUserParams = @{
        GivenName         = $user.GivenName
        Surname           = $user.Surname
        Name              = $user.Cn
        DisplayName       = $user.Cn
        Description       = $user.Description
        AccountPassword   = $SecurePwd
        Enabled           = $true
        SAMAccountName    = $accountName
        UserPrincipalName = $userPrincipalName
        EmailAddress      = $emailAddress
        Path              = if ($user.groups -like "*administration_CBS*") {
                                "OU=Administration,OU=CBS Users,DC=tpi,DC=bs,DC=ch"
                            } elseif ($user.groups -like "*teachers_CBS*") {
                                "OU=Teachers,OU=CBS Users,DC=tpi,DC=bs,DC=ch"
                            } elseif ($user.groups -like "*students_CBS*") {
                                "OU=Students,OU=CBS Users,DC=tpi,DC=bs,DC=ch"
                            } else {
                                "CN=Users,DC=tpi,DC=bs,DC=ch"
                            }
        OtherAttributes = @{
            employeeID     = $user.employeeID
            employeeNumber = $user.employeeNumber
        }
    }

    # Tentative de création de l'utilisateur dans l'Active Directory
    try {
        New-ADUser @NewADUserParams
        Write-Host "Utilisateur $($user.Cn) créé avec succès." -ForegroundColor Green
        Write-Host "Nom du compte créé :" $accountName -ForegroundColor Cyan

        # Ajouter l'utilisateur aux groupes AD spécifiés dans le CSV
        $groups = $user.groups -split ";"
        foreach ($group in $groups) {
            Add-ADGroupMember -Identity $group -Members $accountName -ErrorAction Stop
            Write-Host "Ajouté au groupe : $group" -ForegroundColor Cyan
        }
    }
    catch {
        # Affichage précis de l'erreur en cas d'échec de création
        Write-Host "Erreur lors de la création de l'utilisateur $($user.Cn) : $_" -ForegroundColor Red
    }
}
