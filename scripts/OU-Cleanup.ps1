<#
.SYNOPSIS
    Identifies stale AD objects and moves them to a quarantine OU.

.DESCRIPTION
    Scans Active Directory for:
    - Disabled user accounts
    - Inactive user accounts (no logon in X days)
    - Stale computer accounts (no logon in X days)

    Moves them to a specified quarantine OU and logs results.

.PARAMETER QuarantineOU
    The OU where stale objects will be moved.

.PARAMETER InactiveDays
    Number of days without logon to consider an object stale.

.EXAMPLE
    .\OU-Cleanup.ps1 -QuarantineOU "OU=Quarantine,DC=yourdomain,DC=com" -InactiveDays 90
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$QuarantineOU,

    [Parameter(Mandatory=$true)]
    [int]$InactiveDays
)

Import-Module ActiveDirectory

$DateThreshold = (Get-Date).AddDays(-$InactiveDays)

Write-Host "Scanning for stale AD objects older than $InactiveDays days..." -ForegroundColor Cyan

# Disabled users
$DisabledUsers = Get-ADUser -Filter {Enabled -eq $false}

# Inactive users
$InactiveUsers = Get-ADUser -Filter * -Properties LastLogonDate |
    Where-Object { $_.LastLogonDate -lt $DateThreshold -and $_.Enabled -eq $true }

# Stale computers
$StaleComputers = Get-ADComputer -Filter * -Properties LastLogonDate |
    Where-Object { $_.LastLogonDate -lt $DateThreshold }

$Report = @()

function Move-Object {
    param($Object)

    try {
        Move-ADObject -Identity $Object.DistinguishedName -TargetPath $QuarantineOU -ErrorAction Stop

        $Report += [PSCustomObject]@{
            Name = $Object.Name
            Type = $Object.ObjectClass
            LastLogon = $Object.LastLogonDate
            Action = "Moved to Quarantine OU"
        }

        Write-Host "Moved: $($Object.Name)" -ForegroundColor Yellow
    }
    catch {
        Write-Host "Error moving $($Object.Name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

foreach ($user in $DisabledUsers) { Move-Object $user }
foreach ($user in $InactiveUsers) { Move-Object $user }
foreach ($comp in $StaleComputers) { Move-Object $comp }

# Export report
$OutputPath = "../examples/OU-Cleanup-Report.csv"
$Report | Export-Csv -Path $OutputPath -NoTypeInformation

Write-Host "`nOU Cleanup Complete!" -ForegroundColor Green
Write-Host "Report saved to: $OutputPath" -ForegroundColor Yellow

Write-Host "`nSummary:" -ForegroundColor Cyan
Write-Host "Disabled Users: $($DisabledUsers.Count)"
Write-Host "Inactive Users: $($InactiveUsers.Count)"
Write-Host "Stale Computers: $($StaleComputers.Count)"
Write-Host "Total Moved: $($Report.Count)"
