<#
.SYNOPSIS
    Audits Active Directory user login activity.

.DESCRIPTION
    Generates a report of:
    - Last logon date
    - Accounts that have never logged in
    - Accounts inactive for X days
    - Disabled accounts
    - Enabled accounts

    Exports results to CSV for security and compliance reviews.

.PARAMETER InactiveDays
    Number of days without logon to consider a user inactive.

.EXAMPLE
    .\LoginActivity-Audit.ps1 -InactiveDays 60
#>

param(
    [Parameter(Mandatory=$true)]
    [int]$InactiveDays
)

Import-Module ActiveDirectory

Write-Host "Auditing login activity for all AD users..." -ForegroundColor Cyan

$DateThreshold = (Get-Date).AddDays(-$InactiveDays)

$Users = Get-ADUser -Filter * -Properties LastLogonDate, Enabled

$Report = foreach ($user in $Users) {

    $LastLogon = $user.LastLogonDate
    $Status = if ($user.Enabled) { "Enabled" } else { "Disabled" }

    $ActivityStatus = switch ($true) {
        ($LastLogon -eq $null) { "Never Logged In" }
        ($LastLogon -lt $DateThreshold) { "Inactive" }
        default { "Active" }
    }

    [PSCustomObject]@{
        Name            = $user.Name
        Username        = $user.SamAccountName
        Enabled         = $Status
        LastLogon       = $LastLogon
        ActivityStatus  = $ActivityStatus
    }
}

# Export report
$OutputPath = "../examples/LoginActivity-Report.csv"
$Report | Export-Csv -Path $OutputPath -NoTypeInformation

Write-Host "`nLogin Activity Audit Complete!" -ForegroundColor Green
Write-Host "Report saved to: $OutputPath" -ForegroundColor Yellow

# Summary
$NeverLoggedIn = ($Report | Where-Object { $_.ActivityStatus -eq "Never Logged In" }).Count
$Inactive = ($Report | Where-Object { $_.ActivityStatus -eq "Inactive" }).Count
$Active = ($Report | Where-Object { $_.ActivityStatus -eq "Active" }).Count

Write-Host "`nSummary:" -ForegroundColor Cyan
Write-Host "Active Accounts: $Active"
Write-Host "Inactive Accounts (>$InactiveDays days): $Inactive"
Write-Host "Never Logged In: $NeverLoggedIn"
Write-Host "Total Accounts: $($Report.Count)"
