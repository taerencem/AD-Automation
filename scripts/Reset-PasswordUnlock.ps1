<#
.SYNOPSIS
    Resets an AD user's password and unlocks the account.

.DESCRIPTION
    This script resets a user's password, unlocks the account,
    and forces a password change at next logon.

.PARAMETER Username
    The sAMAccountName of the user.

.PARAMETER NewPassword
    The new password to assign.

.EXAMPLE
    .\Reset-PasswordUnlock.ps1 -Username jdoe -NewPassword "TempPass123!"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Username,

    [Parameter(Mandatory=$true)]
    [string]$NewPassword
)

Import-Module ActiveDirectory

try {
    $SecurePass = ConvertTo-SecureString $NewPassword -AsPlainText -Force

    Set-ADAccountPassword -Identity $Username -NewPassword $SecurePass -Reset
    Unlock-ADAccount -Identity $Username
    Set-ADUser -Identity $Username -ChangePasswordAtLogon $true

    Write-Host "Password reset and account unlocked for user: $Username" -ForegroundColor Green
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}
