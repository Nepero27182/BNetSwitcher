Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Suppress console output
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'SilentlyContinue'
$WarningPreference = 'SilentlyContinue'
$InformationPreference = 'SilentlyContinue'
$VerbosePreference = 'SilentlyContinue'

#--------------------------------------
# GLOBAL SETTINGS
#--------------------------------------
# Battle.net Config
$script:ConfigPath = "$env:APPDATA\Battle.net\Battle.net.config"
$script:BattleNetExe = "${env:ProgramFiles(x86)}\Battle.net\Battle.net Launcher.exe"

# Form Settings
$script:FormWidth = 380
$script:FormHeight = 360
$script:FormTitle = "Battle.net Account Switcher"

# Spacing/Padding
$script:Padding = 16

# List Settings
$script:ListHeight = 200
$script:ListFont = "Segoe UI, 11"

# Button Settings
$script:ButtonHeight = 36
$script:ButtonText = "Switch Account"
$script:ButtonFont = "Segoe UI, 12"

# Label Settings
$script:LabelHeight = 24
$script:LabelText = "Created by Blackwut"
$script:LabelFont = "Segoe UI, 10"

# Calculated positions (set during GUI setup)
$script:ListX = $null
$script:ListY = $null
$script:ListWidth = $null
$script:ButtonX = $null
$script:ButtonY = $null
$script:ButtonWidth = $null
$script:LabelX = $null
$script:LabelY = $null
$script:LabelWidth = $null

#--------------------------------------
# CONFIG
#--------------------------------------
$ConfigPath = $script:ConfigPath
$BattleNetExe = $script:BattleNetExe

#--------------------------------------
# THEME DETECTION
#--------------------------------------
function Get-WindowsThemePreference {
    try {
        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
        $regValue = (Get-ItemProperty -Path $regPath -Name "AppsUseLightTheme" -ErrorAction SilentlyContinue).AppsUseLightTheme
        if ($null -eq $regValue) { return $true } # Default to light
        return $regValue -eq 1
    } catch {
        return $true # Default to light on error
    }
}

$isDarkMode = -not (Get-WindowsThemePreference)

if (!(Test-Path $ConfigPath)) {
    [System.Windows.Forms.MessageBox]::Show("Battle.net.config not found!","ERROR","OK","Error")
    exit
}

$json = Get-Content $ConfigPath | ConvertFrom-Json
$accounts = $json.Client.SavedAccountNames -split ','

if ($accounts.Count -eq 0) {
    [System.Windows.Forms.MessageBox]::Show("No accounts found!","ERROR","OK","Error")
    exit
}

#--------------------------------------
# THEME COLORS
#--------------------------------------
$ThemeColors = @{
    Dark = @{
        FormBack = [System.Drawing.Color]::FromArgb(45, 45, 48)
        FormFore = [System.Drawing.Color]::FromArgb(220, 220, 220)
        ButtonBack = [System.Drawing.Color]::FromArgb(60, 60, 60)
        ButtonFore = [System.Drawing.Color]::FromArgb(220, 220, 220)
        ListBack = [System.Drawing.Color]::FromArgb(37, 37, 38)
        ListFore = [System.Drawing.Color]::FromArgb(220, 220, 220)
        LabelFore = [System.Drawing.Color]::FromArgb(150, 150, 150)
    }
    Light = @{
        FormBack = [System.Drawing.Color]::White
        FormFore = [System.Drawing.Color]::Black
        ButtonBack = [System.Drawing.Color]::FromArgb(240, 240, 240)
        ButtonFore = [System.Drawing.Color]::Black
        ListBack = [System.Drawing.Color]::White
        ListFore = [System.Drawing.Color]::Black
        LabelFore = [System.Drawing.Color]::Gray
    }
}

$CurrentTheme = if ($isDarkMode) { "Dark" } else { "Light" }
$Colors = $ThemeColors[$CurrentTheme]

#--------------------------------------
# GUI SETUP
#--------------------------------------
# Calculate centered positions accounting for form chrome
# Get the form's client area (interior usable space)
$form = New-Object System.Windows.Forms.Form
$form.Text = $script:FormTitle
$form.Size = New-Object System.Drawing.Size($script:FormWidth, $script:FormHeight)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.BackColor = $Colors.FormBack
$form.ForeColor = $Colors.FormFore

# Get actual client width (accounting for scrollbars, borders, etc.)
$clientWidth = $form.ClientSize.Width

# Calculate component width to fill client area with equal padding
$script:ListWidth = $clientWidth - (2 * $script:Padding)
$script:ButtonWidth = $clientWidth - (2 * $script:Padding)
$script:LabelWidth = $clientWidth - (2 * $script:Padding)

# Calculate positions with proper vertical spacing
$script:ListX = $script:Padding
$script:ListY = $script:Padding

$script:ButtonX = $script:Padding
$script:ButtonY = $script:ListY + $script:ListHeight + $script:Padding

$script:LabelX = $script:Padding
$script:LabelY = $script:ButtonY + $script:ButtonHeight + $script:Padding

# ACCOUNTS LIST
$list = New-Object System.Windows.Forms.ListBox
$list.Location = "$($script:ListX),$($script:ListY)"
$list.Size = "$($script:ListWidth),$($script:ListHeight)"
$list.Font = $script:ListFont
$list.BackColor = $Colors.ListBack
$list.ForeColor = $Colors.ListFore
$list.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$accounts | ForEach-Object { [void]$list.Items.Add($_) }
$form.Controls.Add($list)

# SWITCH BUTTON
$btn = New-Object System.Windows.Forms.Button
$btn.Text = $script:ButtonText
$btn.Location = "$($script:ButtonX),$($script:ButtonY)"
$btn.Size = "$($script:ButtonWidth),$($script:ButtonHeight)"
$btn.Font = $script:ButtonFont
$btn.BackColor = $Colors.ButtonBack
$btn.ForeColor = $Colors.ButtonFore
$btn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btn.FlatAppearance.BorderColor = $Colors.ButtonBack
$btn.Anchor = [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$form.Controls.Add($btn)

# AUTHOR LABEL
$AuthorLabel = New-Object System.Windows.Forms.Label
$AuthorLabel.Text = $script:LabelText
$AuthorLabel.Location = "$($script:LabelX),$($script:LabelY)"
$AuthorLabel.Size = "$($script:LabelWidth),$($script:LabelHeight)"
$AuthorLabel.TextAlign = "MiddleCenter"
$AuthorLabel.Font = $script:LabelFont
$AuthorLabel.ForeColor = $Colors.LabelFore
$AuthorLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Bottom
$form.Controls.Add($AuthorLabel)

#--------------------------------------
# SWITCH LOGIC
#--------------------------------------
function Switch-Account {
    param([string]$SelectedAccount)
    
    if ([string]::IsNullOrEmpty($SelectedAccount)) {
        return
    }

    # reorder account list
    $newList = @($SelectedAccount) + ($accounts | Where-Object { $_ -ne $SelectedAccount })
    $json.Client.SavedAccountNames = ($newList -join ",")

    # backup
    Copy-Item $ConfigPath "$ConfigPath.backup" -Force

    # save
    $json | ConvertTo-Json -Depth 100 | Out-File $ConfigPath -Encoding UTF8

    # stop Battle.net
    if (Get-Process "Battle.net" -ErrorAction SilentlyContinue) {
        Stop-Process -Name "Battle.net" -Force
    }

    # launch
    if (Test-Path $BattleNetExe) {
        Start-Process $BattleNetExe
    }

    $form.Close()
}

# Button click event
$btn.Add_Click({
    if ($list.SelectedItem) {
        Switch-Account $list.SelectedItem
    }
})

# Double-click event on list
$list.Add_MouseDoubleClick({
    if ($list.SelectedItem) {
        Switch-Account $list.SelectedItem
    }
})

# Display form and suppress all output
$null = $form.ShowDialog()
exit
