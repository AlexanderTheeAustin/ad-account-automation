<#
.SYNOPSIS
    Creates a new Active Directory user with basic account settings.

.DESCRIPTION
    This script automates part of the user provisioning process by creating
    a new AD account, setting a temporary password, assigning an OU, and
    enabling the account.

.NOTES
    Replace placeholder values before use in a real environment.
    Do not store real passwords or internal domain details in public repos.
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$FirstName,

    [Parameter(Mandatory = $true)]
    [string]$LastName,

    [Parameter(Mandatory = $true)]
    [string]$Department,

    [Parameter(Mandatory = $true)]
    [string]$Title,

    [Parameter(Mandatory = $true)]
    [string]$OUPath
)

# Import Active Directory module
Import-Module ActiveDirectory -ErrorAction Stop

# Build account values
$DisplayName = "$FirstName $LastName"
$SamAccountName = ($FirstName.Substring(0,1) + $LastName).ToLower()
$UserPrincipalName = "$SamAccountName@domain.local"

# Temporary password
$TempPassword = ConvertTo-SecureString "ChangeMe123!" -AsPlainText -Force

try {
    New-ADUser `
        -Name $DisplayName `
        -GivenName $FirstName `
        -Surname $LastName `
        -DisplayName $DisplayName `
        -SamAccountName $SamAccountName `
        -UserPrincipalName $UserPrincipalName `
        -Department $Department `
        -Title $Title `
        -Path $OUPath `
        -AccountPassword $TempPassword `
        -Enabled $true `
        -ChangePasswordAtLogon $true

    Write-Host "User account created successfully for $DisplayName" -ForegroundColor Green
    Write-Host "Username: $SamAccountName"
    Write-Host "UPN: $UserPrincipalName"
}
catch {
    Write-Error "Failed to create user account: $($_.Exception.Message)"
}
