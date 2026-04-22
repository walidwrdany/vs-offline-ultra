
# 🚀 Visual Studio Offline Ultra Orchestrator (v8.0)

![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)
![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey.svg)
![Mode](https://img.shields.io/badge/Mode-Offline--First-success.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

A powerful, fully automated PowerShell solution for **offline-first installation, configuration, extension management, and repair of Visual Studio**.

Designed for **advanced developers, DevOps engineers, and enterprise environments** where reproducibility, automation, and offline capability are critical.

---

## 📌 Table of Contents

- [✨ Features](#-features)
- [🧱 Architecture](#-architecture)
- [📦 Folder Structure](#-folder-structure)
- [⚙️ Requirements](#️-requirements)
- [🚀 Getting Started](#-getting-started)
- [🖥️ Interactive Menu](#️-interactive-menu)
- [🔁 Recommended Workflows](#-recommended-workflows)
- [🧩 Functions Breakdown](#-functions-breakdown)
- [🛠️ Troubleshooting](#️-troubleshooting)
- [📊 Logging](#-logging)
- [🔐 Security Notes](#-security-notes)
- [📈 Use Cases](#-use-cases)
- [🤝 Contributing](#-contributing)
- [📜 License](#-license)

---

## ✨ Features

### 🔧 Offline-First Installation
- Full Visual Studio layout creation
- Completely offline installation (`--noWeb`)
- Deterministic builds across machines

---

### 📦 Smart Workload Management
Preconfigured workloads:
- .NET Web Development
- Desktop Development
- Data & SQL Tools
- Azure & Docker Tools

Supports:
- Custom `.vsconfig`
- Component-level control

---

### 🧩 Extension Automation Engine
Automatically:
- Downloads VSIX extensions
- Installs them post-installation
- Supports offline usage

Includes tools like:
- EF Core Power Tools
- CodeMaid
- GitHub Actions
- REST Client
- AWS Toolkit

---

### ⚡ Parallel VSIX Downloader
- Multi-download support
- Skips existing files
- Marketplace-driven links

---

### 🛠️ Layout Management System
Supports:
- Layout creation
- Sync updates
- Cleanup of obsolete packages
- Layout verification & repair

---

### 🧪 Advanced Repair Engine
- Detects corrupted packages
- Repairs missing components
- Uses `--verify` and `--fix`

---

### 🧹 Full Environment Reset
- Clears caches and temp files
- Resets Visual Studio settings
- Removes corrupted state

---

### 🔐 Certificate Injection
Fixes:
- Exit Code 1
- Signature validation issues

---

### ⚙️ Process Control
Kills blocking processes:
- devenv
- VSIXInstaller
- ServiceHub
- msbuild

---

### 📊 Logging System
- Daily log files
- Color-coded console output
- Full traceability

---

## 🧱 Architecture

```text
[ Bootstrapper ]
        ↓
[ Layout Engine ] → Offline Packages
        ↓
[ Config Generator (.vsconfig) ]
        ↓
[ Core Installation (--noWeb) ]
        ↓
[ Extension Engine (VSIX) ]
        ↓
[ Repair / Reset / Cleanup Tools ]
````

---

## 📦 Folder Structure

```
C:\VSLayout
│
├── vs_setup.exe
├── vs.vsconfig
├── Extensions\
├── certificates\
├── Archive\
└── VS_Log_YYYYMMDD.log
```

---

## ⚙️ Requirements

* Windows 10 / 11
* PowerShell 5.1+
* Administrator privileges
* Internet required ONLY for:

  * First-time layout download
  * Extensions download

---

## 🚀 Getting Started

### 1️⃣ Clone Repository

```bash
git clone https://github.com/your-repo/vs-offline-ultra.git
cd vs-offline-ultra
```

---

### 2️⃣ Run Script

```powershell
.\vs-offline-ultra.ps1
```

---

### 3️⃣ Follow Interactive Menu

---

## 🖥️ Interactive Menu

```
1. Full Setup (Prepare Everything - Online)
2. Download Bootstrapper
3. Generate local vsconfig
4. Sync Layout (Workloads)
5. Download Extensions (VSIX)
6. Install IDE Core (Offline Mode)
7. Install Extensions (Post-Install)
8. Cleanup Obsolete Packages
9. Reset VS Settings/Cache
10. Repair/Verify Layout
0. Exit
```

---

## 🔁 Recommended Workflows

### 🟢 First-Time Setup

1. Run:

```
Option 1 → Full Setup
```

2. Then:

```
Option 6 → Install Core
```

3. Then:

```
Option 7 → Install Extensions
```

---

### 🔄 Maintenance

| Task                 | Option |
| -------------------- | ------ |
| Cleanup old packages | 8      |
| Repair installation  | 10     |
| Reset environment    | 9      |

---

## 🧩 Functions Breakdown

### 🔹 Log-Action

* Handles logging to file + console
* Supports severity levels

---

### 🔹 Kill-VS-Processes

* Prevents installation conflicts
* Stops all VS-related services

---

### 🔹 Generate-VsConfig

Creates:

```
vs.vsconfig
```

Includes:

* Workloads
* Components
* Local VSIX references

---

### 🔹 Download-Bootstrapper

* Downloads VS installer based on edition

---

### 🔹 Download-Layout

```
vs_setup.exe --layout
```

* Builds offline package repository

---

### 🔹 Download-Extensions-Parallel

* Fetches VSIX files
* Saves locally for offline install

---

### 🔹 Install-VS-Core

Uses:

```
--noWeb
--noUpdateInstaller
--allowUnsignedExtensions
```

---

### 🔹 Install-Extensions

```
VSIXInstaller.exe
```

---

### 🔹 Clean-Old-Layout

* Removes outdated packages
* Frees disk space

---

### 🔹 Reset-VS-Environment

* Clears cache
* Resets settings

---

### 🔹 Repair-Verify-Layout

```
--verify
--fix
```

---

## 🛠️ Troubleshooting

| Problem            | Solution                  |
| ------------------ | ------------------------- |
| Exit Code 1        | Use certificate injection |
| Corrupted layout   | Run Repair (Option 10)    |
| Extensions fail    | Re-run Option 7           |
| Installation stuck | Kill processes + retry    |

---

## 📊 Logging

Log file example:

```
VS_Log_20260422.log
```

Contains:

* Execution steps
* Errors
* Warnings

---

## 🔐 Security Notes

* Runs with Administrator privileges
* Certificates are locally trusted
* No external dependency during install phase

---

## 📈 Use Cases

* 🏢 Enterprise offline environments
* 🔄 CI/CD reproducible builds
* 🧪 Testing multiple VS setups
* 💻 Developer workstation automation
* 🌐 Restricted network environments

---

## 🤝 Contributing

Pull requests are welcome.

If you want to improve:

* Add workloads
* Extend extension list
* Improve logging
* Add CI/CD integration

---

## 📜 License

MIT License

---

## 🏁 Final Notes

This project is not just an installer.

It is a **complete Visual Studio lifecycle manager**:

* Install
* Configure
* Extend
* Repair
* Maintain

---

🔥 Built for power users. Designed for automation.

---
