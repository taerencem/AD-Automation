<#
.SYNOPSIS
    Bulk user creation script for Active Directory.

.DESCRIPTION
    Reads a CSV file and creates users in the specified OU.
    Designed for onboarding new employees in enterprise environments.

#>

Import-Module ActiveDirectory

# Path to CSV file
$UserList = Import-Csv -Path "../examples/sample-users.csv"

foreach ($user in $UserList) {

    $DisplayName = "$($user.FirstName) $($user.LastName)"
    $SamAccountName = $user.Username
    $OU = $user.OU

    Write-Host "Creating user: $DisplayName"

    New-ADUser `
        -Name $DisplayName `
        -GivenName $user.FirstName `
        -Surname $user.LastName `
        -SamAccountName $SamAccountName `
        -UserPrincipalName "$SamAccountName@yourdomain.com" `
        -AccountPassword (ConvertTo-SecureString $user.Password -AsPlainText -Force) `
        -Enabled $true `
        -Path $OU `
        -ChangePasswordAtLogon $true
}
