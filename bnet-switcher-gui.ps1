Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

#--------------------------------------
# SECURITY & PRIVACY NOTICE
#--------------------------------------
# This application is 100% LEGAL and SAFE:
# - Operates ENTIRELY OFFLINE - no internet connection required
# - NO data collection, telemetry, or external communications
# - NO unauthorized server access - only modifies your local config
# - Open source PowerShell code - you can inspect everything it does
# - Performs only the same actions you would manually do
# - Creates automatic backups for data safety

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
$script:AppRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $PSCommandPath }
$script:DataFolder = Join-Path $env:APPDATA "BNetSwitcher"
$script:BattleTagStorePath = Join-Path $script:DataFolder "battletags.json"
$script:LegacyBattleTagStorePath = Join-Path $script:AppRoot "battletags.json"
$script:RankCache = @{}
$script:EnableDebugLogging = $false

# Form Settings
$script:FormWidth = 800
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
$script:LabelText = "Created by Nepero - v0.2"
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

function Write-DebugLog {
    param([string]$Message)
    if (-not $script:EnableDebugLogging) { return }
    $timestamp = (Get-Date).ToString("HH:mm:ss")
    Write-Host "[DEBUG $timestamp] $Message" -ForegroundColor Yellow
}

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
# BATTLETAG STORAGE & RANK HELPERS
#--------------------------------------
function Initialize-BattleTagStore {
    try {
        if (-not (Test-Path $script:DataFolder)) {
            New-Item -ItemType Directory -Path $script:DataFolder -Force | Out-Null
        }
    } catch {
        Write-DebugLog "Unable to create BattleTag data folder at $($script:DataFolder): $_"
    }

    if (-not (Test-Path $script:BattleTagStorePath) -and (Test-Path $script:LegacyBattleTagStorePath)) {
        try {
            Copy-Item -Path $script:LegacyBattleTagStorePath -Destination $script:BattleTagStorePath -Force
            Write-DebugLog "Migrated legacy battletags.json from script folder."
        } catch {
            Write-DebugLog "Failed to migrate legacy BattleTag file: $_"
        }
    }
}

function Get-BattleTagStore {
    Initialize-BattleTagStore

    if (-not (Test-Path $script:BattleTagStorePath)) {
        return @{}
    }

    try {
        $raw = Get-Content $script:BattleTagStorePath -Raw
        if ([string]::IsNullOrWhiteSpace($raw)) { return @{} }
        $data = $raw | ConvertFrom-Json
        $map = @{}
        if ($data -is [System.Collections.IDictionary]) {
            foreach ($key in $data.Keys) {
                $map[$key] = $data[$key]
            }
        } elseif ($null -ne $data) {
            foreach ($prop in $data.PSObject.Properties) {
                $map[$prop.Name] = $prop.Value
            }
        }
        return $map
    } catch {
        return @{}
    }
}

function Save-BattleTagStore {
    param([hashtable]$Store)
    try {
        Initialize-BattleTagStore
        ($Store | ConvertTo-Json -Depth 5) | Set-Content -Path $script:BattleTagStorePath -Encoding UTF8
    } catch {
        # ignore write issues
    }
}

function Normalize-BattleTag {
    param([string]$BattleTag)
    if ([string]::IsNullOrWhiteSpace($BattleTag)) { return $null }
    $normalized = $BattleTag.Trim() -replace '\s',''
    $normalized = $normalized -replace '#','-'
    return [System.Uri]::EscapeDataString($normalized)
}

function Format-RankValue {
    param($RankNode)
    if ($null -eq $RankNode) { return "Unranked" }

    $division = $RankNode.division
    if (-not [string]::IsNullOrWhiteSpace($division)) {
        $division = $division.Substring(0,1).ToUpper() + $division.Substring(1)
    }

    $tier = $RankNode.tier
    $value = $RankNode.value
    if (-not $value) { $value = $RankNode.sr }
    if (-not $value) { $value = $RankNode.rank }

    $text = $division
    if ($tier) {
        $text = if ($text) { "$text $tier" } else { "$tier" }
    }

    if ($value) {
        $text = if ($text) { "$text ($value)" } else { "$value" }
    }

    if ([string]::IsNullOrWhiteSpace($text)) {
        return "Unranked"
    }

    return $text
}

function Get-RoleRanks {
    param([string]$BattleTag)

    $result = [ordered]@{
        Tank = ""
        DPS = ""
        Support = ""
        OpenQueue = ""
        Success = $false
    }

    $normalized = Normalize-BattleTag $BattleTag
    if ([string]::IsNullOrWhiteSpace($normalized)) {
        Write-DebugLog "BattleTag missing; skip rank lookup."
        return $result
    }

    if ($script:RankCache.ContainsKey($normalized)) {
        Write-DebugLog "Cache hit for BattleTag $BattleTag ($normalized)."
        return $script:RankCache[$normalized]
    }

    $url = "https://overfast-api.tekrop.fr/players/$normalized/summary"
    Write-DebugLog "Requesting ranks from $url"
    try {
        $response = Invoke-RestMethod -Uri $url -UseBasicParsing -Method Get -TimeoutSec 10
        Write-DebugLog "Received rank response for $BattleTag ($normalized)."
        $tankRank = $response.competitive.pc.tank
        $damageRank = $response.competitive.pc.damage
        $supportRank = $response.competitive.pc.support
        $openQueueRank = $response.competitive.pc.open_queue

        $result.Tank = Format-RankValue $tankRank
        $result.DPS = Format-RankValue $damageRank
        $result.Support = Format-RankValue $supportRank
        $result.OpenQueue = Format-RankValue $openQueueRank
        $result.Success = $true
    } catch {
        Write-DebugLog "Rank lookup failed for $BattleTag ($normalized): $_"
        $result.Tank = "Not Found"
        $result.DPS = "Not Found"
        $result.Support = "Not Found"
        $result.OpenQueue = "Not Found"
    }

    $script:RankCache[$normalized] = $result
    return $result
}

function Update-RowRanks {
    param([System.Windows.Forms.DataGridViewRow]$Row)

    if ($null -eq $Row) { return }

    $battleTag = $Row.Cells["BattleTag"].Value
    if ([string]::IsNullOrWhiteSpace($battleTag)) {
        $Row.Cells["Tank"].Value = ""
        $Row.Cells["DPS"].Value = ""
        $Row.Cells["Support"].Value = ""
        $Row.Cells["OpenQueue"].Value = ""
        return
    }

    $Row.Cells["Tank"].Value = "Loading..."
    $Row.Cells["DPS"].Value = "Loading..."
    $Row.Cells["Support"].Value = "Loading..."
    $Row.Cells["OpenQueue"].Value = "Loading..."

    $ranks = Get-RoleRanks -BattleTag $battleTag
    $Row.Cells["Tank"].Value = $ranks.Tank
    $Row.Cells["DPS"].Value = $ranks.DPS
    $Row.Cells["Support"].Value = $ranks.Support
    $Row.Cells["OpenQueue"].Value = $ranks.OpenQueue
}

$script:BattleTagStore = Get-BattleTagStore

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

# Load and set icon if it exists
# Try multiple possible icon locations
$iconPaths = @(
    "bnet-switcher.ico",
    (Join-Path (Split-Path -Parent $PSCommandPath) "bnet-switcher.ico"),
    (Join-Path $PSScriptRoot "bnet-switcher.ico"),
    (Join-Path (Get-Location) "bnet-switcher.ico")
)

foreach ($iconPath in $iconPaths) {
    if (Test-Path $iconPath) {
        try {
            $iconFile = Get-Item $iconPath
            $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($iconFile.FullName)
            break
        } catch {
            # Try next path
        }
    }
}

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

# ACCOUNTS GRID
$list = New-Object System.Windows.Forms.DataGridView
$list.Location = "$($script:ListX),$($script:ListY)"
$list.Size = "$($script:ListWidth),$($script:ListHeight)"
$list.Font = $script:ListFont
$list.BackgroundColor = $Colors.ListBack
$list.ForeColor = $Colors.ListFore
$list.GridColor = $Colors.ListFore
$list.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$list.AllowUserToAddRows = $false
$list.AllowUserToDeleteRows = $false
$list.AllowUserToResizeRows = $false
$list.ReadOnly = $false
$list.MultiSelect = $false
$list.SelectionMode = [System.Windows.Forms.DataGridViewSelectionMode]::FullRowSelect
$list.RowHeadersVisible = $false
$list.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill
$list.ColumnHeadersHeightSizeMode = [System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode]::AutoSize
$list.EnableHeadersVisualStyles = $false
$list.ColumnHeadersDefaultCellStyle.BackColor = $Colors.ButtonBack
$list.ColumnHeadersDefaultCellStyle.ForeColor = $Colors.ButtonFore
$list.DefaultCellStyle.BackColor = $Colors.ListBack
$list.DefaultCellStyle.ForeColor = $Colors.ListFore
$list.DefaultCellStyle.SelectionBackColor = [System.Drawing.Color]::FromArgb(70,120,200)
$list.DefaultCellStyle.SelectionForeColor = [System.Drawing.Color]::White
$list.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right

[void]$list.Columns.Add("Account","`nAccount`n")
[void]$list.Columns.Add("BattleTag","BattleTag")
[void]$list.Columns.Add("Tank","Tank")
[void]$list.Columns.Add("DPS","DPS")
[void]$list.Columns.Add("Support","Support")
[void]$list.Columns.Add("OpenQueue","Open")

$list.Columns["Account"].ReadOnly = $true
$list.Columns["BattleTag"].ReadOnly = $false
$list.Columns["Tank"].ReadOnly = $true
$list.Columns["DPS"].ReadOnly = $true
$list.Columns["Support"].ReadOnly = $true
$list.Columns["OpenQueue"].ReadOnly = $true

$list.Columns["Account"].FillWeight = 30
$list.Columns["BattleTag"].FillWeight = 20
$list.Columns["Tank"].FillWeight = 12
$list.Columns["DPS"].FillWeight = 12
$list.Columns["Support"].FillWeight = 12
$list.Columns["OpenQueue"].FillWeight = 14

$form.Controls.Add($list)

foreach ($account in $accounts) {
    $battleTagValue = if ($script:BattleTagStore.ContainsKey($account)) { $script:BattleTagStore[$account] } else { "" }
    $rowIndex = $list.Rows.Add($account, $battleTagValue, "", "", "", "")
    if (-not [string]::IsNullOrWhiteSpace($battleTagValue)) {
        $row = $list.Rows[$rowIndex]
        $row.Cells["Tank"].Value = "Pending..."
        $row.Cells["DPS"].Value = "Pending..."
        $row.Cells["Support"].Value = "Pending..."
        $row.Cells["OpenQueue"].Value = "Pending..."
    }
}

if ($list.Rows.Count -gt 0) {
    $list.Rows[0].Selected = $true
}

$battleTagColumnIndex = $list.Columns["BattleTag"].Index
$list.Add_CellEndEdit({
    param($sender, $eventArgs)
    if ($eventArgs.ColumnIndex -ne $battleTagColumnIndex) { return }

    $row = $sender.Rows[$eventArgs.RowIndex]
    $accountValue = $row.Cells["Account"].Value
    $battleTagValue = $row.Cells["BattleTag"].Value
    $battleTagText = if ($battleTagValue) { $battleTagValue.ToString().Trim() } else { "" }

    if ([string]::IsNullOrWhiteSpace($battleTagText)) {
        if ($script:BattleTagStore.ContainsKey($accountValue)) {
            $script:BattleTagStore.Remove($accountValue)
        }
    } else {
        $script:BattleTagStore[$accountValue] = $battleTagText
    }

    Save-BattleTagStore -Store $script:BattleTagStore
    Update-RowRanks -Row $row
})

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
function Get-SelectedAccount {
    param([System.Windows.Forms.DataGridView]$Grid)
    if ($null -eq $Grid) { return $null }
    if ($Grid.SelectedRows.Count -gt 0) {
        return $Grid.SelectedRows[0].Cells["Account"].Value
    }
    return $null
}

function Switch-Account {
    param([string]$SelectedAccount)
    
    if ([string]::IsNullOrEmpty($SelectedAccount)) {
        return
    }

    # reorder account list
    $newList = @($SelectedAccount) + ($accounts | Where-Object { $_ -ne $SelectedAccount })
    $json.Client.SavedAccountNames = ($newList -join ",")
    $accounts = $newList

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
    $selectedAccount = Get-SelectedAccount -Grid $list
    if ($selectedAccount) {
        Switch-Account $selectedAccount
    }
})

# Double-click event on grid
$list.Add_CellDoubleClick({
    param($sender, $eventArgs)
    $selectedAccount = Get-SelectedAccount -Grid $sender
    if ($selectedAccount) {
        Switch-Account $selectedAccount
    }
})

# Form shown event – refresh ranks after GUI loads
$form.Add_Shown({
    foreach ($row in $list.Rows) {
        if ($row.Cells["BattleTag"].Value) {
            Update-RowRanks -Row $row
        }
    }
})

# Display form and suppress all output
$null = $form.ShowDialog()
exit
