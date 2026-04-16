<#
.SYNOPSIS
    Bulk creates Active Directory users from a CSV file and optionally adds them to groups.

.DESCRIPTION
    This script imports user data from a CSV file, creates new AD accounts,
    assigns basic attributes, enables the account, and optionally adds users
    to AD security groups.

.CSV FORMAT
    FirstName,LastName,Department,Title,OUPath,Password,Groups
    John,Doe,IT,Support Technician,"OU=Users,DC=domain,DC=local","ChangeMe123!","Group1;Group2"

.NOTES
    Replace placeholder values before using in a production environment.
    Do not upload real domains, passwords, or internal naming conventions to GitHub.
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$CsvPath
)

Import-Module ActiveDirectory -ErrorAction Stop

if (-not (Test-Path $CsvPath)) {
    Write-Error "CSV file not found: $CsvPath"
    exit 1
}

$Users = Import-Csv -Path $CsvPath

foreach ($User in $Users) {
    try {
        $FirstName = $User.FirstName.Trim()
        $LastName = $User.LastName.Trim()
        $Department = $User.Department.Trim()
        $Title = $User.Title.Trim()
        $OUPath = $User.OUPath.Trim()
        $Password = $User.Password.Trim()
        $Groups = $User.Groups

        $DisplayName = "$FirstName $LastName"
        $SamAccountName = ($FirstName.Substring(0,1) + $LastName).ToLower()
        $UserPrincipalName = "$SamAccountName@domain.local"
        $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force

        $ExistingUser = Get-ADUser -Filter "SamAccountName -eq '$SamAccountName'" -ErrorAction SilentlyContinue
        if ($ExistingUser) {
            Write-Warning "User already exists: $SamAccountName. Skipping."
            continue
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

        if ($Groups -and $Groups.Trim() -ne "") {
            $GroupList = $Groups -split ";"

            foreach ($Group in $GroupList) {
                $GroupName = $Group.Trim()
                if ($GroupName -ne "") {
                    try {
                        Add-ADGroupMember -Identity $GroupName -Members $SamAccountName -ErrorAction Stop
                        Write-Host "  Added $SamAccountName to group: $GroupName" -ForegroundColor Cyan
                    }
                    catch {
                        Write-Warning "  Failed to add $SamAccountName to group '$GroupName': $($_.Exception.Message)"
                    }
                }
            }
        }
    }
    catch {
        Write-Error "Failed processing user '$($User.FirstName) $($User.LastName)': $($_.Exception.Message)"
    }
}
