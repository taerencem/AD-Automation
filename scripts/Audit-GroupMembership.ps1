<#
.SYNOPSIS
    Audits Active Directory group membership with recursive scanning.

.DESCRIPTION
    Generates a detailed report of all members in a specified AD group.
    Identifies nested groups, user accounts, and object types.
    Exports results to CSV for compliance and security reviews.

.PARAMETER GroupName
    The name (sAMAccountName or CN) of the AD group to audit.

.EXAMPLE
    .\Audit-GroupMembership.ps1 -GroupName "Domain Admins"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$GroupName
)

Import-Module ActiveDirectory

Write-Host "Auditing group membership for: $GroupName" -ForegroundColor Cyan

try {
    $Group = Get-ADGroup -Identity $GroupName -ErrorAction Stop
}
catch {
    Write-Host "Error: Group '$GroupName' not found." -ForegroundColor Red
    exit
}

$Members = Get-ADGroupMember -Identity $GroupName -Recursive

$Report = foreach ($member in $Members) {

    $ObjectType = switch ($member.ObjectClass) {
        "user"   { "User Account" }
        "group"  { "Nested Group" }
        default  { $member.ObjectClass }
    }

    [PSCustomObject]@{
        Name        = $member.Name
        Username    = $member.SamAccountName
        ObjectType  = $ObjectType
        DistinguishedName = $member.DistinguishedName
    }
}

# Output file
$OutputPath = "../examples/$($GroupName)-MembershipReport.csv"

$Report | Export-Csv -Path $OutputPath -NoTypeInformation

Write-Host "Report generated successfully:" -ForegroundColor Green
Write-Host $OutputPath -ForegroundColor Yellow

# Display summary
$UserCount = ($Report | Where-Object { $_.ObjectType -eq "User Account" }).Count
$GroupCount = ($Report | Where-Object { $_.ObjectType -eq "Nested Group" }).Count

Write-Host "`nSummary:" -ForegroundColor Cyan
Write-Host "Users: $UserCount"
Write-Host "Nested Groups: $GroupCount"
Write-Host "Total Objects: $($Report.Count)"
