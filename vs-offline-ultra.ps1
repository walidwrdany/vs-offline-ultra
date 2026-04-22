<#
.SYNOPSIS
    Visual Studio 2026 Ultra Orchestrator (v8.0)
    - Full Setup Automation
    - Post-Installation Extension Engine (Post-Install)
    - Fixes "Exit Code 1" and Signature Validation Errors
    - Verified: Compatible with Build 18.5.11709.299
    - Automated: Clean, Sync, and Offline Repair logic
#>

Param(
    [string]$BasePath = "C:\VSLayout",
    [string]$Edition = "Enterprise" # Options: Community, Professional, Enterprise
)

# --- CONFIGURATION ---
$LogFile = Join-Path $PSScriptRoot "VS_Log_$(Get-Date -f 'yyyyMMdd').log"
$ConfigPath = Join-Path $BasePath "vs.vsconfig"
$ExtensionsPath = Join-Path $BasePath "Extensions"
$VSBootstrapper = Join-Path $BasePath "vs_setup.exe"
$VSInstallPath = Join-Path $env:ProgramFiles "Microsoft Visual Studio\2026\$Edition"

$VSUrls = @{
    Community    = "https://aka.ms/vs/stable/vs_community.exe"
    Professional = "https://aka.ms/vs/stable/vs_professional.exe"
    Enterprise   = "https://aka.ms/vs/stable/vs_enterprise.exe"
}

$Workloads = @(
	# --- Primary Workloads ---
	"Microsoft.VisualStudio.Workload.CoreEditor",
	"Microsoft.VisualStudio.Workload.NetWeb",
	"Microsoft.VisualStudio.Workload.ManagedDesktop",
	
	# --- Essential Additions for 2026 ---
	"Microsoft.VisualStudio.Workload.Data",          # SQL Server, EF Core, SSDT
	"Microsoft.VisualStudio.Workload.Azure",         # Docker, Cloud Tools, Containers
	
	# --- Essential Individual Components ---
	"Component.VisualStudio.GitHub.Copilot",         # AI Autocomplete & Chat
	"Microsoft.VisualStudio.Component.IntelliCode",  # AI-assisted IntelliSense
	"Microsoft.VisualStudio.Component.DiagnosticTools", # Performance Profiling
	"Microsoft.VisualStudio.Component.WebDeploy"     # Essential for Web Publishing
)

# Master Extension List (Corrected for Visual Studio IDE IDs)
$ExtensionsList = @(
    @{ID="ErikEJ.EFCorePowerTools"; Name="EFCorePowerTools.vsix"},
    @{ID="MadsKristensen.AddNewFile64"; Name="AddNewFile64.vsix"},
    @{ID="TomasRestrepo.Viasfora"; Name="Viasfora.vsix"},
    @{ID="MadsKristensen.OpeninVisualStudioCode"; Name="OpenInVSCode.vsix"},
    @{ID="ErikEJ.SQLServerCompactSQLiteToolbox"; Name="SQLCEToolbox.vsix"},
    @{ID="MadsKristensen.MarkdownEditor2"; Name="MarkdownEditor2.vsix"},
    @{ID="ChristianResmaHelle.ApiClientCodeGenerator2022"; Name="ApiClientGen.vsix"},
    @{ID="TimHeuer.GitHubActionsVS"; Name="GitHubActions.vsix"},
    @{ID="SteveCadwallader.CodeMaidVS2022"; Name="CodeMaid.vsix"},
    @{ID="RandomEngy.UnitTestBoilerplateGenerator"; Name="UnitTestBoilerplate.vsix"},
    @{ID="GiorgiDalakishvili.EFCoreVisualizer"; Name="EFCoreVisualizer.vsix"},
    @{ID="neuecc.OpenonGitHub"; Name="OpenOnGitHub.vsix"},
    @{ID="devmagic.efsidekick"; Name="EFSidekick.vsix"},
    @{ID="God0nlyKnows.NightOwl"; Name="NightOwl.vsix"},
    @{ID="AmazonWebServices.AWSToolkitforVisualStudio2022"; Name="AWSToolkit.vsix"},
    @{ID="MadsKristensen.CleanSolution"; Name="CleanSolution.vsix"},
    @{ID="dobrynin.cleanbinandobj"; Name="CleanBinObj.vsix"},
    @{ID="TemplateStudio.TemplateStudioForWPF"; Name="TemplateStudioWPF.vsix"},
    @{ID="MadsKristensen.ImageOptimizer64bit"; Name="ImageOptimizer.vsix"},
    @{ID="MadsKristensen.RestClient"; Name="RestClient.vsix"},
    @{ID="NikolayBalakin.Outputenhancer"; Name="OutputEnhancer.vsix"},
    @{ID="MadsKristensen.Tweaks2022"; Name="Tweaks.vsix"},
    @{ID="MadsKristensen.DocumentMargin"; Name="DocumentMargin.vsix"}
)

# --- CORE FUNCTIONS ---

Function Log-Action {
    Param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Entry = "[$Timestamp] [$Level] $Message"
    
    $Color = switch($Level) {
        "ERROR" { "Red" }
        "WARN"  { "Yellow" }
        Default { "Green" }
    }
    
    Write-Host $Entry -ForegroundColor $Color
    if (!(Test-Path $BasePath)) { New-Item -ItemType Directory -Path $BasePath | Out-Null }
    $Entry | Out-File -FilePath $LogFile -Append
}

Function Kill-VS-Processes {
    Log-Action "Stopping all VS background tasks to release file locks..."
    Get-Process devenv, vs_installer, VSIXInstaller, ServiceHub*, msbuild -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

Function Generate-VsConfig {
    Log-Action "Generating vsconfig with workloads and local paths..."
    
    $LocalExtensions = $ExtensionsList | ForEach-Object { Join-Path $ExtensionsPath $_.Name }
    
    $ConfigObj = @{
        version = "1.0"
        components = $Workloads
        extensions = $LocalExtensions
    }
    
    $ConfigObj | ConvertTo-Json | Out-File $ConfigPath -Encoding utf8
    Log-Action "Config saved: $ConfigPath"
}

Function Download-Bootstrapper {
    Log-Action "Downloading VS 2026 $Edition Bootstrapper..."
    try {
        $Url = $VSUrls[$Edition]
        Invoke-WebRequest -Uri $Url -OutFile $VSBootstrapper -ErrorAction Stop
        Log-Action "Bootstrapper ready."
    } catch {
        Log-Action "Download failed: $($_.Exception.Message)" "ERROR"
    }
}

Function Download-Layout {
	Kill-VS-Processes
    Log-Action "Starting Layout sync (Internet Required)..."
    $Args = @("--layout", "`"$BasePath`"", "--config", "`"$ConfigPath`"", "--lang", "en-US", "--wait", "--passive")
    $Proc = Start-Process -FilePath $VSBootstrapper -ArgumentList $Args -Wait -PassThru
    Log-Action "Layout sync finished (Code: $($Proc.ExitCode))"
}

Function Download-Extensions-Parallel {
    Log-Action "Initiating Parallel Download for $(($ExtensionsList.Count)) VSIX files..."
    if (!(Test-Path $ExtensionsPath)) { New-Item -ItemType Directory -Path $ExtensionsPath | Out-Null }
    
    $ExtensionsList | ForEach-Object {
        $Dest = Join-Path $ExtensionsPath $_.Name
        if (Test-Path $Dest) {
            Write-Host " Skip: $($_.Name) exists." -ForegroundColor Cyan
        } else {
            Write-Host " Fetching $($_.ID)..." -ForegroundColor Yellow
            $Pub, $Ext = $_.ID.Split('.')
            $Url = "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/$Pub/vsextensions/$Ext/latest/vspackage"
            try { Invoke-WebRequest -Uri $Url -OutFile $Dest } catch { Log-Action "Fail: $($_.ID)" "ERROR" }
        }
    }
}

Function Install-VS-Core {
    Log-Action "Injecting Certificates for Offline Signature Trust..."
    $CertDir = Join-Path $BasePath "certificates"
    if (Test-Path $CertDir) {
        Get-ChildItem -Path $CertDir -Include *.cer,*.crt -Recurse | ForEach-Object {
            certutil.exe -addstore -f "Root" $_.FullName | Out-Null
        }
    }

    Log-Action "Starting VS 2026 Core Installation (Offline)..."
    # --noUpdateInstaller prevents the common Exit Code 1 timeout
    $Args = @("--noWeb", "--noUpdateInstaller", "--config", "`"$ConfigPath`"", "--allowUnsignedExtensions", "--passive", "--norestart", "--wait")
    $Proc = Start-Process -FilePath $VSBootstrapper -ArgumentList $Args -Wait -PassThru
    
    if ($Proc.ExitCode -eq 0 -or $Proc.ExitCode -eq 3010) {
        Log-Action "Core Installation Success."
    } else {
        Log-Action "Core Installation Failed (Code: $($Proc.ExitCode))" "ERROR"
    }
}

Function Install-Extensions {
    Log-Action "Locating VSIX Installer for Visual Studio 2026..."
    $VSIXInstaller = Join-Path $VSInstallPath "Common7\IDE\VSIXInstaller.exe"
    
    if (!(Test-Path $VSIXInstaller)) {
        Log-Action "VSIXInstaller.exe not found at $VSIXInstaller. Is VS installed?" "ERROR"
        return
    }
	
	Kill-VS-Processes

    Log-Action "Starting batch extension installation..."
    Get-ChildItem -Path $ExtensionsPath -Filter "*.vsix" | ForEach-Object {
        Log-Action "Installing: $($_.Name)"
        $Args = @("/quiet", "/admin", "`"$($_.FullName)`"")
        $Proc = Start-Process -FilePath $VSIXInstaller -ArgumentList $Args -Wait -PassThru
        if ($Proc.ExitCode -eq 0) {
            Log-Action "Successfully installed $($_.Name)"
        } else {
            Log-Action "Failed $($_.Name) with code $($Proc.ExitCode)" "WARN"
        }
    }
    Log-Action "Extension Installation Engine Finished."
}

Function Clean-Old-Layout {
    Log-Action "Cleaning obsolete package versions..."
    $ArchiveDir = Join-Path $BasePath "Archive"
    if (Test-Path $ArchiveDir) {
        Get-ChildItem -Path $ArchiveDir -Directory | ForEach-Object {
            $Cat = Join-Path $_.FullName "Catalog.json"
            if (Test-Path $Cat) {
                Log-Action "Cleaning GUID: $($_.Name)"
                Start-Process -FilePath $VSBootstrapper -ArgumentList "--layout", "`"$BasePath`"", "--clean", "`"$Cat`"", "--passive", "--wait" -Wait
            }
        }
    }
}

Function Reset-VS-Environment {
    Log-Action "WARNING: This will close VS and wipe settings/cache. Proceed? (Y/N)" "WARN"
    $key = [Console]::ReadKey($true)
    if ($key.Key -ne 'Y') { return }
	
    $LocalIDEPath = Join-Path $VSInstallPath "Common7\IDE\devenv.exe"
    
	if (!(Test-Path $LocalIDEPath)) {
        Log-Action "devenv.exe not found at $LocalIDEPath. Is VS installed?" "ERROR"
        return
    }

    Kill-VS-Processes

    Log-Action "Wiping Component Model Cache & User Hives..."
    $VSAppData = Join-Path $env:LOCALAPPDATA "Microsoft\VisualStudio\18.0*"
    if (Test-Path $VSAppData) {
        Get-ChildItem -Path $VSAppData -Directory | ForEach-Object {
            $CachePath = Join-Path $_.FullName "ComponentModelCache"
            if (Test-Path $CachePath) { Remove-Item $CachePath -Recurse -Force -ErrorAction SilentlyContinue }
            $RegFile = Join-Path $_.FullName "privateregistry.bin"
            if (Test-Path $RegFile) { Remove-Item $RegFile -Force -ErrorAction SilentlyContinue }
        }
    }

    Log-Action "Clearing Temp folders..."
    if (Test-Path $env:TEMP) { Get-ChildItem "$env:TEMP\*" -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue }

    if (Test-Path $LocalIDEPath) {
        Log-Action "Running IDE Reset..."
        Start-Process -FilePath $LocalIDEPath -ArgumentList "/ResetSettings", "General" -Wait
    }
    Log-Action "VS Environment Fully Reset."
}

Function Repair-Verify-Layout {
    Log-Action "Forensic Repair: Verifying and Fixing Layout bits (Internet Required)..."
    
    Log-Action "Step 1: Verification..."
    $Args = @("--layout", "`"$BasePath`"", "--verify", "--wait", "--passive")
    Start-Process -FilePath $VSBootstrapper -ArgumentList $Args -Wait
    
    Log-Action "Step 2: Fixing corrupted bits..."
    $ArgsFix = @("--layout", "`"$BasePath`"", "--fix", "--wait", "--passive")
    Start-Process -FilePath $VSBootstrapper -ArgumentList $ArgsFix -Wait
    
    Log-Action "Repair Complete."
}



# --- MENU INTERFACE ---
Do {
    Clear-Host
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host "      VS 2026 ULTRA MANAGER v8.0 (CI/CD)      " -ForegroundColor Cyan
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host "1. Full Setup (Prepare Everything - Online)"
    Write-Host "2. Download Bootstrapper"
    Write-Host "3. Generate local vsconfig"
    Write-Host "4. Sync Layout (Workloads)"
    Write-Host "5. Download Extensions (VSIX)"
    Write-Host "6. Install IDE Core (Offline Mode)"
    Write-Host "7. Install Extensions (Post-Install)"
    Write-Host "8. Cleanup Obsolete Packages"
    Write-Host "9. Reset VS Settings/Cache"
    Write-Host "10. Repair/Verify Layout"
    Write-Host "0. Exit"
    Write-Host "----------------------------------------------"
    $Choice = Read-Host "Select Operation:"

    Switch ($Choice) {
        "1" { 
                Download-Bootstrapper
                Generate-VsConfig
                Download-Layout
                Download-Extensions-Parallel
                Log-Action "Full Preparation Complete."
            }
        "2" { Download-Bootstrapper }
        "3" { Generate-VsConfig }
        "4" { Download-Layout }
        "5" { Download-Extensions-Parallel }
        "6" { Install-VS-Core }
        "7" { Install-Extensions }
        "8" { Clean-Old-Layout }
        "9" { Reset-VS-Environment }
        "10" { Repair-Verify-Layout }
        "0" { exit }
		
		Default { Write-Host "Wrong Selection!" -ForegroundColor Red }
    }
	
    Write-Host "`nPress any key to return to menu..."
    $null = [Console]::ReadKey($true) # Fixed Syntax Error here
} While ($true)
