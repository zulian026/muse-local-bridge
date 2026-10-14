<#
.SYNOPSIS
    Memasang public key dari Muse AI ke administrators_authorized_keys Windows dengan permission yang valid.
.NOTES
    Harus dijalankan di PowerShell 'Run as Administrator'.
#>

param(
    [Parameter(Mandatory=$true, HelpMessage="Masukkan baris public key dari Muse (ssh-ed25519 AAAA...)")]
    [string]$PublicKey
)

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "ERROR: Skrip ini harus dijalankan di PowerShell 'Run as Administrator'!"
    exit 1
}

$authFile = "C:\ProgramData\ssh\administrators_authorized_keys"

Write-Host "Menyimpan public key ke $authFile..." -ForegroundColor Yellow
Set-Content -Path $authFile -Value $PublicKey.Trim() -Force

Write-Host "Mengatur permission ketat (icacls)..." -ForegroundColor Yellow
icacls $authFile /inheritance:r | Out-Null
icacls $authFile /grant "SYSTEM:(F)" | Out-Null
icacls $authFile /grant "BUILTIN\Administrators:(F)" | Out-Null

Write-Host "Merestart service sshd..." -ForegroundColor Yellow
Restart-Service sshd

Write-Host "Kunci berhasil dipasang dan service OpenSSH telah direstart!" -ForegroundColor Green
