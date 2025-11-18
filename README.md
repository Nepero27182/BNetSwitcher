# Battle.net Account Switcher

A lightweight GUI and console tool to quickly switch between Battle.net accounts.

## Features

- **GUI Version** (`bnet-switcher-gui.ps1`):
  - Dark mode with toggle button
  - Automatically loads Windows theme preference on startup
  - Clean, modern interface
  - Quick account switching
  
- **Console Version** (`bnet-switcher-console.bat`):
  - Minimal console output
  - Fast command-line interface

## Building to EXE

The `build.ps1` script compiles the PowerShell script into a standalone EXE using PS2EXE.

### Quick Setup (Recommended)

**Step 1: Create tools directory**
```powershell
mkdir tools\ps2exe -Force
```

**Step 2: Download PS2EXE**
```powershell
$url = "https://github.com/MScholtes/PS2EXE/releases/download/v1.3.6/ps2exe.ps1"
$path = "tools\ps2exe\ps2exe.ps1"
Invoke-WebRequest -Uri $url -OutFile $path
```

**Step 3: Build the EXE**
```powershell
.\build.ps1
```

### Build Options

**With custom icon:**
```powershell
.\build.ps1 -IconPath "path\to\icon.ico"
```

**Custom output name:**
```powershell
.\build.ps1 -OutputExe "MyAccountSwitcher.exe"
```

### Result

- **Input:** `bnet-switcher-gui.ps1`
- **Output:** `bnet-switcher-gui.exe`
- **Size:** ~3-5 MB (includes .NET Framework)
- **Runs:** No console window, x64 architecture
- **Icon:** Custom icon support

### About PS2EXE

PS2EXE is a free open-source tool that converts PowerShell scripts to Windows EXEs. Find it here: https://github.com/MScholtes/PS2EXE/releases

## Installation

### Option 1: Use the EXE
After building, simply run `bnet-switcher-gui.exe`

### Option 2: Run the PS1 directly
```powershell
.\bnet-switcher-gui.ps1
```

## Troubleshooting

**"Battle.net.config not found"**
- Ensure Battle.net is installed and has been launched at least once
- Config file is located at: `%APPDATA%\Battle.net\Battle.net.config`

**Dark mode not detecting Windows preference**
- Requires Windows 10 build 1809+ for theme detection
- Falls back to light mode if registry key is unavailable

**Build script says PS2EXE not found**
- Follow the "Quick Setup" steps above to download PS2EXE
- Or manually download from: https://github.com/MScholtes/PS2EXE/releases
- Place the `ps2exe.ps1` file in the `tools\ps2exe\` folder

## Files

- `bnet-switcher-gui.ps1` - Main GUI application (dark mode enabled)
- `bnet-switcher-console.bat` - Console version (minimal output)
- `build.ps1` - Build script to compile PS1 to EXE
- `README.md` - This file

## Author

Created by Blackwut | Enhanced with dark mode and build tooling

## License

Use as you wish.
