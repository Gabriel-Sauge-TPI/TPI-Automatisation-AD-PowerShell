
# Projet TPI - Automatisation complète de la création d'utilisateurs Active Directory avec PowerShell

## Introduction

Ce projet a pour objectif d'automatiser intégralement la création de comptes utilisateurs dans Active Directory (AD) à l'aide d'un script PowerShell et d'un fichier CSV structuré.

## Fonctionnalités principales

- **Automatisation intégrale** : Aucune intervention manuelle requise après lancement.
- **Mots de passe sécurisés** : Génération automatique de mots de passe robustes (12 caractères incluant majuscules, minuscules et caractères spéciaux).
- **Gestion des attributs AD** : Tous les attributs requis par Active Directory sont automatiquement configurés.
- **Placement automatique dans les OUs** : Placement des utilisateurs selon leur type dans les unités organisationnelles correspondantes.
- **Ajout automatique aux groupes** : Attribution automatique des groupes spécifiques selon les rôles utilisateurs.
- **Journalisation complète** : Un fichier log détaillé est généré à chaque exécution pour le suivi et la traçabilité.
- **Idempotence garantie** : Le script peut être exécuté plusieurs fois sans doublons ni erreurs.

## Prérequis

### Logiciels et environnements

- Windows Server 2022 avec Active Directory activé
- Windows 10 ou supérieur pour le poste client
- PowerShell version 7.x ou supérieur
- Module Active Directory (RSAT installé)

## Installation

### 1. Préparer l'environnement

```powershell
Install-WindowsFeature RSAT-AD-PowerShell
Set-ExecutionPolicy RemoteSigned
```

### 2. Télécharger les fichiers nécessaires

Déposez les fichiers suivants dans `C:\Scripts\Create-ADUsers` :

- `Create-ADUsers.ps1`
- `Template-Users-AD-final-corrected.csv`

## Exécution du script

Ouvrir PowerShell en mode administrateur.

```powershell
cd C:\Scripts\Create-ADUsers
.\Create-ADUsers.ps1
```

## Gestion des logs

Chaque exécution génère un fichier de log détaillé (`creation_log.txt`) dans le même répertoire.

## Structure du script

- **Importation et vérification** : Module AD et fichier CSV.
- **Traitement des données** : Génération d'attributs automatiques.
- **Création et placement** : Création utilisateur, placement dans OU, ajout aux groupes.

## Exemples d'utilisation

Vérifier la création d'un utilisateur :

```powershell
Get-ADUser john.doe -Properties * | Format-List
```

Vérifier les logs :

```powershell
Get-Content creation_log.txt
```

## Bonnes pratiques

- Sauvegardez vos fichiers CSV après utilisation.
- Vérifiez régulièrement les logs.
- Maintenez vos scripts à jour sur GitHub.

## Perspectives d'évolution

- Gestion automatisée du cycle complet des comptes utilisateurs.
- Interface graphique simplifiée.
- Intégration Microsoft 365.

## Support

Yan Pianaro  
Email : yan.pianaro@beausoleil.ch  
Téléphone : +41 79 618 69 26  
