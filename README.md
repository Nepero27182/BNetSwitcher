# Battle.net Account Switcher

A lightweight GUI tool to quickly switch between Battle.net accounts on Windows.

## Features

- **Automatic Dark Mode Detection**: Matches the GUI to your Windows light/dark preference on launch.
- **BattleTag & Rank Tracking**: Add a BattleTag per account and automatically fetch Tank/DPS/Support/Open Queue SR via the OverFast API (requires internet access) when the window opens.
- **Persistent BattleTags**: Tags are saved per account in `%APPDATA%\BNetSwitcher\battletags.json`, so EXE builds remain portable.
- **Account Reordering**: Switching moves the selected account to the top of the config for faster follow-up launches.
- **Silent Operation**: No console window; ideal for background use or pinned taskbar shortcuts.
- **Data Grid with Double-Click Support**: Inline edit BattleTags, inspect ranks, and double-click any row to switch instantly.
- **Auto-Launch & Cleanup**: Stops the current Battle.net process, launches it again, and closes the GUI automatically.
- **Config Backup**: Creates backups of `Battle.net.config` before every change for safety.

## Quick Start Guide

Follow this guide every time you want to switch between accounts:

### Step 1: Launch the Tool
Run `bnet-switcher.exe` (or `.\bnet-switcher-gui.ps1` if using PowerShell). The grid will populate with every account found in your Battle.net config.

### Step 2: Add or Update BattleTags (Optional)
- Click inside the **BattleTag** column next to an account to add or edit a tag (format: `Name#1234`).
- BattleTags save automatically to `%APPDATA%\BNetSwitcher\battletags.json` so the tool can write even when located in Program Files.

### Step 3: Let Ranks Load
- After the window opens, the tool calls the OverFast API for every BattleTag.
- Tank, DPS, Support, and Open Queue ranks fill in as soon as the responses arrive (placeholders show “Pending…” while loading).

### Step 4: Switch Accounts
- Select any row (or keep the first selection) and click **"Switch Account"** or simply double-click the account name.
- Battle.net closes, the config updates, and the launcher restarts under the chosen account.

### Step 5: Repeat for All Accounts
- Continue steps 3-4 for each account you want to log into
- The tool automatically:
  - Closes the current Battle.net process
  - Reorders accounts so your most-used ones appear at the top
  - Creates backups of your config file for safety

### Tips
- **Most Recent Account**: The account you switched to will move to the top of the list next time
- **Mouse Shortcut**: Double-click any account to switch instantly
- **Safe Switching**: All account switches are backed up automatically
- **No Password Storage**: The tool never saves passwords - Battle.net handles authentication

### Rank API
- BattleTag ranks come from the public [OverFast API](https://overfast-api.tekrop.fr) and require an active internet connection.
- If you block the API or run fully offline, the Tank/DPS/Support/Open Queue cells will show “Pending…” or “Not Found” but account switching still works.
- Avoid spamming updates; the API has rate limits and may temporarily block excessive requests.

## Build System

The `build.ps1` script automatically:
- Detects or installs the `ps2exe` PowerShell module
- Compiles to 64-bit architecture
- Disables console window appearance
- Supports optional custom icons
- Verifies the output and reports file size

**Result:**
- **Output:** `bnet-switcher.exe`
- **Platform:** Windows x64
- **Execution:** No console window, silent operation

## Requirements

- Windows 10 or later
- Battle.net installed and launched at least once
- PowerShell 5.0+ (for PS1 version)
- .NET Framework (included on all Windows 10+)

## Troubleshooting

### "Battle.net.config not found!" Error
- Ensure Battle.net is installed: `C:\Program Files (x86)\Battle.net\`
- Ensure Battle.net has been launched at least once
- Config file location: `%APPDATA%\Battle.net\Battle.net.config`

### Build script fails to install ps2exe
- Manually install with: `Install-Module ps2exe -Scope CurrentUser`
- Or download from: https://github.com/MScholtes/PS2EXE/releases

### GUI doesn't detect dark mode
- Requires Windows 10 build 1809 or later
- Check: Settings > Personalization > Colors > Choose your mode
- Falls back to light mode if detection fails

### Battle.net doesn't launch with the new account
- Ensure Battle.net is installed at the default location: `C:\Program Files (x86)\Battle.net\Battle.net Launcher.exe`
- Try running the GUI as Administrator
- Check that you have permission to modify the config file

## Author

Created by Nepero

## Legal & Privacy

### ✅ 100% Legal
This tool is a utility for managing your own Battle.net accounts. It only:
- Reads and modifies **your local** Battle.net configuration file
- Manages processes on your local machine
- Does not interact with Blizzard's servers in any unauthorized way
- Only performs the same actions you would manually do by logging in/out

### 🔒 Privacy & Security
- **No data collection** - Your account information never leaves your computer
- **No telemetry** - No usage tracking or analytics
- **Local operation only** - All operations happen on your machine
- **Open source** - You can inspect the PowerShell code to verify what it does
- **Config backups** - Automatic backups created before any changes for safety
- **Optional OverFast API call** - Only the BattleTag rank lookup reaches the OverFast API; remove BattleTags or disable ranks to remain fully offline.

### ⚖️ Disclaimer
This is a community tool. Use at your own risk. Always keep backups of important files. The author is not responsible for any account access issues or data loss.

## License

Use as you wish.
