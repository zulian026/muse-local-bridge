<#
.SYNOPSIS
    Script otomatisasi untuk menyiapkan OpenSSH Server dan direktori kerja Muse AI di Windows.
.DESCRIPTION
    Menjalankan pengecekan service OpenSSH, firewall port 22, Tailscale IP, dan membuat workspace.
.NOTES
    Harus dijalankan di PowerShell dengan hak akses Administrator.
#>

# Periksa hak administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "ERROR: Skrip ini harus dijalankan di PowerShell 'Run as Administrator'!"
    exit 1
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Setup Host OpenSSH & Tailscale untuk Muse " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 1. Menjalankan service OpenSSH
Write-Host "`n[1/5] Memeriksa status OpenSSH Server (sshd)..." -ForegroundColor Yellow
try {
    Start-Service sshd -ErrorAction Stop
    Set-Service -Name sshd -StartupType 'Automatic'
    Write-Host "  -> Service sshd aktif dan diset Automatic." -ForegroundColor Green
} catch {
    Write-Error "  -> Gagal menjalankan sshd. Pastikan fitur OpenSSH Server sudah terinstall di Windows Optional Features."
}

# 2. Firewall Port 22
Write-Host "`n[2/5] Memeriksa Firewall Rule untuk Port 22..." -ForegroundColor Yellow
$fwRule = Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue
if ($null -eq $fwRule) {
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 | Out-Null
    Write-Host "  -> Aturan firewall port 22 berhasil dibuat." -ForegroundColor Green
} else {
    Write-Host "  -> Aturan firewall port 22 sudah aktif." -ForegroundColor Green
}

# 3. Deteksi Tailscale IP
Write-Host "`n[3/5] Memeriksa status Tailscale..." -ForegroundColor Yellow
try {
    $tailscaleIp = (tailscale ip -4).Trim()
    if ($tailscaleIp) {
        Write-Host "  -> IP Tailscale Laptop Anda: $tailscaleIp" -ForegroundColor Green
    } else {
        Write-Warning "  -> Tailscale belum login atau belum terkoneksi. Silakan jalankan 'tailscale up'."
    }
} catch {
    Write-Warning "  -> Command 'tailscale' tidak ditemukan. Pastikan aplikasi Tailscale terpasang."
}

# 4. Username Lokal
$currentUser = $env:USERNAME
Write-Host "`n[4/5] Username Windows aktif: $currentUser" -ForegroundColor Green

# 5. Buat Workspace Folder
$workspacePath = "$HOME\Documents\MuseWorkspace"
Write-Host "`n[5/5] Memeriksa Folder Workspace ($workspacePath)..." -ForegroundColor Yellow
if (-not (Test-Path $workspacePath)) {
    New-Item -ItemType Directory -Path $workspacePath -Force | Out-Null
    Write-Host "  -> Berhasil membuat folder workspace: $workspacePath" -ForegroundColor Green
} else {
    Write-Host "  -> Folder workspace sudah ada dan siap digunakan." -ForegroundColor Green
}

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host " SETUP LOKAL SELESAI!" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Gunakan detail ini pada prompt Muse AI:"
Write-Host "  IP Tailscale : $tailscaleIp"
Write-Host "  Username     : $currentUser"
Write-Host "  Workspace    : $workspacePath"
Write-Host "==========================================" -ForegroundColor Cyan
