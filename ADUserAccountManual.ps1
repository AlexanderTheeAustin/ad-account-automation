<#
.SYNOPSIS
    Creates a single Active Directory user manually and optionally adds the user to groups.

.DESCRIPTION
    This script prompts for user details, creates a new AD account,
    enables it, and optionally assigns group membership.

.NOTES
    Replace placeholder values before using in a production environment.
    Do not upload real domains, passwords, or internal naming conventions to GitHub.
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
    [string]$OUPath,

    [Parameter(Mandatory = $true)]
    [string]$Password,

    [Parameter(Mandatory = $false)]
    [string[]]$Groups
)

Import-Module ActiveDirectory -ErrorAction Stop

try {
    $DisplayName = "$FirstName $LastName"
    $SamAccountName = ($FirstName.Substring(0,1) + $LastName).ToLower()
    $UserPrincipalName = "$SamAccountName@domain.local"
    $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force

    $ExistingUser = Get-ADUser -Filter "SamAccountName -eq '$SamAccountName'" -ErrorAction SilentlyContinue
    if ($ExistingUser) {
        Write-Warning "User already exists: $SamAccountName"
        exit 1
    }

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
        -AccountPassword $SecurePassword `
        -Enabled $true `
        -ChangePasswordAtLogon $true

    Write-Host "Created user: $DisplayName" -ForegroundColor Green

    if ($Groups) {
        foreach ($Group in $Groups) {
            try {
                Add-ADGroupMember -Identity $Group -Members $SamAccountName -ErrorAction Stop
                Write-Host "Added $SamAccountName to group: $Group" -ForegroundColor Cyan
            }
            catch {
                Write-Warning "Failed to add $SamAccountName to group '$Group': $($_.Exception.Message)"
            }
        }
    }
}
catch {
    Write-Error "Failed to create user: $($_.Exception.Message)"
}
