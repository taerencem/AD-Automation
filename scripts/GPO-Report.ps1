<#
.SYNOPSIS
    Generates a detailed Group Policy Object (GPO) report.

.DESCRIPTION
    Collects information about all GPOs including:
    - GPO name and GUID
    - Linked OUs
    - Security filtering
    - WMI filters
    - Creation and modification dates

    Exports results to CSV for compliance and documentation.

.EXAMPLE
    .\GPO-Report.ps1
#>

Import-Module GroupPolicy
Import-Module ActiveDirectory

Write-Host "Generating GPO Report..." -ForegroundColor Cyan

$GPOs = Get-GPO -All
$Report = @()

foreach ($gpo in $GPOs) {

    # Linked OUs
    $Links = (Get-GPOLink -Guid $gpo.Id -ErrorAction SilentlyContinue)
    $LinkedOUs = $Links | Select-Object -ExpandProperty Target -ErrorAction SilentlyContinue

    # Security Filtering
    $ACLs = (Get-GPO -Guid $gpo.Id).SecurityDescriptor.Sddl
    $SecurityGroups = (Get-Acl "AD:\$($gpo.Path)").Access |
        Select-Object IdentityReference, ActiveDirectoryRights

    # WMI Filter
    $WMIFilter = $gpo.WmiFilter.Name

    $Report += [PSCustomObject]@{
        GPOName        = $gpo.DisplayName
        GUID           = $gpo.Id
        Created        = $gpo.CreationTime
        Modified       = $gpo.ModificationTime
        LinkedOUs      = ($LinkedOUs -join "; ")
        WMIFilter      = $WMIFilter
        SecurityFilter = ($SecurityGroups.IdentityReference -join "; ")
    }

    Write-Host "Processed GPO: $($gpo.DisplayName)" -ForegroundColor Yellow
}

# Export report
$OutputPath = "../examples/GPO-Report.csv"
$Report | Export-Csv -Path $OutputPath -NoTypeInformation

Write-Host "`nGPO Report Complete!" -ForegroundColor Green
Write-Host "Report saved to: $OutputPath" -ForegroundColor Yellow

Write-Host "`nSummary:" -ForegroundColor Cyan
Write-Host "Total GPOs: $($GPOs.Count)"
