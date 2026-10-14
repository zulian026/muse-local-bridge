# Muse AI Local Bridge via Tailscale & OpenSSH (Windows)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform: Windows](https://img.shields.io/badge/Platform-Windows%2010%2F11-blue.svg)](https://microsoft.com/windows)
[![Network: Tailscale](https://img.shields.io/badge/Network-Tailscale-100%25-green.svg)](https://tailscale.com)

Panduan praktis dan otomatisasi konfigurasi untuk menghubungkan agent **Muse AI** langsung ke laptop/PC lokal (Windows) menggunakan **Tailscale** dan **OpenSSH**.

Dengan konfigurasi ini, Muse AI dapat mengeksekusi otomatisasi dokumen (Microsoft Word, Excel), menjalankan workflow pemrograman langsung di folder lokal Anda, serta mengelola file secara aman di dalam direktori kerja terisolasi (*sandboxed*), tanpa memerlukan IP publik statis atau sewa VPS tambahan.

---

## 📑 Daftar Isi
- [Fitur Utama](#-fitur-utama)
- [Peringatan Keamanan & Sandboxing](#-peringatan-keamanan--sandboxing)
- [Prasyarat](#-prasyarat)
- [Panduan Instalasi & Setup Cepat](#-panduan-instalasi--setup-cepat)
  - [Opsi A: Menggunakan Script Otomatis (Direkomendasikan)](#opsi-a-menggunakan-script-otomatis-direkomendasikan)
  - [Opsi B: Konfigurasi Manual via PowerShell](#opsi-b-konfigurasi-manual-via-powershell)
- [Konfigurasi Muse AI](#-konfigurasi-muse-ai)
- [Solusi Masalah Umum (Troubleshooting)](#-solusi-masalah-umum-troubleshooting)
- [Contoh Prompt Penggunaan](#-contoh-prompt-penggunaan)
- [Kontribusi](#-kontribusi)
- [Lisensi](#-lisensi)

---

## 🌟 Fitur Utama
- **Zero Port Forwarding:** Menggunakan jaringan privat Tailnet berbasis WireGuard, tidak perlu membuka port router ke publik.
- **Direct Local Execution:** Buka file Word/Excel langsung di layar desktop atau jalankan `code .` (VS Code).
- **Workspace Isolation:** Aturan prompt ketat memastikan AI hanya bekerja di folder proyek tertentu (misal: `Documents\MuseWorkspace`).
- **Non-destructive:** Aturan konfirmasi sebelum mengeksekusi perintah terminal berisiko.

---

## ⚠️ Peringatan Keamanan & Sandboxing

Memberikan akses SSH ke AI berarti mengizinkan eksekusi terminal secara langsung:
1. **Gunakan Folder Khusus:** Selalu tetapkan folder kerja khusus (misal: `C:\Users\<User>\Documents\MuseWorkspace`).
2. **Jangan Simpan Data Sensitif di Workspace:** Hindari menaruh password, private key (`.env`, `.pem`), atau data finansial di dalam folder tersebut.
3. **Review Perintah Terminal:** Jangan ragu memeriksa perintah yang dijalankan AI sebelum proses eksekusi berlangsung.

---

## 🛠️ Prasyarat
1. Laptop / PC dengan sistem operasi **Windows 10 / 11**.
2. Akun **Tailscale** terpasang dan aktif di laptop ([tailscale.com](https://tailscale.com)).
3. Fitur **OpenSSH Server** bawaan Windows aktif.

---

## 🚀 Panduan Instalasi & Setup Cepat

### Opsi A: Menggunakan Script Otomatis (Direkomendasikan)

Telah disediakan skrip PowerShell pembantu di dalam folder `scripts/`:

1. Buka PowerShell sebagai **Administrator**.
2. Masuk ke direktori repository ini:
   ```powershell
   cd path\ke\muse-local-bridge
   ```
3. Jalankan script setup:
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   .\scripts\setup-windows-host.ps1
   ```
4. Script akan otomatis:
   - Memeriksa dan menjalankan service `sshd` (OpenSSH).
   - Memastikan firewall port 22 terbuka.
   - Menampilkan IP Tailscale laptop Anda (`100.x.x.x`).
   - Membuat direktori kerja default (`$HOME\Documents\MuseWorkspace`).

---

### Opsi B: Konfigurasi Manual via PowerShell

Jika ingin mengonfigurasi langkah demi langkah secara manual:

```powershell
# 1. Jalankan OpenSSH Server
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

# 2. Hubungkan Tailscale
tailscale up

# 3. Dapatkan IP Tailscale laptop
tailscale ip -4

# 4. Cek username lokal Windows
whoami
```

---

## 🤖 Konfigurasi Muse AI

1. Buka dashboard Tailscale di browser: [login.tailscale.com](https://login.tailscale.com) -> **Settings** -> **Keys** -> klik **Generate Auth Key**.
2. Di sesi chat Muse AI, kirimkan prompt inisialisasi dari file `prompts/muse-system-prompt.txt`:

```text
Halo Muse, saya ingin menghubungkan sesi ini langsung ke laptop saya via Tailscale dan OpenSSH.

Langkah kerja:
1. Pasang/jalankan client Tailscale di container kamu.
2. Sambungkan ke tailnet saya dengan Auth Key berikut:
   Auth Key: [TEMPEL_AUTH_KEY_TSKEY-AUTH-xxxx_DISINI]
3. Buat sepasang SSH key baru:
   ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
4. Tampilkan public key kamu (cat ~/.ssh/id_ed25519.pub) ke dalam chat.

Target laptop saya:
- IP Tailscale: [TEMPEL_IP_TAILSCALE_LAPTOP]
- Username: [TEMPEL_USERNAME_WINDOWS]
- Working Directory: C:\Users\[USERNAME]\Documents\MuseWorkspace
```

3. Salin baris public key (`ssh-ed25519 AAAA...`) yang diberikan oleh Muse.

### 🔑 Pemasangan Kunci SSH di Windows

Di Windows, akun Administrator **tidak membaca** `~/.ssh/authorized_keys`, melainkan file sistem `C:\ProgramData\ssh\administrators_authorized_keys`.

Jalankan perintah berikut di PowerShell Administrator di laptop Anda:

```powershell
# Masukkan public key dari Muse
Set-Content -Path "C:\ProgramData\ssh\administrators_authorized_keys" -Value "TEMPEL_PUBLIC_KEY_DARI_MUSE_DISINI"

# Set ACL Permission ketat (OpenSSH menolak file jika izin terlalu longgar)
icacls "C:\ProgramData\ssh\administrators_authorized_keys" /inheritance:r
icacls "C:\ProgramData\ssh\administrators_authorized_keys" /grant "SYSTEM:(F)"
icacls "C:\ProgramData\ssh\administrators_authorized_keys" /grant "BUILTIN\Administrators:(F)"

# Restart OpenSSH service
Restart-Service sshd
```

Kirim pesan ke Muse: *"Kunci SSH sudah dipasang di administrators_authorized_keys, silakan uji koneksi ssh."*

---

## 🔧 Solusi Masalah Umum (Troubleshooting)

| Gejala Masalah | Penyebab | Solusi |
|---|---|---|
| `The Tailscale SSH server is not supported on windows` | Flag `--ssh` di Tailscale hanya untuk Linux/macOS | Gunakan perintah `tailscale up` biasa, lalu manfaatkan OpenSSH bawaan Windows. |
| `Permission denied (publickey)` meskipun key sudah dipasang | Akun Windows bertipe Administrator mengabaikan file `.ssh\authorized_keys` | Pindahkan key ke `C:\ProgramData\ssh\administrators_authorized_keys` dan atur permission via `icacls`. |
| Port 22 unreachable / timeout | Firewall memblokir koneksi masuk SSH | Jalankan: `New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22`. |

---

## 📂 Contoh Prompt Penggunaan

Lihat folder `prompts/examples/` untuk referensi prompt lengkap:
- `01-excel-automation.txt`: Otomatisasi pembuatan spreadsheet & pembukaan instan di desktop.
- `02-word-automation.txt`: Membuat laporan atau draf notulen Word `.docx`.
- `03-coding-project.txt`: Setup repositori git lokal, inisialisasi scaffold project, dan buka di VS Code.

---

## 🤝 Kontribusi
Pull request dan saran perbaikan konfigurasi sangat terbuka! Silakan fork repositori ini, buat branch baru, dan ajukan PR.

---

## 📜 Lisensi
Proyek ini didistribusikan di bawah lisensi [MIT License](LICENSE). Bebas digunakan, dimodifikasi, dan didistribusikan kembali.
