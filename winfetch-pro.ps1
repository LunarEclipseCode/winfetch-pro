
#!/usr/bin/env -S pwsh -nop
#requires -version 5

# (!) This file must to be saved in UTF-8 with BOM encoding in order to work with legacy Powershell 5.x

<#PSScriptInfo
.VERSION 1.0.3
.GUID 6f7dd5d1-6db3-41e4-8328-ace6c30bf24f
.AUTHOR @LunarEclipseCode, Winfetch contributers
.PROJECTURI https://github.com/LunarEclipseCode/winfetch-pro
.COMPANYNAME
.COPYRIGHT
.TAGS neofetch screenfetch system-info commandline
.LICENSEURI https://github.com/LunarEclipseCode/winfetch-pro/blob/master/LICENSE
.ICONURI https://raw.githubusercontent.com/LunarEclipseCode/winfetch-pro/refs/heads/master/images/logo.png
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
#>

<#
.SYNOPSIS
    Winfetch-Pro - Neofetch for Windows in PowerShell 5+
.DESCRIPTION
    winfetch-pro is an enhanced version of winfetch, featuring customizable layouts (double columns, headers, footers), additional system information (WiFi, Bluetooth, cache levels, battery health, BIOS), automatic percent bar alignment, and versatile color customization options.
.PARAMETER image
    Display a pixelated image instead of the usual logo.
.PARAMETER ascii
    Display the image using ASCII characters instead of blocks.
.PARAMETER genconf
    Reset your configuration file to the default.
.PARAMETER configpath
    Specify a path to a custom config file.
.PARAMETER noimage
    Do not display any image or logo; display information only.
.PARAMETER logo
    Sets the version of Windows to derive the logo from.
.PARAMETER centerlogo
    Centers the logo if the longest line in the bottom section exceeds the length of the longest line in the logo.
.PARAMETER imgwidth
    Specify width for image/logo. Default is 35.
.PARAMETER alphathreshold
    Specify minimum alpha value for image pixels to be visible. Default is 50.
.PARAMETER blink
    Make the logo blink.
.PARAMETER stripansi
    Output without any text effects or colors.
.PARAMETER all
    Display all built-in info segments.
.PARAMETER help
    Display this help message.
.PARAMETER cpustyle
    Specify how to show information level for CPU usage
.PARAMETER memorystyle
    Specify how to show information level for RAM usage
.PARAMETER diskstyle
    Specify how to show information level for disks' usage
.PARAMETER batterystyle
    Specify how to show information level for battery
.PARAMETER batteryhealthstyle
    Specify how to show information level for battery health
.PARAMETER showdisks
    Configure which disks are shown, use '-showdisks *' to show all.
.PARAMETER showpkgs
    Configure which package managers are shown, e.g. '-showpkgs winget,scoop,choco'.
.PARAMETER colorTopLeft
    Specify the color of top left quadrant in Windows logo
.PARAMETER colorTopRight
    Specify the color of top right quadrant in Windows logo
.PARAMETER colorBottomLeft
    Specify the color of bottom left quadrant in Windows logo
.PARAMETER colorBottomRight
    Specify the color of bottom right quadrant in Windows logo
.PARAMETER allColor
    Specify the color of all quadrants in Windows logo to override the specific color variables
.PARAMETER colorBottomKey
    Specify the color of keys in bottom section
.PARAMETER colorBottomValue
    Specify the color of values in bottom section
.PARAMETER colorLeftKey
    Specify the color of keys in left column
.PARAMETER colorLeftValue
    Specify the color of values in left column
.PARAMETER colorRightKey
    Specify the color of keys in right column
.PARAMETER colorRightValue
    Specify the color of values in right column
.PARAMETER colorGeneralKey
    Specify the color of keys for elements that start with 'general_' in the left column's config
.PARAMETER colorGeneralValue
    Specify the color of values for elements that start with 'general_' in the left column's config
.INPUTS
    System.String
.OUTPUTS
    System.String[]
.NOTES
    Run Winfetch-Pro without arguments to view core functionality.
#>

[CmdletBinding()]
param(
    [string][alias('i')]$image,
    [switch][alias('k')]$ascii,
    [switch][alias('g')]$genconf,
    [string][alias('c')]$configpath,
    [switch][alias('n')]$noimage,
    [string][alias('l')]$logo,
    [switch][alias('b')]$blink,
    [switch][alias('s')]$stripansi,
    [switch][alias('a')]$all,
    [switch][alias('h')]$help,
    [ValidateSet("text", "bar", "textbar", "bartext", "altbar", "textaltbar", "altbartext")][string]$cpustyle = "textaltbar",
    [ValidateSet("text", "bar", "textbar", "bartext", "altbar", "textaltbar", "altbartext")][string]$memorystyle = "textaltbar",
    [ValidateSet("text", "bar", "textbar", "bartext", "altbar", "textaltbar", "altbartext")][string]$diskstyle = "textaltbar",
    [ValidateSet("text", "bar", "textbar", "bartext", "altbar", "textaltbar", "altbartext")][string]$batterystyle = "textaltbar",
    [ValidateSet("text", "bar", "textbar", "bartext", "altbar", "textaltbar", "altbartext")][string]$batteryhealthstyle = "textaltbar",
    [ValidateScript({ $_ -gt 1 -and $_ -lt $Host.UI.RawUI.WindowSize.Width - 1 })][alias('w')][int]$imgwidth = 35,
    [ValidateScript({ $_ -ge 0 -and $_ -le 255 })][alias('t')][int]$alphathreshold = 50,
    [array]$showdisks = @($env:SystemDrive),
    [array]$showpkgs = @("scoop", "choco"),

    [string][alias('ctl')]$colorTopLeft = "1;31", 
    [string][alias('ctr')]$colorTopRight = "cyan", 
    [string][alias('cbl')]$colorBottomLeft = "yellow", 
    [string][alias('cbr')]$colorBottomRight = "1;34", 
    [string]$allColor = $null, 

    [string][alias('cBK')]$colorBottomKey = "red",
    [string][alias('cBV')]$colorBottomValue = "cyan",
    [string][alias('cLK')]$colorLeftKey = "red",
    [string][alias('cLV')]$colorLeftValue = "yellow",
    [string][alias('cRK')]$colorRightKey = "cyan",
    [string][alias('cRV')]$colorRightValue = "white",
    [string][alias('cGK')]$colorGeneralKey = "red",
    [string][alias('cGV')]$colorGeneralValue = "cyan",

    [array]$header = @(),
    [bool]$centerlogo = $true
)

if (-not ($IsWindows -or $PSVersionTable.PSVersion.Major -eq 5)) {
    Write-Error "Only supported on Windows."
    exit 1
}

# ===== DISPLAY HELP =====
if ($help) {
    if (Get-Command -Name less -ErrorAction Ignore) {
        Get-Help ($MyInvocation.MyCommand.Definition) -Full | less
    }
    else {
        Get-Help ($MyInvocation.MyCommand.Definition) -Full
    }
    exit 0
}

# ===== CONFIG MANAGEMENT =====
$defaultConfig = @'
# ===== WINFETCH-PRO CONFIGURATION =====

# $image = "~/winfetch.png"
# $noimage = $true

# Display image using ASCII characters
# $ascii = $true

# Set the version of Windows to derive the logo from.
# $logo = "Windows 10"

# Specify width for image/logo
# $imgwidth = 24

# Specify minimum alpha value for image pixels to be visible
# $alphathreshold = 50

# Custom ASCII Art
# This should be an array of strings, with positive
# height and width equal to $imgwidth defined above.
# $CustomAscii = @(
#     "⠀⠀⠀⠀⠀⠀ ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣾⣿⣦⠀ ⠀"
#     "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣶⣶⣾⣷⣶⣆⠸⣿⣿⡟⠀ ⠀"
#     "⠀⠀⠀⠀⠀⠀⠀⠀⣠⣾⣷⡈⠻⠿⠟⠻⠿⢿⣷⣤⣤⣄⠀⠀ ⠀"
#     "⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⠟⠁⠀⠀⠀⠀⠀⠀⠈⠻⣿⣿⣦⠀ ⠀"
#     "⠀⠀⠀⢀⣤⣤⡘⢿⣿⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⣿⣿⡇ ⠀"
#     "⠀⠀⠀⣿⣿⣿⡇⢸⣿⡁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢈⣉⣉⡁ ⠀"
#     "⠀⠀⠀⠈⠛⠛⢡⣾⣿⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⡇ ⠀"
#     "⠀⠀⠀⠀⠀⠀⠀⠻⣿⣿⣦⡀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⠟⠀ ⠀"
#     "⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⡿⢁⣴⣶⣦⣴⣶⣾⡿⠛⠛⠋⠀⠀ ⠀"
#     "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠿⠿⢿⡿⠿⠏⢰⣿⣿⣧⠀⠀ ⠀"
#     "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢿⣿⠟⠀⠀ ⠀"
# )

# Make the logo blink
# $blink = $true

# Display all built-in info segments.
# $all = $true

# Add a custom info line
# function info_custom_time {
#     return @{
#         title = "Time"
#         content = (Get-Date)
#     }
# }

# Configure which disks are shown
# $ShowDisks = @("C:", "D:")
# Show all available disks
# $ShowDisks = @("*")

# Configure which package managers are shown
# disabling unused ones will improve speed
# $ShowPkgs = @("winget", "scoop", "choco")

# Use the following option to specify custom package managers.
# Create a function with that name as suffix, and which returns
# the number of packages. Two examples are shown here:
# $CustomPkgs = @("cargo", "just-install")
# function info_pkg_cargo {
#     return (cargo install --list | Where-Object {$_ -like "*:" }).Length
# }
# function info_pkg_just-install {
#     return (just-install list).Length
# }

# Configure how to show info for levels
# 'textaltbar' is the default.
# 'bar' is for bar only.
# 'textbar' is for text + bar.
# 'bartext' is for bar + text.
# 'textaltbar is for alternate bar only.
# 'textaltbar' is for text + alternate bar style.
# 'altbartext' is for alternate bar + text.
# $cpustyle = 'bar'
# $memorystyle = 'textbar'
# $diskstyle = 'bartext'
# $batterystyle = 'bartext'

# Configure color of each quadrant in Windows logo.
# Supports colors in format "0;34" (ANSI), "38;5;123" (Extended ANSI) or names.
# Supported names
# Standard colors: black, red, green, yellow, blue, magenta, cyan, white
# Dark colors: Add "dark_" before any standard color (e.g., dark_red, dark_blue)
# $colorTopLeft = "1;37"
# $colorTopRight = "blue"
# $colorBottomLeft = "1;34"
# $colorBottomRight = "white"

# Configure color of keys and values in the bottom section and in left and right columns
# Supports colors in similar way as the previous section on Windows logo
# $colorBottomKey = "0;34"    
# $colorBottomValue = "1;37"    
# $colorLeftKey = "dark_cyan"     
# $colorLeftValue = "white" 
# $colorRightKey = "0;36"     
# $colorRightValue = "1;37"

# Use config_left for a single column layout similar to winfetch
# Use both config_left and config_right for a two-column layout
# Elements prefixed with "general_" will occupy the entire line, 
# and their corresponding config_right elements will be ignored.
# To set a different color scheme for keys and values in general, use:
# $colorGeneralKey = "red"     
# $colorGeneralValue = "cyan"

$config_left = @(
    "blank"
    "user"
    "os"
    "mini_os"
    "resolution"
    "mini_uptime"
    "cpu_name"
    "cpu_cores"
    "ram_total"
    "ram_form_factor"
    "blank"
    "general_memory"
    "general_disk"
    "general_battery_health"
    "blank"
    "weather_condition"
    "temp_celcius"
    "sun"
)

$config_right = @(
    "blank"
    "hostname"
    "kernel"
    "refresh_rate"
    "cpu_processes"
    "cpu_clock_speed"
    "mini_cache"
    "ram_frequency"
    "cpu_usage_only"
    "blank"
    "blank"
    "blank"
    "blank"
    "blank"
    "blank"
    "humidity"
    "feels_like_celcius"
    "wind"
)

# Elements in config_bottom will be placed below the logo.
# Note: A non-blank config_bottom without a logo is not supported and may cause formatting issues.
$config_bottom = @(
    "blank"
    "colorbar_center"
)

# Each array in the header will be a separate line, with all elements inside that array being connected by space.
# Header elements are placed above the left and right column.
# Always keep the @() as the last element of header. Otherwise, if header has one array with 3 elements,
# they are printed in 3 different lines instead of being connected in one line.
$header = @(
    @("emoji_date", "emoji_time", "emoji_battery"), @()
)

# Specify the color for each element in header (set to white if color not mentioned)
$headerColorMap = @{
    'emoji_time'    = "yellow" 
    'emoji_date'    = "red"
    'emoji_battery' = "cyan"
}

# Similar to the header, but placed below the left and right columns.
$footer = @()

# Define colors for each element in the footer, similar to the headerColorMap.
$footerColorMap = @{}

# Add any of the following elements to config_left, config_right, config_bottom
# header, or footer to enable their output

# "blank"
# "title"
# "user"
# "hostname"
# "dashes"
# "os"            
# "mini-os"
# "emoji_date"              # Intended to be used in the header
# "emoji_time"              # Intended to be used in the header
# "emoji_battery"
# "computer"
# "bios"
# "kernel"
# "motherboard"
# "uptime"                  # Format: 1 day 4 hours 32 minutes
# "mini_uptime"             # Format: 1d 4h 32min
# "display"
# "refresh_rate"
# "resolution"              # Resolution of all monitors
# "mini_resolution"         # Resolution of the primary monitor
# "ps_pkgs"                 # takes some time
# "pkgs"
# "pwsh"
# "terminal"
# "terminal_font"
# "theme"
# "cpu"
# "cpu_usage"               # Shows the cpu usage percentage and the number of running processes
# "cpu_usage_only"          # Shows the cpu usage percentage
# "cpu_processes"           # Shows the number of running processes
# "cpu_name"
# "cpu_clock_speed"
# "cpu_cores"
# "cache"
# "mini_cache"
# "gpu"
# "ram"
# "ram_form_factor"
# "ram_total"
# "ram_frequency"
# "memory"
# "disk"
# "battery"
# "battery_health"
# "locale"
# "region"
# "language"
# "weather"
# "bluetooth"
# "wifi"
# "local_ip"
# "public_ip"
# "colorbar"
# "colorbar_center"
# "gradient"
# "gradient_center"
# "weather"                 
# "weather_condition"
# "humidity"
# "sun"                     # Shows the sunset/sunrise time
# "temp_celcius"
# "temp_farenheit"
# "wind"
# "feels_like_celcius"
# "feels_like_farenheit"
'@

if (-not $configPath) {
    if ($env:WINFETCH_CONFIG_PATH) {
        $configPath = $env:WINFETCH_CONFIG_PATH
    }
    else {
        $configPath = "${env:USERPROFILE}\.config\winfetch-pro\config.ps1"
    }
}

# generate default config
if ($genconf -and (Test-Path $configPath)) {
    $choiceYes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
        "overwrite your configuration with the default"
    $choiceNo = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
        "do nothing and exit"
    $result = $Host.UI.PromptForChoice("Resetting your config to default will overwrite it.",
        "Do you want to continue?", ($choiceYes, $choiceNo), 1)
    if ($result -eq 0) { Remove-Item -Path $configPath } else { exit 1 }
}

if (-not (Test-Path $configPath) -or [String]::IsNullOrWhiteSpace((Get-Content $configPath))) {
    New-Item -Type File -Path $configPath -Value $defaultConfig -Force | Out-Null
    if ($genconf) {
        Write-Host "Saved default config to '$configPath'."
        exit 0
    }
    else {
        Write-Host "Missing config: Saved default config to '$configPath'."
    }
}

. $configPath *> $null

# prevent config from overriding specified parameters
foreach ($param in $PSBoundParameters.Keys) {
    Set-Variable $param $PSBoundParameters[$param]
}

$config = . $configPath
# Set default left and right columns if config not set
if (-not $config) {
    $config_left = @(
        "blank"
        "user"
        "mini_os"
        "resolution"
        "mini_uptime"
        "cpu_name"
        "cpu_cores"
        "ram_total"
        "ram_form_factor"
        "blank"
        "general_memory"
        "general_disk"
        "general_battery_health"
        "blank"
        "weather_condition"
        "temp_celcius"
        "sun"
    )

    $config_right = @(
        "blank"
        "hostname"
        "kernel"
        "refresh_rate"
        "cpu_processes"
        "cpu_clock_speed"
        "mini_cache"
        "ram_frequency"
        "cpu_usage_only"
        "blank"
        "blank"
        "blank"
        "blank"
        "blank"
        "humidity"
        "feels_like_celcius"
        "wind"
    )

    $config_bottom = @(
        "blank"
        "colorbar_center"
    )

    $header = @(
        @("emoji_date", "emoji_time", "emoji_battery"), @()
    )

    $headerColorMap = @{
        'emoji_time'    = "yellow" 
        'emoji_date'    = "red"
        'emoji_battery' = "cyan"
    }

    $logo = "Windows 7"
}

if ($all) {
    $header = @(@("emoji_date", "emoji_time"), @())
    $config_left = @(
        "blank"
        "title"
        "dashes"
        "os"
        "computer"
        "bios"
        "kernel"
        "motherboard"
        "uptime"
        "display"
        "ps_pkgs"
        "pkgs"
        "pwsh"
        "terminal"
        "terminal_font"
        "theme"
        "cpu"
        "cache"
        "gpu"
        "cpu_usage"
        "ram"
        "memory"
        "disk"
        "battery"
        "locale"
        "weather"
        "bluetooth"
        "wifi"
        "local_ip"
        "public_ip"
    )
    $config_right = @()
    $config_bottom = @(
        "blank"
        "colorbar_center")
}

# ===== VARIABLES =====
$e = [char]0x1B
$ansiRegex = '([\u001B\u009B][[\]()#;?]*(?:(?:(?:[a-zA-Z\d]*(?:;[-a-zA-Z\d\/#&.:=?%@~_]*)*)?\u0007)|(?:(?:\d{1,4}(?:;\d{0,4})*)?[\dA-PR-TZcf-ntqry=><~])))'
$cimSession = New-CimSession
$os = Get-CimInstance -ClassName Win32_OperatingSystem -Property Caption, OSArchitecture, LastBootUpTime, TotalVisibleMemorySize, FreePhysicalMemory -CimSession $cimSession
$t = if ($blink) { "5" } else { "1" }
$COLUMNS = $imgwidth
$ansiReset = "`e[0m"

# ===== UTILITY FUNCTIONS =====
function get_percent_bar {
    param (
        [Parameter(Mandatory)][int]$percent
    )

    if ($percent -gt 100) { $percent = 100 }
    elseif ($percent -lt 0) { $percent = 0 }

    $x = [char]9632
    $bar = $null

    if ($isBottomSection -and -not $isRightColumn) {
        $defaultColor = Get-AnsiCode -colorInput $colorBottomValue
    }
    elseif ($isRightColumn) {
        $defaultColor = Get-AnsiCode -colorInput $colorRightValue
    }
    else {
        $defaultColor = Get-AnsiCode -colorInput $colorLeftValue
    }

    $bar += "$e[${defaultColor}m[ "
    for ($i = 1; $i -le ($barValue = ([math]::round($percent / 10))); $i++) {
        if ($i -le 6) { $bar += "$e[32m$x" }     # Green section
        elseif ($i -le 8) { $bar += "$e[93m$x" } # Yellow section
        else { $bar += "$e[91m$x" }              # Red section
    }
    for ($i = 1; $i -le (10 - $barValue); $i++) { 
        $bar += "$e[${defaultColor}m-" 
    }
    $bar += "$e[${defaultColor}m ]"

    return $bar
}
function get_altbar {
    param (
        [Parameter(Mandatory)][int]$percent,
        [bool]$reverse = $false
    )

    if ($percent -gt 100) { $percent = 100 }
    elseif ($percent -lt 0) { $percent = 0 }

    $ScaledPercent = ($percent / 100) * 112
    $filledBoxes = [math]::Floor($ScaledPercent / 8)
    $totalBoxes = 14
    $emptyBoxes = $totalBoxes - $filledBoxes
    $altbar = $null

    if (-not $reverse) {
        $filledColor = if ($percent -lt 80) { "39" } else { "203" }  # blue for < 80%, red for >= 80%
    }
    else {
        $filledColor = if ($percent -lt 80) { "203" } else { "39" }  # red for < 80%, blue for >= 80% when reversed
    }

    for ($i = 0; $i -lt $filledBoxes; $i++) {
        $altbar += "$e[38;5;${filledColor}m$([char]0x2587)"
    }

    for ($i = 0; $i -lt $emptyBoxes; $i++) {
        $altbar += "$e[38;5;250m$([char]0x2587)"
    }

    return $altbar
}

function get_level_info {
    param (
        [string]$barprefix,
        [string]$style,
        [int]$percentage,
        [string]$text,
        [switch]$altstyle,
        [bool]$reverse = $false
    )

    if ($stripansi) {
        if ($style -eq "altbar") {
            $style = "bar"
        }
        if ($style -eq "textaltbar") {
            $style = "textbar"
        }
        if ($style -eq "altbartext") {
            $style = "bartext"
        }
    }
    switch ($style) {
        'bar' { return "$barprefix$(get_percent_bar $percentage)" }
        'textbar' { return "$text $(get_percent_bar $percentage)" }
        'bartext' { return "$barprefix$(get_percent_bar $percentage) $text" }
        'altbar' { return "$barprefix$(get_altbar -percent $percentage -reverse $reverse)" }
        'textaltbar' { return "$text $(get_altbar -percent $percentage -reverse $reverse)" }
        'altbartext' { return "$barprefix$(get_altbar -percent $percentage -reverse $reverse) $text" }
        default { 
            if ($altstyle) { 
                return "$percentage% ($text)" 
            }
            else { 
                return "$text ($percentage%)" 
            } 
        }
    }
}

function Get-AnsiCode {
    param (
        [string]$colorInput
    )

    $colorMap = @{
        "black"        = "1;30"
        "red"          = "1;31"
        "green"        = "1;32"
        "yellow"       = "1;33"
        "blue"         = "1;34"
        "magenta"      = "1;35"
        "cyan"         = "1;36"
        "white"        = "1;37"
        "dark_black"   = "0;30"
        "dark_red"     = "0;31"
        "dark_green"   = "0;32"
        "dark_yellow"  = "0;33"
        "dark_blue"    = "0;34"
        "dark_magenta" = "0;35"
        "dark_cyan"    = "0;36"
        "dark_white"   = "0;37"
    }

    $colorInput = $colorInput.Trim().ToLower()

    if ($colorInput -match '^\d+(;\d+)*$') {
        $parts = $colorInput -split ';'
        foreach ($part in $parts) {
            if (-not ($part -as [int]) -and $part -ne "0") {
                throw "Invalid ANSI code part: '$part'. Each part must be a number between 0 and 255."
            }
            $num = [int]$part
            if ($num -lt 0 -or $num -gt 255) {
                throw "ANSI code part out of range: '$part'. Must be between 0 and 255."
            }
        }
        return $colorInput
    }
    elseif ($colorMap.ContainsKey($colorInput)) {
        return $colorMap[$colorInput]
    }
    else {
        throw "Invalid color input: '$colorInput'."
    }
}

function apply_window_colors {
    param (
        [array]$logoArray
    )
    $check = $null -ne $allColor -and $allColor -ne ''
    $ctl = if ($check) { Get-AnsiCode -colorInput $allColor } else { Get-AnsiCode -colorInput $colorTopLeft } 
    $ctr = if ($check) { Get-AnsiCode -colorInput $allColor } else { Get-AnsiCode -colorInput $colorTopRight } 
    $cbl = if ($check) { Get-AnsiCode -colorInput $allColor } else { Get-AnsiCode -colorInput $colorBottomLeft } 
    $cbr = if ($check) { Get-AnsiCode -colorInput $allColor } else { Get-AnsiCode -colorInput $colorBottomRight } 

    $processedLogo = $logoArray | ForEach-Object {
        $_ -replace '<CTL>', $ctl `
            -replace '<CTR>', $ctr `
            -replace '<CBL>', $cbl `
            -replace '<CBR>', $cbr
    }

    return $processedLogo
}

function truncate_line {
    param (
        [string]$text,
        [int]$maxLength
    )
    $length = ($text -replace $ansiRegex, "").Length
    if ($length -le $maxLength) {
        return $text
    }
    $truncateAmt = $length - $maxLength
    $truncatedOutput = ""
    $parts = $text -split $ansiRegex

    for ($i = $parts.Length - 1; $i -ge 0; $i--) {
        $part = $parts[$i]
        if (-not $part.StartsWith([char]27) -and $truncateAmt -gt 0) {
            $num = if ($truncateAmt -gt $part.Length) {
                $part.Length
            }
            else {
                $truncateAmt
            }
            $truncateAmt -= $num
            $part = $part.Substring(0, $part.Length - $num)
        }
        $truncatedOutput = "$part$truncatedOutput"
    }

    return $truncatedOutput
}

# ===== IMAGE =====
$img = if (-not $noimage) {
    if ($image) {
        if ($image -eq 'wallpaper') {
            $image = (Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name Wallpaper).Wallpaper
        }

        Add-Type -AssemblyName 'System.Drawing'
        $OldImage = if (Test-Path $image -PathType Leaf) {
            [Drawing.Bitmap]::FromFile((Resolve-Path $image))
        }
        else {
            [Drawing.Bitmap]::FromStream((Invoke-WebRequest $image -UseBasicParsing).RawContentStream)
        }

        # Divide scaled height by 2.2 to compensate for ASCII characters being taller than they are wide
        [int]$ROWS = $OldImage.Height / $OldImage.Width * $COLUMNS / $(if ($ascii) { 2.2 } else { 1 })
        $Bitmap = New-Object System.Drawing.Bitmap @($OldImage, [Drawing.Size]"$COLUMNS,$ROWS")

        if ($ascii) {
            $chars = ' .,:;+iIH$@'
            for ($i = 0; $i -lt $Bitmap.Height; $i++) {
                $currline = ""
                for ($j = 0; $j -lt $Bitmap.Width; $j++) {
                    $p = $Bitmap.GetPixel($j, $i)
                    $currline += "$e[38;2;$($p.R);$($p.G);$($p.B)m$($chars[[math]::Floor($p.GetBrightness() * $chars.Length)])$e[0m"
                }
                $currline
            }
        }
        else {
            for ($i = 0; $i -lt $Bitmap.Height; $i += 2) {
                $currline = ""
                for ($j = 0; $j -lt $Bitmap.Width; $j++) {
                    $pixel1 = $Bitmap.GetPixel($j, $i)
                    $char = [char]0x2580
                    if ($i -ge $Bitmap.Height - 1) {
                        if ($pixel1.A -lt $alphathreshold) {
                            $char = [char]0x2800
                            $ansi = "$e[49m"
                        }
                        else {
                            $ansi = "$e[38;2;$($pixel1.R);$($pixel1.G);$($pixel1.B)m"
                        }
                    }
                    else {
                        $pixel2 = $Bitmap.GetPixel($j, $i + 1)
                        if ($pixel1.A -lt $alphathreshold -or $pixel2.A -lt $alphathreshold) {
                            if ($pixel1.A -lt $alphathreshold -and $pixel2.A -lt $alphathreshold) {
                                $char = [char]0x2800
                                $ansi = "$e[49m"
                            }
                            elseif ($pixel1.A -lt $alphathreshold) {
                                $char = [char]0x2584
                                $ansi = "$e[49;38;2;$($pixel2.R);$($pixel2.G);$($pixel2.B)m"
                            }
                            else {
                                $ansi = "$e[49;38;2;$($pixel1.R);$($pixel1.G);$($pixel1.B)m"
                            }
                        }
                        else {
                            $ansi = "$e[38;2;$($pixel1.R);$($pixel1.G);$($pixel1.B);48;2;$($pixel2.R);$($pixel2.G);$($pixel2.B)m"
                        }
                    }
                    $currline += "$ansi$char$e[0m"
                }
                $currline
            }
        }

        $Bitmap.Dispose()
        $OldImage.Dispose()

    }
    elseif (($CustomAscii -is [Array]) -and ($CustomAscii.Length -gt 0)) {
        $CustomAscii
    }
    else {
        if (-not $logo) {
            if ($os -Like "*Windows 11 *") {
                $logo = "Windows 11"
            }
            elseif ($os -Like "*Windows 10 *" -Or $os -Like "*Windows 8.1 *" -Or $os -Like "*Windows 8 *") {
                $logo = "Windows 10"
            }
            else {
                $logo = "Windows 7"
            }
        }
    
        if ($logo -eq "Windows 11") {
            $COLUMNS = 32
            $logoArray = @(
                "${e}[${t};<CTL>mlllllllllllllll  ${e}[<CTR>mlllllllllllllll",
                "${e}[${t};<CTL>mlllllllllllllll  ${e}[<CTR>mlllllllllllllll",
                "${e}[${t};<CTL>mlllllllllllllll  ${e}[<CTR>mlllllllllllllll",
                "${e}[${t};<CTL>mlllllllllllllll  ${e}[<CTR>mlllllllllllllll",
                "${e}[${t};<CTL>mlllllllllllllll  ${e}[<CTR>mlllllllllllllll",
                "${e}[${t};<CTL>mlllllllllllllll  ${e}[<CTR>mlllllllllllllll",
                "${e}[${t};<CTL>mlllllllllllllll  ${e}[<CTR>mlllllllllllllll",
                "${e}[${t};<CTL>m                 ${e}[<CTR>m               ",
                "${e}[${t};<CBL>mlllllllllllllll  ${e}[<CBR>mlllllllllllllll",
                "${e}[${t};<CBL>mlllllllllllllll  ${e}[<CBR>mlllllllllllllll",
                "${e}[${t};<CBL>mlllllllllllllll  ${e}[<CBR>mlllllllllllllll",
                "${e}[${t};<CBL>mlllllllllllllll  ${e}[<CBR>mlllllllllllllll",
                "${e}[${t};<CBL>mlllllllllllllll  ${e}[<CBR>mlllllllllllllll",
                "${e}[${t};<CBL>mlllllllllllllll  ${e}[<CBR>mlllllllllllllll",
                "${e}[${t};<CBL>mlllllllllllllll  ${e}[<CBR>mlllllllllllllll"
            )

            @(apply_window_colors -logoArray $logoArray)
        }
        elseif ($logo -eq "Windows 11 Alternate") {
            $COLUMNS = 32
            $logoArray = @(
                "${e}[${t};<CTL>m███████████████  ${e}[<CTR>m███████████████",
                "${e}[${t};<CTL>m███████████████  ${e}[<CTR>m███████████████",
                "${e}[${t};<CTL>m███████████████  ${e}[<CTR>m███████████████",
                "${e}[${t};<CTL>m███████████████  ${e}[<CTR>m███████████████",
                "${e}[${t};<CTL>m███████████████  ${e}[<CTR>m███████████████",
                "${e}[${t};<CTL>m███████████████  ${e}[<CTR>m███████████████",
                "${e}[${t};<CTL>m███████████████  ${e}[<CTR>m███████████████",
                "${e}[${t};<CTL>m                 ${e}[<CTR>m               ",
                "${e}[${t};<CBL>m███████████████  ${e}[<CBR>m███████████████",
                "${e}[${t};<CBL>m███████████████  ${e}[<CBR>m███████████████",
                "${e}[${t};<CBL>m███████████████  ${e}[<CBR>m███████████████",
                "${e}[${t};<CBL>m███████████████  ${e}[<CBR>m███████████████",
                "${e}[${t};<CBL>m███████████████  ${e}[<CBR>m███████████████",
                "${e}[${t};<CBL>m███████████████  ${e}[<CBR>m███████████████",
                "${e}[${t};<CBL>m███████████████  ${e}[<CBR>m███████████████"
            )
    
            @(apply_window_colors -logoArray $logoArray)
        }
        elseif ($logo -eq "Windows 10" -Or $logo -eq "Windows 8.1" -Or $logo -eq "Windows 8") {
            $COLUMNS = 34
            $logoArray = @(
                "${e}[${t};<CTL>m                          ${e}[<CTR>m....iilll",
                "${e}[${t};<CTL>m                ${e}[<CTR>m....iilllllllllllll",
                "${e}[${t};<CTL>m    ....iillll  ${e}[<CTR>mlllllllllllllllllll",
                "${e}[${t};<CTL>miillllllllllll  ${e}[<CTR>mlllllllllllllllllll",
                "${e}[${t};<CTL>mllllllllllllll  ${e}[<CTR>mlllllllllllllllllll",
                "${e}[${t};<CTL>mllllllllllllll  ${e}[<CTR>mlllllllllllllllllll",
                "${e}[${t};<CTL>mllllllllllllll  ${e}[<CTR>mlllllllllllllllllll",
                "${e}[${t};<CTL>mllllllllllllll  ${e}[<CTR>mlllllllllllllllllll",
                "${e}[${t};<CTL>mllllllllllllll  ${e}[<CTR>mlllllllllllllllllll",
                "${e}[${t};<CTL>m                ${e}[<CTR>m                   ",
                "${e}[${t};<CBL>mllllllllllllll  ${e}[<CBR>mlllllllllllllllllll",
                "${e}[${t};<CBL>mllllllllllllll  ${e}[<CBR>mlllllllllllllllllll",
                "${e}[${t};<CBL>mllllllllllllll  ${e}[<CBR>mlllllllllllllllllll",
                "${e}[${t};<CBL>mllllllllllllll  ${e}[<CBR>mlllllllllllllllllll",
                "${e}[${t};<CBL>m!!llllllllllll  ${e}[<CBR>mlllllllllllllllllll",
                "${e}[${t};<CBL>m    ''''!!llll  ${e}[<CBR>mlllllllllllllllllll",
                "${e}[${t};<CBL>m                ${e}[<CBR>m''''!!lllllllllllll",
                "${e}[${t};<CBL>m                          ${e}[<CBR>m''''!!lll"
            )

            @(apply_window_colors -logoArray $logoArray)
        }

        elseif ($logo -eq "Windows 10 Alternate" -Or $logo -eq "Windows 8.1 Alternate" -Or $logo -eq "Windows 8 Alternate") {
            $COLUMNS = 34
            $logoArray = @(
                "${e}[${t};<CTL>m                           ${e}[<CTR>m.ooodMMM",
                "${e}[${t};<CTL>m                ${e}[<CTR>m  .oodMMMMMMMMMMMMM",
                "${e}[${t};<CTL>m    ...oodMMMM  ${e}[<CTR>mMMMMMMMMMMMMMMMMMMM",
                "${e}[${t};<CTL>moodMMMMMMMMMMM  ${e}[<CTR>mMMMMMMMMMMMMMMMMMMM",
                "${e}[${t};<CTL>mMMMMMMMMMMMMMM  ${e}[<CTR>mMMMMMMMMMMMMMMMMMMM",
                "${e}[${t};<CTL>mMMMMMMMMMMMMMM  ${e}[<CTR>mMMMMMMMMMMMMMMMMMMM",
                "${e}[${t};<CTL>mMMMMMMMMMMMMMM  ${e}[<CTR>mMMMMMMMMMMMMMMMMMMM",
                "${e}[${t};<CTL>mMMMMMMMMMMMMMM  ${e}[<CTR>mMMMMMMMMMMMMMMMMMMM",
                "${e}[${t};<CTL>mMMMMMMMMMMMMMM  ${e}[<CTR>mMMMMMMMMMMMMMMMMMMM",
                "${e}[${t};<CTL>m                ${e}[<CTR>m                   ",
                "${e}[${t};<CBL>mMMMMMMMMMMMMMM  ${e}[<CBR>mMMMMMMMMMMMMMMMMMMM",
                "${e}[${t};<CBL>mMMMMMMMMMMMMMM  ${e}[<CBR>mMMMMMMMMMMMMMMMMMMM",
                "${e}[${t};<CBL>mMMMMMMMMMMMMMM  ${e}[<CBR>mMMMMMMMMMMMMMMMMMMM",
                "${e}[${t};<CBL>mMMMMMMMMMMMMMM  ${e}[<CBR>mMMMMMMMMMMMMMMMMMMM",
                "${e}[${t};<CBL>mººPMMMMMMMMMMM  ${e}[<CBR>mMMMMMMMMMMMMMMMMMMM",
                "${e}[${t};<CBL>m    '''ººPMMMM  ${e}[<CBR>mMMMMMMMMMMMMMMMMMMM",
                "${e}[${t};<CBL>m                ${e}[<CBR>m''ººPMMMMMMMMMMMMM",
                "${e}[${t};<CBL>m                         ${e}[<CBR>m'''ºººPMM"
            )

            @(apply_window_colors -logoArray $logoArray)
        }
        elseif ($logo -eq "Windows 7" -Or $logo -eq "Windows Vista" -Or $logo -eq "Windows XP") {
            $COLUMNS = 35
            $logoArray = @(
                "${e}[${t};<CTL>m        ,.=:!!t3Z3z.,               ",
                "${e}[${t};<CTL>m       :tt:::tt333EE3               ",
                "${e}[${t};<CTL>m       Et:::ztt33EEE  ${e}[<CTR>m@Ee.,      ..,",
                "${e}[${t};<CTL>m      ;tt:::tt333EE7 ${e}[<CTR>m;EEEEEEttttt33#",
                "${e}[${t};<CTL>m     :Et:::zt333EEQ. ${e}[<CTR>mSEEEEEttttt33QL",
                "${e}[${t};<CTL>m     it::::tt333EEF ${e}[<CTR>m@EEEEEEttttt33F ",
                "${e}[${t};<CTL>m    ;3=*^``````'*4EEV ${e}[<CTR>m:EEEEEEttttt33@. ",
                "${e}[${t};<CBL>m    ,.=::::it=., ${e}[<CTL>m`` ${e}[<CTR>m@EEEEEEtttz33QF  ",
                "${e}[${t};<CBL>m   ;::::::::zt33)   ${e}[<CTR>m'4EEEtttji3P*   ",
                "${e}[${t};<CBL>m  :t::::::::tt33 ${e}[<CBR>m:Z3z..  ${e}[<CTR>m```` ${e}[<CBR>m,..g.   ",
                "${e}[${t};<CBL>m  i::::::::zt33F ${e}[<CBR>mAEEEtttt::::ztF    ",
                "${e}[${t};<CBL>m ;:::::::::t33V ${e}[<CBR>m;EEEttttt::::t3     ",
                "${e}[${t};<CBL>m E::::::::zt33L ${e}[<CBR>m@EEEtttt::::z3F     ",
                "${e}[${t};<CBL>m{3=*^``````'*4E3) ${e}[<CBR>m;EEEtttt:::::tZ``     ",
                "${e}[${t};<CBL>m            `` ${e}[<CBR>m:EEEEtttt::::z7       ",
                "${e}[${t};<CBL>m                ${e}[<CBR>m'VEzjt:;;z>*``       "
            )

            @(apply_window_colors -logoArray $logoArray)
        }
        elseif ($logo -eq "Microsoft") {
            $COLUMNS = 13
            $logoArray = @(
                "${e}[${t};<CTL>m┌─────┐${e}[<CTR>m┌─────┐",
                "${e}[${t};<CTL>m│     │${e}[<CTR>m│     │",
                "${e}[${t};<CTL>m│     │${e}[<CTR>m│     │",
                "${e}[${t};<CTL>m└─────┘${e}[<CTR>m└─────┘",
                "${e}[${t};<CBL>m┌─────┐${e}[<CBR>m┌─────┐",
                "${e}[${t};<CBL>m│     │${e}[<CBR>m│     │",
                "${e}[${t};<CBL>m│     │${e}[<CBR>m│     │",
                "${e}[${t};<CBL>m└─────┘${e}[<CBR>m└─────┘"
            )

            @(apply_window_colors -logoArray $logoArray)
        }
        elseif ($logo -eq "Windows 2000" -Or $logo -eq "Windows 98" -Or $logo -eq "Windows 95") {
            $COLUMNS = 45
            $logoArray = @(
                "                         ${e}[${t};30mdBBBBBBBb"
                "                     ${e}[${t};30mdBBBBBBBBBBBBBBBb"
                "             ${e}[${t};30m   000 BBBBBBBBBBBBBBBBBBBB"
                "${e}[${t};30m:::::        000000 BBBBB${e}[${t};<CTL>mdBB${e}[${t};30mBBBB${e}[${t};<CTR>mBBBb${e}[${t};30mBBBBBBB"
                "${e}[${t};<CTL>m::::: ${e}[${t};30m====== 000${e}[${t};<CTL>m000 BBBBBBBB${e}[${t};30mBBBB${e}[${t};<CTR>mBBBBBBBBB${e}[${t};30mBBBB"
                "${e}[${t};<CTL>m::::: ====== ${e}[${t};<CTL>m000000 BBBBBBBB${e}[${t};30mBBBB${e}[${t};<CTR>mBBBBBBBBB${e}[${t};30mBBBB"
                "${e}[${t};<CTL>m::::: ====== ${e}[${t};<CTL>m000000 BBBBBBBB${e}[${t};30mBBBB${e}[${t};<CTR>mBBBBBBBBB${e}[${t};30mBBBB"
                "${e}[${t};<CTL>m::::: ====== ${e}[${t};<CTL>m000000 BBBBBBBB${e}[${t};30mBBBB${e}[${t};<CTR>mBBBBBBBBB${e}[${t};30mBBBB"
                "${e}[${t};<CTL>m::::: ====== 000000 BBBBf${e}[${t};30mBBBBBBBBBBB${e}[${t};<CTR>m`BBBB${e}[${t};30mBBBB"
                "${e}[${t};30m::::: ${e}[${t};<CTL>m====== 000${e}[${t};30m000 BBBBBBBBBBBBBBBBBBBBBBBBB"
                "${e}[${t};30m::::: ====== 000000 BBBBB${e}[${t};<CBL>mdBB${e}[${t};30mBBBB${e}[${t};<CBR>mBBBb${e}[${t};30mBBBBB${e}[${t};30mBBBB"
                "${e}[${t};<CBL>m::::: ${e}[${t};30m====== 000${e}[${t};<CBL>m000 BBBBBBBB${e}[${t};30mBBBB${e}[${t};<CBR>mBBBBBBBBB${e}[${t};30mBBBB"
                "${e}[${t};<CBL>m::::: ====== 000000 BBBBBBBB${e}[${t};30mBBBB${e}[${t};<CBR>mBBBBBBBBB${e}[${t};30mBBBB"
                "${e}[${t};<CBL>m::::: ====== 000000 BBBBBBBB${e}[${t};30mBBBB${e}[${t};<CBR>mBBBBBBBBB${e}[${t};30mBBBB"
                "${e}[${t};<CBL>m::::: ====== 000000 BBBBBBBB${e}[${t};30mBBBB${e}[${t};<CBR>mBBBBBBBBB${e}[${t};30mBBBB"
                "${e}[${t};<CBL>m::::: ====== 000000 BBBBf${e}[${t};30mBBBBBBBBBBB${e}[${t};<CBR>m`BBBB${e}[${t};30mBBBB"
                "${e}[${t};30m::::: ${e}[${t};<CBL>m====== 000${e}[${t};30m000 BBBBBf         `BBBBBBBBB"
                "${e}[${t};30m   :: ====== 000000 BBf                `BBBBB"
                "${e}[${t};30m   ==  000000 B                     BBB"
            )

            @(apply_window_colors -logoArray $logoArray)
        }
        else {
            Write-Error 'The only version logos supported are Windows 11, Windows 10/8.1/8, Windows 7/Vista/XP, Windows 2000/98/95 and Microsoft.'
            exit 1
        }
    }
}

# ===== BLANK =====
function info_blank {
    return @{}
}

# ===== OS =====
function info_os {
    return @{
        title   = "OS"
        content = "$($os.Caption.TrimStart('Microsoft ')) [$($os.OSArchitecture)]"
    }
}

function info_mini_os {
    return @{
        title   = "OS"
        content = "$($os.Caption.TrimStart('Microsoft '))"
    }
}

# ===== DATE =====
function info_emoji_date {
    $CalendarEmoji = [char]::ConvertFromUtf32(0x1F4C5)
    $FormattedDate = Get-Date -Format " d MMMM yyyy"
    @{
        title   = "Date (Emoji)"
        content = "$CalendarEmoji$FormattedDate"
    }
}

# ===== TIME =====
function info_emoji_time {
    $TempDate = Get-Date
    $hour = $TempDate.Hour
    $minute = $TempDate.Minute

    # Round the minutes to the nearest half-hour
    # If minutes >= 45, round up the hour and if minutes >= 15 and < 45, set to half-hour
    # Else, set to the exact hour
    $roundUp = [int]($minute -ge 45)
    $halfHour = [int]( ($minute -ge 15) -and ($minute -lt 45) ) * 12

    # Convert the hour to 12-hour format
    $hour = ($hour + $roundUp) % 12
    if ($hour -eq 0) { $hour = 12 }

    # Calculate corresponding clock emoji
    $emojiCode = 0x1F550 + ($hour - 1) + $halfHour
    $TimeEmoji = [char]::ConvertFromUtf32($emojiCode)

    $Time = "$TimeEmoji $($TempDate.ToString('h:mm:ss tt'))"

    @{
        title   = "Time (Emoji)"
        content = $Time
    }
}

# ===== BIOS =====
function info_bios {
    $biosInfo = Get-CimInstance -ClassName Win32_BIOS -Property SMBIOSBIOSVersion, BiosVersion -ErrorAction SilentlyContinue -CimSession $cimSession

    if (-not $biosInfo) {
        return @{
            title   = "BIOS"
            content = "No BIOS information found"
        }
    }

    $version = $biosInfo.SMBIOSBIOSVersion -join ", "
    $firmwareVersion = if ($biosInfo.BiosVersion[0]) { $biosInfo.BiosVersion[0] } else { "Firmware N/A" }

    # Retrieve boot mode from environment variable
    $bootMode = $env:firmware_type

    return @{
        title   = "BIOS ($bootMode)"
        content = "$version ($firmwareVersion)"
    }
}

# ===== WIFI =====
function info_wifi {
    $wifiInfo = netsh wlan show interfaces

    $ssid = $signal = $radioType = $authentication = $null

    # Initialize a count of found fields
    $fieldsFound = 0
    $totalFields = 4

    foreach ($line in $wifiInfo) {
        $trimmedLine = $line.Trim()

        # Find the first colon to separate key and value
        $colonIndex = $trimmedLine.IndexOf(':')
        if ($colonIndex -lt 0) {
            continue
        }

        $key = $trimmedLine.Substring(0, $colonIndex).Trim()
        $value = $trimmedLine.Substring($colonIndex + 1).Trim()

        switch ($key) {
            'SSID' {
                if ($value) {
                    $ssid = $value
                    $fieldsFound++
                    if ($fieldsFound -eq $totalFields) { break }
                }
            }
            'Signal' {
                if ($value.EndsWith('%')) {
                    $signal = $value
                    $fieldsFound++
                    if ($fieldsFound -eq $totalFields) { break }
                }
            }
            'Radio type' {
                $radioType = $value
                switch ($radioType) {
                    '802.11n' { $radioType += ' (v4)' }
                    '802.11ac' { $radioType += ' (v5)' }
                    '802.11ax' { $radioType += ' (v6)' }
                    default { }
                }
                $fieldsFound++
                if ($fieldsFound -eq $totalFields) { break }
            }
            'Authentication' {
                switch ($value) {
                    'WPA2-Personal' { $authentication = 'WPA2' }
                    'WPA2-Enterprise' { $authentication = 'WPA2-E' }
                    'WPA3-Personal' { $authentication = 'WPA3' }
                    'WPA3-Enterprise' { $authentication = 'WPA3-E' }
                    'Open' { $authentication = 'Open' }
                    default { $authentication = $value }
                }
                $fieldsFound++
                if ($fieldsFound -eq $totalFields) { break }
            }
            default { }
        }

        # Exit the loop early if all fields are found
        if ($fieldsFound -eq $totalFields) { break }
    }

    # Check if SSID was found (i.e., connected)
    if ($ssid) {
        $wifiInfoString = "$ssid - $radioType - $authentication"
        if ($signal) {
            $wifiInfoString += " ($signal)"
        }

        return @{
            title   = 'Wi-Fi'
            content = $wifiInfoString
        }
    }
    else {
        return @{
            title   = 'Wi-Fi'
            content = 'No Wi-Fi connection found'
        }
    }
}

# ===== MOTHERBOARD =====
function info_motherboard {
    $motherboard = Get-CimInstance Win32_BaseBoard -CimSession $cimSession -Property Manufacturer, Product
    return @{
        title   = "Motherboard"
        content = "{0} {1}" -f $motherboard.Manufacturer, $motherboard.Product
    }
}

# ===== TITLE =====
function info_title {
    $e = [char]27

    # Determine which color key to use for the username and @ sign
    if (-not $isRightColumn -and -not $isBottomSection) {
        $colorKey = Get-AnsiCode -colorInput $colorLeftKey
        $colorValue = Get-AnsiCode -colorInput $colorLeftValue
    }
    elseif (-not $isRightColumn -and $isBottomSection) {
        $colorKey = Get-AnsiCode -colorInput $colorBottomKey
        $colorValue = Get-AnsiCode -colorInput $colorBottomValue
    }
    elseif ($isRightColumn -and -not $isBottomSection) {
        $colorKey = Get-AnsiCode -colorInput $colorRightKey
        $colorValue = Get-AnsiCode -colorInput $colorRightValue
    }

    $username = [System.Environment]::UserName
    $computerName = $env:COMPUTERNAME

    return @{
        title   = ""
        content = "$e[${colorKey}m{0}@$e[${colorKey}m{1}$e[0m" -f $username, "$e[${colorValue}m${computerName}$e[0m"
    }
}

function info_user {
    return @{
        title   = "User"
        content = [System.Environment]::UserName
    }
}

function info_hostname {
    return @{
        title   = "Hostname"
        content = $env:COMPUTERNAME
    }
}

# ===== DASHES =====
function info_dashes {
    if (-not $isRightColumn -and -not $isBottomSection) {
        $colorValue = Get-AnsiCode -colorInput $colorLeftKey
    }
    elseif (-not $isRightColumn -and $isBottomSection) {
        $colorValue = Get-AnsiCode -colorInput $colorBottomKey
    }
    elseif ($isRightColumn -and -not $isBottomSection) {
        $colorValue = Get-AnsiCode -colorInput $colorRightKey
    }

    # Calculate the length based on username and computer name
    $length = [System.Environment]::UserName.Length + $env:COMPUTERNAME.Length + 1

    # Generate the content with the selected color
    $content = "$([char]27)[${colorValue}m" + ("-" * $length) + "$([char]27)[0m"

    return @{
        title   = "" 
        content = $content
    }
}

function info_refresh_rate {
    $refreshRate = Get-CimInstance -ClassName Win32_VideoController -CimSession $cimSession | Select-Object -ExpandProperty CurrentRefreshRate

    if ($refreshRate) {
        $refreshRateValue = "$refreshRate Hz"
    }
    else {
        $refreshRateValue = "Unknown"
    }

    return @{
        title   = "Refresh Rate"
        content = $refreshRateValue
    }
}

# ===== COMPUTER =====
function info_computer {
    $compsys = Get-CimInstance -ClassName Win32_ComputerSystem -Property Manufacturer, Model -CimSession $cimSession
    return @{
        title   = "Host"
        content = '{0} {1}' -f $compsys.Manufacturer, $compsys.Model
    }
}

# ===== KERNEL =====
function info_kernel {
    return @{
        title   = "Kernel"
        content = "$([System.Environment]::OSVersion.Version)"
    }
}

# ===== UPTIME =====
function info_uptime {
    @{
        title   = "Uptime"
        content = $(switch ([System.DateTime]::Now - $os.LastBootUpTime) {
            ({ $PSItem.Days -eq 1 }) { '1 day' }
            ({ $PSItem.Days -gt 1 }) { "$($PSItem.Days) days" }
            ({ $PSItem.Hours -eq 1 }) { '1 hour' }
            ({ $PSItem.Hours -gt 1 }) { "$($PSItem.Hours) hours" }
            ({ $PSItem.Minutes -eq 1 }) { '1 minute' }
            ({ $PSItem.Minutes -gt 1 }) { "$($PSItem.Minutes) minutes" }
            }) -join ' '
    }
}

function info_mini_uptime {
    @{
        title   = "Uptime"
        content = $(switch ([System.DateTime]::Now - $os.LastBootUpTime) {
            ({ $PSItem.Days -eq 1 }) { '1 day' }
            ({ $PSItem.Days -gt 1 }) { "$($PSItem.Days)d" }
            ({ $PSItem.Hours -eq 1 }) { '1 hour' }
            ({ $PSItem.Hours -gt 1 }) { "$($PSItem.Hours)h" }
            ({ $PSItem.Minutes -eq 1 }) { '1 minute' }
            ({ $PSItem.Minutes -gt 1 }) { "$($PSItem.Minutes)min" }
            }) -join ' '
    }
}

# ===== RESOLUTION =====
function info_resolution {
    Add-Type -AssemblyName System.Windows.Forms
    $displays = foreach ($monitor in [System.Windows.Forms.Screen]::AllScreens) {
        "$($monitor.Bounds.Size.Width)x$($monitor.Bounds.Size.Height)"
    }

    return @{
        title   = "Resolution"
        content = $displays -join ', '
    }
}

# Get the primary screen's resolution
function info_mini_resolution {

    $screen = [System.Windows.Forms.Screen]::PrimaryScreen
    $resolution = "$($screen.Bounds.Width)x$($screen.Bounds.Height)"
 
    return @{
        title   = "Resolution"
        content = $resolution
    }
}

# ===== TERMINAL =====
# this section works by getting the parent processes of the current powershell instance.
function info_terminal {
    $programs = 'powershell', 'pwsh', 'winpty-agent', 'cmd', 'zsh', 'sh', 'bash', 'fish', 'env', 'nu', 'elvish', 'csh', 'tcsh', 'python', 'xonsh'
    if ($PSVersionTable.PSEdition.ToString() -ne 'Core') {
        $parent = Get-Process -Id (Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $PID" -Property ParentProcessId -CimSession $cimSession).ParentProcessId -ErrorAction Ignore
        for () {
            if ($parent.ProcessName -in $programs) {
                $parent = Get-Process -Id (Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $($parent.ID)" -Property ParentProcessId -CimSession $cimSession).ParentProcessId -ErrorAction Ignore
                continue
            }
            break
        }
    }
    else {
        $parent = (Get-Process -Id $PID).Parent
        for () {
            if ($parent.ProcessName -in $programs) {
                $parent = (Get-Process -Id $parent.ID).Parent
                continue
            }
            break
        }
    }

    $terminal = switch ($parent.ProcessName) {
        { $PSItem -in 'explorer', 'conhost' } { 'Windows Console' }
        'Console' { 'Console2/Z' }
        'ConEmuC64' { 'ConEmu' }
        'WindowsTerminal' { 'Windows Terminal' }
        'FluentTerminal.SystemTray' { 'Fluent Terminal' }
        'Code' { 'Visual Studio Code' }
        default { $PSItem }
    }

    if (-not $terminal) {
        $terminal = "$e[91m(Unknown)"
    }

    return @{
        title   = "Terminal"
        content = $terminal
    }
}

# ===== TERMINAL FONT =====
function info_terminal_font {
    $programs = 'powershell', 'pwsh', 'winpty-agent', 'cmd', 'zsh', 'sh', 'bash', 'fish', 'env', 'nu', 'elvish', 'csh', 'tcsh', 'python', 'xonsh'
    $childProcesses = @{}
    foreach ($prog in $programs) {
        $childProcesses[$prog.ToLower()] = $true
    }

    function Get-ParentProcessId {
        param ($processId)
        try {
            $proc = Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $processId" -Property ParentProcessId -ErrorAction SilentlyContinue
            return $proc.ParentProcessId
        }
        catch {
            return $null
        }
    }

    # Traverse the process tree to find the terminal process
    $currentProcess = Get-Process -Id $PID -ErrorAction SilentlyContinue
    if (-not $currentProcess) {
        return @{
            title   = "Terminal Font"
            content = "Process not found"
        }
    }

    while ($childProcesses.ContainsKey($currentProcess.ProcessName.ToLower())) {
        $parentPid = Get-ParentProcessId -processId $currentProcess.Id
        if (-not $parentPid) { break }
        $currentProcess = Get-Process -Id $parentPid -ErrorAction SilentlyContinue
        if (-not $currentProcess) { break }
    }

    $terminalProcess = $currentProcess

    $fontInfo = $null

    $envLocalAppData = $env:LOCALAPPDATA
    $envAppData = $env:APPDATA

    switch ($terminalProcess.ProcessName) {
        'WindowsTerminal' {
            $wtSettingsPath = "$envLocalAppData\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
            if (Test-Path $wtSettingsPath) {
                try {
                    $wtSettings = Get-Content -Path $wtSettingsPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
                    $defaultProfile = $wtSettings.profiles.list | Where-Object { $_.guid -eq $wtSettings.defaultProfile } | Select-Object -First 1
                    if ($defaultProfile.font.face) {
                        if ($defaultProfile.font.size) {
                            $fontInfo = "$($defaultProfile.font.face) ($([math]::Round($defaultProfile.font.size, 1))pt)"
                        }
                        else {
                            $fontInfo = "$($defaultProfile.font.face)"
                        }
                    }
                }
                catch {
                    # Handle JSON parsing or property access errors silently
                }
            }
        }
        'Code' {
            $vscodeSettingsPath = "$envAppData\Code\User\settings.json"
            if (Test-Path $vscodeSettingsPath) {
                try {
                    $vscodeSettings = Get-Content -Path $vscodeSettingsPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
                    $fontName = $vscodeSettings.'terminal.integrated.fontFamily'
                    $fontSize = $vscodeSettings.'terminal.integrated.fontSize'
                    if ($fontName) {
                        if ($fontSize) {
                            $fontInfo = "$fontName ($([math]::Round($fontSize, 1))pt)"
                        }
                        else {
                            $fontInfo = "$fontName"
                        }
                    }
                }
                catch {
                }
            }
        }
    }

    if (-not $fontInfo) {
        $fontInfo = "Unknown"
    }

    return @{
        title   = "Terminal Font"
        content = $fontInfo
    }
}

# ===== DISPLAY =====
function info_display {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Collections.ArrayList]$lines = @()
    
    foreach ($monitor in [System.Windows.Forms.Screen]::AllScreens) {
        $width = $monitor.Bounds.Size.Width
        $height = $monitor.Bounds.Size.Height
        
        $refreshRate = Get-CimInstance -ClassName Win32_VideoController -CimSession $cimSession | Select-Object -ExpandProperty CurrentRefreshRate

        [void]$lines.Add(@{
                title   = "Display"
                content = "$($width)x$($height) @ $($refreshRate)Hz"
            })
    }
    return $lines
}

# ===== THEME =====
function info_theme {
    $themeinfo = Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name SystemUsesLightTheme, AppsUseLightTheme
    $themename = (Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes' -Name CurrentTheme).CurrentTheme.Split('\')[-1].Replace('.theme', '')
    $systheme = if ($themeinfo.SystemUsesLightTheme) { "Light" } else { "Dark" }
    $apptheme = if ($themeinfo.AppsUseLightTheme) { "Light" } else { "Dark" }
    return @{
        title   = "Theme"
        content = "$themename (System: $systheme, Apps: $apptheme)"
    }
}

# ===== CPU =====
function info_cpu {
    $cpu = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Env:COMPUTERNAME).OpenSubKey("HARDWARE\DESCRIPTION\System\CentralProcessor\0")
    $cpuname = $cpu.GetValue("ProcessorNameString")
    $cpuname = if ($cpuname.Contains('@')) {
        ($cpuname -Split '@')[0].Trim()
    }
    else {
        $cpuname.Trim()
    }
    return @{
        title   = "CPU"
        content = "$cpuname @ $($cpu.GetValue("~MHz") / 1000)GHz" # [math]::Round($cpu.GetValue("~MHz") / 1000, 1) is 2-5ms slower
    }
}

function info_cpu_name {
    $cpuRegistryKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Env:COMPUTERNAME).OpenSubKey("HARDWARE\DESCRIPTION\System\CentralProcessor\0")
    
    # Truncate name to fit it in two columns
    $cpuName = $cpuRegistryKey.GetValue("ProcessorNameString")
    if ($cpuName.Contains('@')) {
        $cpuName = ($cpuName -Split '@')[0].Trim()
    }

    if ($cpuName.Contains('with')) {
        $cpuName = ($cpuName -Split 'with')[0].Trim()
    }

    $cpuName = $cpuName -replace '\(TM\)', ''
    $cpuName = $cpuName -replace 'CPU', ''
    $cpuName = $cpuName.Trim()

    $cpuName = $cpuName -replace '^\S+\s*', ''

    return @{
        title   = "CPU"
        content = $cpuName
    }
}

function info_cpu_clock_speed {
    $cpu = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Env:COMPUTERNAME).OpenSubKey("HARDWARE\DESCRIPTION\System\CentralProcessor\0")
    return @{
        title   = "Clock Speed"
        content = "$($cpu.GetValue("~MHz") / 1000) GHz" 
    }
}

function info_cpu_cores {
    $cpuInfo = Get-CimInstance -ClassName Win32_Processor -Property NumberOfCores, NumberOfLogicalProcessors | Select-Object -First 1

    return @{
        title   = "Cores/Threads"
        content = "$($cpuInfo.NumberOfCores)/$($cpuInfo.NumberOfLogicalProcessors)"
    }
}

# ===== GPU =====
function info_gpu {
    [System.Collections.ArrayList]$lines = @()
    foreach ($gpu in Get-CimInstance -ClassName Win32_VideoController -Property Name -CimSession $cimSession) {
        [void]$lines.Add(@{
                title   = "GPU"
                content = $gpu.Name
            })
    }
    return $lines
}

# ===== CACHE =====
function Get-FormattedCache {
    param (
        [array]$cacheMemory,
        [bool]$includeSpaces
    )

    $cacheLevels = ""
    $cacheSizes = ""

    for ($i = 0; $i -lt $cacheMemory.Count; $i++) {
        $sizeInKB = $cacheMemory[$i].MaxCacheSize

        if ($i -gt 0) { $cacheLevels += "/" }
        $cacheLevels += "L$($i + 1)"

        if ($i -gt 0) { $cacheSizes += "/" }
        if ($sizeInKB -ge 1024) {
            $sizeInMB = [math]::round($sizeInKB / 1024, 1)
            $cacheSizes += "$sizeInMB" + ($includeSpaces ? " MB" : "MB")
        }
        else {
            $cacheSizes += "$sizeInKB" + ($includeSpaces ? " KB" : "KB")
        }
    }

    return @{
        Levels = $cacheLevels
        Sizes  = $cacheSizes
    }
}

function info_cache {
    $cacheMemory = Get-CimInstance -ClassName Win32_CacheMemory -Property MaxCacheSize | Sort-Object -Property MaxCacheSize
    $formattedCache = Get-FormattedCache -cacheMemory $cacheMemory -includeSpaces $true

    return @{
        title   = "$($formattedCache.Levels) Cache"
        content = $formattedCache.Sizes
    }
}

function info_mini_cache {
    $cacheMemory = Get-CimInstance -ClassName Win32_CacheMemory -Property MaxCacheSize
    $formattedCache = Get-FormattedCache -cacheMemory $cacheMemory -includeSpaces $false

    return @{
        title   = $formattedCache.Levels
        content = $formattedCache.Sizes
    }
}

# ===== RAM =====
$formFactorMap = @{
    0  = "Unknown"
    1  = "Other"
    2  = "SIP"
    3  = "DIP"
    4  = "ZIP"
    5  = "SOJ"
    7  = "SIMM"
    8  = "DIMM"
    9  = "TSOP"
    10 = "PGA"
    11 = "RIMM"
    12 = "SODIMM"
    13 = "SRIMM"
    14 = "SMD"
    15 = "SSMP"
    16 = "QFP"
    17 = "TQFP"
    18 = "SOIC"
    19 = "LCC"
    20 = "PLCC"
    21 = "BGA"
    22 = "FPBGA"
    23 = "LGA"
    24 = "FB-DIMM"
}

function info_ram {
    [System.Collections.ArrayList]$lines = @()
    
    $ramInfo = Get-CimInstance -ClassName Win32_PhysicalMemory -Property Capacity, SMBIOSMemoryType, Speed, FormFactor -CimSession $cimSession
    
    # Track the number of RAM modules
    $ramCount = $ramInfo.Count
    $ramIndex = 1
    
    foreach ($ram in $ramInfo) {
        if ($ram.Capacity -lt 1GB) {
            $capacityMB = [math]::Round($ram.Capacity / 1MB, 2)
            $capacityStr = "$capacityMB MB"
        }
        else {
            $capacityGB = [math]::Round($ram.Capacity / 1GB, 2)
            $capacityStr = "$capacityGB GB"
        }
        
        # Map SMBIOSMemoryType to Memory Type
        switch ($ram.SMBIOSMemoryType) {
            0 { $memoryType = "Unknown" }
            20 { $memoryType = "DDR" }
            21 { $memoryType = "DDR2" }
            24 { $memoryType = "DDR3" }
            26 { $memoryType = "DDR4" }
            30 { $memoryType = "DDR5" }
            default { $memoryType = "Other" }
        }
        
        $speed = if ($ram.Speed) { "$($ram.Speed) MHz" } else { "Not Available" }
        $formFactor = $formFactorMap[[int]$ram.FormFactor] ?? "Unknown"
        
        $ramString = "$capacityStr $memoryType @ $speed ($formFactor)"
        
        if ($ramCount -eq 1) {
            $ramTitle = "RAM"
        }
        else {
            $ramTitle = "RAM$ramIndex"
            $ramIndex++
        }
        
        [void]$lines.Add(@{
                title   = $ramTitle
                content = $ramString
            })
    }
    return $lines
}

function info_ram_form_factor {
    $ramInfo = Get-CimInstance -ClassName Win32_PhysicalMemory -Property FormFactor -CimSession $cimSession

    if ($null -eq $ramInfo) {
        return @{
            title   = "Form Factor"
            content = "N/A"
        }
    }

    $ram = $ramInfo[0]
    $formFactor = $formFactorMap[[int]$ram.FormFactor] ?? "Unknown"

    return @{
        title   = "Form Factor"
        content = $formFactor
    }
}

function info_ram_total {
    $ramInfo = Get-CimInstance -ClassName Win32_PhysicalMemory -Property Capacity, SMBIOSMemoryType -CimSession $cimSession

    $totalCapacity = 0
    $lowestMemoryType = 99

    foreach ($ram in $ramInfo) {
        $totalCapacity += $ram.Capacity

        # Determine the lowest DDR version
        if ($ram.SMBIOSMemoryType -in 20..30) {
            $lowestMemoryType = [math]::Min($lowestMemoryType, $ram.SMBIOSMemoryType)
        }
    }

    $totalCapacityGB = [math]::Round($totalCapacity / 1GB)

    switch ($lowestMemoryType) {
        20 { $memoryType = "DDR" }
        21 { $memoryType = "DDR2" }
        24 { $memoryType = "DDR3" }
        26 { $memoryType = "DDR4" }
        30 { $memoryType = "DDR5" }
        default { $memoryType = "Unknown DDR" }
    }

    return @{
        title   = "RAM"
        content = "${totalCapacityGB}GB $memoryType"
    }
}

function info_ram_frequency {
    $ramInfo = Get-CimInstance -ClassName Win32_PhysicalMemory -Property Speed -CimSession $cimSession
    $lowestFrequency = [int]::MaxValue

    foreach ($ram in $ramInfo) {
        if ($ram.Speed) {
            $lowestFrequency = [math]::Min($lowestFrequency, $ram.Speed)
        }
    }

    if ($lowestFrequency -eq [int]::MaxValue) {
        $output = "Unknown"
    }
    else {
        $output = "$lowestFrequency MHz"
    }


    return @{
        title   = "Frequency"
        content = $output
    }
}

# ===== BLUETOOTH =====
function info_bluetooth {
    # Retrieve the Name property of the first Bluetooth device with Status 'OK'
    $device = Get-CimInstance -ClassName Win32_PnPEntity `
        -Filter "PNPClass = 'Bluetooth' AND Status = 'OK'" `
        -Property Name `
        -ErrorAction SilentlyContinue | 
    Select-Object -First 1

    if ($device) {
        $name = $device.Name

        # Remove these words from the end to keep content short
        $suffixes = @(" AvRCP Transport", "(R)")

        foreach ($suffix in $suffixes) {
            if ($name.EndsWith($suffix, [System.StringComparison]::InvariantCultureIgnoreCase)) {
                $name = $name.Substring(0, $name.Length - $suffix.Length)
                break  # Exit loop after first match
            }
        }

        return @{
            title   = "Bluetooth"
            content = $name.Trim() 
        }
    }
    else {
        return @{
            title   = "Bluetooth"
            content = "No Bluetooth device found"
        }
    }
}

# ===== CPU USAGE =====
function get_cpu_usage {
    # Get all running processes
    $processes = [System.Diagnostics.Process]::GetProcesses()
    $loadPercent = 0
    $processCount = $processes.Count
    $cpuCount = [System.Environment]::ProcessorCount
    $currentTime = [System.DateTime]::Now

    foreach ($process in $processes) {
        try {
            # Calculate the timespan in seconds since the process started
            $timeSpanSeconds = ($currentTime - $process.StartTime).TotalSeconds

            if ($timeSpanSeconds -gt 0) {
                # Calculate CPU usage for the process
                $loadPercent += ($process.CPU * 100) / $timeSpanSeconds / $cpuCount
            }
        }
        catch {
            continue
        }
    }

    return @{
        LoadPercent  = [math]::Round($loadPercent, 2)
        ProcessCount = $processCount
    }
}

function info_cpu_usage {
    $data = $(get_cpu_usage)

    return @{
        Title   = "CPU Usage"
        Content = Get-LevelInfo "" $cpuStyle $data.LoadPercent "$($data.ProcessCount) processes" -AltStyle
    }
}

function info_cpu_usage_only {
    $data = $(get_cpu_usage).LoadPercent

    return @{
        Title   = "CPU Usage"
        Content = "${data}%"
    }
}


function info_cpu_processes {
    $processes = [System.Diagnostics.Process]::GetProcesses()

    return @{
        title   = "Processes"
        content = $processes.Count
    }
}

# ===== MEMORY =====
function info_memory {
    $total = $os.TotalVisibleMemorySize / 1mb
    $used = ($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1mb
    $usage = [math]::floor(($used / $total * 100))
    return @{
        title   = "Memory"
        content = get_level_info "" $memorystyle $usage "$($used.ToString("#.##")) GiB / $($total.ToString("#.##")) GiB"
    }
}

# ===== DISK USAGE =====
function info_disk {
    [System.Collections.ArrayList]$lines = @()

    function to_units($value) {
        if ($value -gt 1tb) {
            return "$([math]::round($value / 1tb, 1)) TiB"
        }
        else {
            return "$([math]::floor($value / 1gb)) GiB"
        }
    }

    [System.IO.DriveInfo]::GetDrives().ForEach{
        $diskLetter = $_.Name.SubString(0, 2)

        if ($showDisks.Contains($diskLetter) -or $showDisks.Contains("*")) {
            try {
                if ($_.TotalSize -gt 0) {
                    $used = $_.TotalSize - $_.AvailableFreeSpace
                    $usage = [math]::Floor(($used / $_.TotalSize * 100))
    
                    [void]$lines.Add(@{
                            title   = "Disk ($diskLetter)"
                            content = get_level_info "" $diskstyle $usage "$(to_units $used) / $(to_units $_.TotalSize)"
                        })
                }
            }
            catch {
                [void]$lines.Add(@{
                        title   = "Disk ($diskLetter)"
                        content = "(failed to get disk usage)"
                    })
            }
        }
    }
    return $lines
}

# ===== POWERSHELL VERSION =====
function info_pwsh {
    return @{
        title   = "Shell"
        content = "PowerShell v$($PSVersionTable.PSVersion)"
    }
}

# ===== POWERSHELL PACKAGES =====
function info_ps_pkgs {
    $ps_pkgs = @()

    # Get all installed packages
    $pgp = Get-Package -ProviderName PowerShellGet
    # Get the number of packages where the tags contains PSModule or PSScript
    $modulecount = $pgp.Where({ $_.Metadata["tags"] -like "*PSModule*" }).count
    $scriptcount = $pgp.Where({ $_.Metadata["tags"] -like "*PSScript*" }).count

    if ($modulecount) {
        if ($modulecount -eq 1) { $modulestring = "1 Module" }
        else { $modulestring = "$modulecount Modules" }

        $ps_pkgs += "$modulestring"
    }

    if ($scriptcount) {
        if ($scriptcount -eq 1) { $scriptstring = "1 Script" }
        else { $scriptstring = "$scriptcount Scripts" }

        $ps_pkgs += "$scriptstring"
    }

    if (-not $ps_pkgs) {
        $ps_pkgs = "(none)"
    }

    return @{
        title   = "PS Packages"
        content = $ps_pkgs -join ', '
    }
}

# ===== PACKAGES =====
function info_pkgs {
    $pkgs = @()

    if ("winget" -in $ShowPkgs -and (Get-Command -Name winget -ErrorAction Ignore)) {
        $wingetpkg = (winget list | Where-Object { $_.Trim("`n`r`t`b-\|/ ").Length -ne 0 } | Measure-Object).Count - 1

        if ($wingetpkg) {
            $pkgs += "$wingetpkg (system)"
        }
    }

    if ("choco" -in $ShowPkgs -and (Get-Command -Name choco -ErrorAction Ignore)) {
        $chocopkg = Invoke-Expression $(
            "(& choco list" + $(if ([version](& choco --version).Split('-')[0]`
                        -lt [version]'2.0.0') { " --local-only" }) + ")[-1].Split(' ')[0] - 1")

        if ($chocopkg) {
            $pkgs += "$chocopkg (choco)"
        }
    }

    if ("scoop" -in $ShowPkgs) {
        $scoopdir = if ($Env:SCOOP) { "$Env:SCOOP\apps" } else { "$Env:UserProfile\scoop\apps" }

        if (Test-Path $scoopdir) {
            $scooppkg = (Get-ChildItem -Path $scoopdir -Directory).Count - 1
        }

        if ($scooppkg) {
            $pkgs += "$scooppkg (scoop)"
        }
    }

    foreach ($pkgitem in $CustomPkgs) {
        if (Test-Path Function:"info_pkg_$pkgitem") {
            $count = & "info_pkg_$pkgitem"
            $pkgs += "$count ($pkgitem)"
        }
    }

    if (-not $pkgs) {
        $pkgs = "(none)"
    }

    return @{
        title   = "Packages"
        content = $pkgs -join ', '
    }
}

# ===== BATTERY =====
function info_battery {
    Add-Type -AssemblyName System.Windows.Forms
    $battery = [System.Windows.Forms.SystemInformation]::PowerStatus

    # If there's no battery
    if ($battery.BatteryChargeStatus -eq 'NoSystemBattery') {
        return @{
            title   = "Battery"
            content = get_level_info "" $batterystyle "N/A" "None" -altstyle -reverse $true
        }
    }

    # Get the current battery percentage
    $batteryLevel = [math]::round($battery.BatteryLifePercent * 100)

    # Determine battery status
    if ($battery.BatteryChargeStatus -like '*Charging*') {
        # Charging state: try to calculate time to full charge
        $batteryData = Get-CimInstance -ClassName BatteryFullChargedCapacity -Namespace ROOT\WMI -ErrorAction SilentlyContinue

        if (-not $batteryData) {
            return @{
                title   = "Battery"
                content = get_level_info "" $batterystyle "$batteryLevel" "$batteryLevel% (Charging)" -altstyle -reverse $true
            }
        }
        
        $fullChargeCapacity = $batteryData.FullChargedCapacity
        $currentCharge = $battery.BatteryLifePercent * $fullChargeCapacity

        $batteryStatus = Get-CimInstance -Namespace "ROOT\WMI" -ClassName BatteryStatus -ErrorAction SilentlyContinue
        $chargingRate = if ($batteryStatus) { $batteryStatus.ChargeRate } else { $null }

        if (-not $chargingRate) {
            return @{
                title   = "Battery"
                content = get_level_info "" $batterystyle "$batteryLevel" "$batteryLevel% (Charging)" -altstyle -reverse $true
            }
        }

        # If not at full charge, calculate time to full charge
        if ($batteryLevel -ne 100) {
            $remainingToCharge = $fullChargeCapacity - $currentCharge
            $timeToFullCharge = ($remainingToCharge / $chargingRate) * 60  # Convert to minutes
            $hours = [math]::Floor($timeToFullCharge / 60)
            $minutes = [math]::Ceiling($timeToFullCharge % 60)

            if ($hours -gt 0) {
                $timeToCharge = "${hours}h ${minutes}min to recharge"
            }
            else {
                $timeToCharge = "${minutes}min to recharge"
            }

            return @{
                title   = "Battery"
                content = get_level_info "" $batterystyle "$batteryLevel" "$batteryLevel% ($timeToCharge)" -altstyle -reverse $true
            }
        }

        return @{
            title   = "Battery"
            content = get_level_info "" $batterystyle "$batteryLevel" "$batteryLevel% (Charging)" -altstyle -reverse $true
        }
    }
    elseif ($battery.PowerLineStatus -like '*Online*') {
        return @{
            title   = "Battery"
            content = get_level_info "" $batterystyle "$batteryLevel" "$batteryLevel% (Plugged In)" -altstyle -reverse $true
        }
    }
    else {
        $timeRemaining = $battery.BatteryLifeRemaining / 60
        if ($timeRemaining -ge 0) {
            $hours = [math]::Floor($timeRemaining / 60)
            $minutes = [math]::Floor($timeRemaining % 60)
            if ($hours -gt 0) {
                $timeFormatted = "${hours}h ${minutes}min left"
            }
            else {
                $timeFormatted = "${minutes}min left"
            }
            return @{
                title   = "Battery"
                content = get_level_info "" $batterystyle "$batteryLevel" "$batteryLevel% ($timeFormatted)" -altstyle -reverse $true
            }
        }
        return @{
            title   = "Battery"
            content = get_level_info "" $batterystyle "$batteryLevel" "$batteryLevel% (Discharging)" -altstyle -reverse $true
        }
    }
}

function info_emoji_battery {
    Add-Type -AssemblyName System.Windows.Forms
    $battery = [System.Windows.Forms.SystemInformation]::PowerStatus
    $batteryEmojiFull = [char]::ConvertFromUtf32(0x1F50B)  # 🔋 Battery (30% or more)

    if ($battery.BatteryChargeStatus -eq 'NoSystemBattery') {
        return @{
            title   = "Battery"
            content = "${batteryEmojiFull} None"
        }
    }

    $chargingEmoji = [char]::ConvertFromUtf32(0x26A1)    # ⚡ Recharge
    $batteryEmojiLow = [char]::ConvertFromUtf32(0x1FAAB)  # 🪫 Low battery
    $batteryLevel = $([math]::round($battery.BatteryLifePercent * 100))

    if ($battery.BatteryChargeStatus -like '*Charging*') {
        $batteryData = Get-CimInstance -ClassName BatteryFullChargedCapacity -Namespace ROOT\WMI -CimSession $cimSession -Property FullChargedCapacity -ErrorAction SilentlyContinue
        if (-not $batteryData) {
            return @{
                title   = "Battery"
                content = "${chargingEmoji}${batteryLevel} (Charging)"
            }
        }
        
        $fullChargeCapacity = $batteryData.FullChargedCapacity
        $currentCharge = $battery.BatteryLifePercent * $fullChargeCapacity
        $chargingRate = (Get-CimInstance -Namespace "ROOT\WMI" -ClassName BatteryStatus -CimSession $cimSession).ChargeRate
        if (-not $chargingRate) {
            return @{
                title   = "Battery"
                content = "${chargingEmoji}${batteryLevel}% (Charging)"
            }
        }

        if ($percentage -ne 100) {
            $remainingToCharge = $fullChargeCapacity - $currentCharge
            $timeToFullCharge = $remainingToCharge / $chargingRate * 60
            $hours = [math]::Floor($timeToFullCharge / 60)
            $minutes = [math]::Ceiling($timeToFullCharge % 60)
            if ($hours -eq 0) {
                $timeToCharge = "$minutes" + "min to $chargingEmoji"
            }
            else {
                $timeToCharge = "$hours" + "h " + "$minutes" + "min to $chargingEmoji"
            }
        }
        return @{
            title   = "Battery"
            content = "${batteryEmojiFull}${batteryLevel}% (${timeToCharge})"
        }
    }

    
    elseif ($battery.PowerLineStatus -like '*Online*') {

        return @{
            title   = "Battery"
            content = "${chargingEmoji}${batteryLevel}% (Plugged in)"
        }
    }
    else {
        $timeRemaining = $battery.BatteryLifeRemaining / 60
        # Don't show time remaining if Windows hasn't properly reported it yet
        $timeFormatted = if ($timeRemaining -ge 0) {
            $hours = [math]::floor($timeRemaining / 60)
            $minutes = [math]::floor($timeRemaining % 60)
        
            if ($hours -eq 0) {
                "${minutes}min"
            }
            else {
                "${hours}h ${minutes}min"
            }
        }
        
        $batteryReport = if ($batteryLevel -ge 30) { $batteryEmojiFull } else { $batteryEmojiLow }
        return @{
            title   = "Battery"
            content = "${batteryReport}${batteryLevel}% (${timeFormatted} left)"
        }
    }
}

function info_battery_health {
    $batteryData = Get-CimInstance -ClassName BatteryFullChargedCapacity -Namespace ROOT\WMI -CimSession $cimSession -Property FullChargedCapacity -ErrorAction SilentlyContinue
    $batteryStatic = Get-CimInstance -ClassName BatteryStaticData -Namespace ROOT\WMI -CimSession $cimSession -Property DesignedCapacity -ErrorAction SilentlyContinue

    # Exit if battery data is unavailable
    if (-not $batteryData -or -not $batteryStatic) {
        return @{
            title   = "Battery Health"
            content = "Battery health data unavailable"
        }
    }

    # Convert capacities from mWh to Wh
    $fullChargeWh = [math]::Round($batteryData.FullChargedCapacity / 1000, 1)
    $designCapacityWh = [math]::Round($batteryStatic.DesignedCapacity / 1000, 1)

    # Calculate battery health, handling division by zero
    $batteryHealth = if ($designCapacityWh -gt 0) { [math]::Floor(($fullChargeWh / $designCapacityWh) * 100) } else { 0 }

    return @{
        title   = "Battery Health"
        content = get_level_info "" $batteryhealthstyle $batteryHealth "$fullChargeWh Wh / $designCapacityWh Wh" -reverse $true
    }
}

# ===== LOCALE =====
# Hashtables for language and region codes
$localeLookup = @{
    "10" = "American Samoa";                             "100" = "Guinea";                            "10026358" = "Americas";                                                                                                                                            
    "10028789" = "Åland Islands";                        "10039880" = "Caribbean";                    "10039882" = "Northern Europe";                                                                                                                                            
    "10039883" = "Southern Africa";                      "101" = "Guyana";                            "10210824" = "Western Europe";                                                                                                                                            
    "10210825" = "Australia and New Zealand";            "103" = "Haiti";                             "104" = "Hong Kong SAR";                                                                                                                                            
    "10541" = "Europe";                                  "106" = "Honduras";                          "108" = "Croatia";                                                                                                                                            
    "109" = "Hungary";                                   "11" = "Argentina";                          "110" = "Iceland";                                                                                                                                            
    "111" = "Indonesia";                                 "113" = "India";                             "114" = "British Indian Ocean Territory";                                                                                                                                            
    "116" = "Iran";                                      "117" = "Israel";                            "118" = "Italy";                                                                                                                                            
    "119" = "Côte d'Ivoire";                             "12" = "Australia";                          "121" = "Iraq";                                                                                                                                            
    "122" = "Japan";                                     "124" = "Jamaica";                           "125" = "Jan Mayen";                                                                                                                                            
    "126" = "Jordan";                                    "127" = "Johnston Atoll";                    "129" = "Kenya";                                                                                                                                            
    "130" = "Kyrgyzstan";                                "131" = "North Korea";                       "133" = "Kiribati";                                                                                                                                            
    "134" = "Korea";                                     "136" = "Kuwait";                            "137" = "Kazakhstan";                                                                                                                                            
    "138" = "Laos";                                      "139" = "Lebanon";                           "14" = "Austria";                                                                                                                                            
    "140" = "Latvia";                                    "141" = "Lithuania";                         "142" = "Liberia";                                                                                                                                            
    "143" = "Slovakia";                                  "145" = "Liechtenstein";                     "146" = "Lesotho";                                                                                                                                            
    "147" = "Luxembourg";                                "148" = "Libya";                             "149" = "Madagascar";                                                                                                                                            
    "151" = "Macao SAR";                                 "15126" = "Isle of Man";                     "152" = "Moldova";                                                                                                                                            
    "154" = "Mongolia";                                  "156" = "Malawi";                            "157" = "Mali";                                                                                                                                            
    "158" = "Monaco";                                    "159" = "Morocco";                           "160" = "Mauritius";                                                                                                                                            
    "161832015" = "Saint Barthélemy";                    "161832256" = "U.S. Minor Outlying Islands"; "161832257" = "Latin America and the Caribbean";                                                                                                                                            
    "161832258" = "Bonaire, Sint Eustatius and Saba";    "162" = "Mauritania";                        "163" = "Malta";                                                                                                                                            
    "164" = "Oman";                                      "165" = "Maldives";                          "166" = "Mexico";                                                                                                                                            
    "167" = "Malaysia";                                  "168" = "Mozambique";                        "17" = "Bahrain";                                                                                                                                            
    "173" = "Niger";                                     "174" = "Vanuatu";                           "175" = "Nigeria";                                                                                                                                            
    "176" = "Netherlands";                               "177" = "Norway";                            "178" = "Nepal";                                                                                                                                            
    "18" = "Barbados";                                   "180" = "Nauru";                             "181" = "Suriname";                                                                                                                                            
    "182" = "Nicaragua";                                 "183" = "New Zealand";                       "184" = "Palestinian Authority";                                                                                                                                            
    "185" = "Paraguay";                                  "187" = "Peru";                              "19" = "Botswana";                                                                                                                                            
    "190" = "Pakistan";                                  "191" = "Poland";                            "192" = "Panama";                                                                                                                                            
    "193" = "Portugal";                                  "194" = "Papua New Guinea";                  "195" = "Palau";                                                                                                                                            
    "196" = "Guinea-Bissau";                             "19618" = "North Macedonia";                 "197" = "Qatar";                                                                                                                                            
    "198" = "Réunion";                                   "199" = "Marshall Islands";                  "2" = "Antigua and Barbuda";                                                                                                                                            
    "20" = "Bermuda";                                    "200" = "Romania";                           "201" = "Philippines";                                                                                                                                            
    "202" = "Puerto Rico";                               "203" = "Russia";                            "204" = "Rwanda";                                                                                                                                            
    "205" = "Saudi Arabia";                              "206" = "Saint Pierre and Miquelon";         "207" = "Saint Kitts and Nevis";                                                                                                                                            
    "208" = "Seychelles";                                "209" = "South Africa";                      "20900" = "Melanesia";                                                                                                                                            
    "21" = "Belgium";                                    "210" = "Senegal";                           "212" = "Slovenia";                                                                                                                                            
    "21206" = "Micronesia";                              "21242" = "Midway Islands";                  "2129" = "Asia";                                                                                                                                            
    "213" = "Sierra Leone";                              "214" = "San Marino";                        "215" = "Singapore";                                                                                                                                            
    "216" = "Somalia";                                   "217" = "Spain";                             "218" = "Saint Lucia";                                                                                                                                            
    "219" = "Sudan";                                     "22" = "Bahamas";                            "220" = "Svalbard";                                                                                                                                            
    "221" = "Sweden";                                    "222" = "Syria";                             "223" = "Switzerland";                                                                                                                                            
    "224" = "United Arab Emirates";                      "225" = "Trinidad and Tobago";               "227" = "Thailand";                                                                                                                                            
    "228" = "Tajikistan";                                "23" = "Bangladesh";                         "231" = "Tonga";                                                                                                                                            
    "232" = "Togo";                                      "233" = "São Tomé and Príncipe";             "234" = "Tunisia";                                                                                                                                            
    "235" = "Turkey";                                    "23581" = "Northern America";                "236" = "Tuvalu";                                                                                                                                            
    "237" = "Taiwan";                                    "238" = "Turkmenistan";                      "239" = "Tanzania";                                                                                                                                            
    "24" = "Belize";                                     "240" = "Uganda";                            "241" = "Ukraine";                                                                                                                                            
    "242" = "United Kingdom";                            "244" = "United States";                     "245" = "Burkina Faso";                                                                                                                                            
    "246" = "Uruguay";                                   "247" = "Uzbekistan";                        "248" = "Saint Vincent and the Grenadines";                                                                                                                                            
    "249" = "Venezuela";                                 "25" = "Bosnia and Herzegovina";             "251" = "Vietnam";                                                                                                                                            
    "252" = "U.S. Virgin Islands";                       "253" = "Vatican City";                      "254" = "Namibia";                                                                                                                                            
    "258" = "Wake Island";                               "259" = "Samoa";                             "26" = "Bolivia";                                                                                                                                            
    "260" = "Swaziland";                                 "261" = "Yemen";                             "26286" = "Polynesia";                                                                                                                                            
    "263" = "Zambia";                                    "264" = "Zimbabwe";                          "269" = "Serbia and Montenegro (Former)";                                                                                                                                            
    "27" = "Myanmar";                                    "270" = "Montenegro";                        "27082" = "Central America";                                                                                                                                            
    "271" = "Serbia";                                    "27114" = "Oceania";                         "273" = "Curaçao";                                                                                                                                            
    "276" = "South Sudan";                               "28" = "Benin";                              "29" = "Belarus";                                                                                                                                            
    "3" = "Afghanistan";                                 "30" = "Solomon Islands";                    "300" = "Anguilla";                                                                                                                                            
    "301" = "Antarctica";                                "302" = "Aruba";                             "303" = "Ascension Island";                                                                                                                                            
    "304" = "Ashmore and Cartier Islands";               "305" = "Baker Island";                      "306" = "Bouvet Island";                                                                                                                                            
    "307" = "Cayman Islands";                            "308" = "Channel Islands";                   "309" = "Christmas Island";                                                                                                                                            
    "30967" = "Sint Maarten";                            "310" = "Clipperton Island";                 "311" = "Cocos (Keeling) Islands";                                                                                                                                            
    "312" = "Cook Islands";                              "313" = "Coral Sea Islands";                 "31396" = "South America";                                                                                                                                            
    "314" = "Diego Garcia";                              "315" = "Falkland Islands";                  "317" = "French Guiana";                                                                                                                                            
    "31706" = "Saint Martin";                            "318" = "French Polynesia";                  "319" = "French Southern Territories";                                                                                                                                            
    "32" = "Brazil";                                     "321" = "Guadeloupe";                        "322" = "Guam";                                                                                                                                            
    "323" = "Guantanamo Bay";                            "324" = "Guernsey";                          "325" = "Heard Island and McDonald Islands";                                                                                                                                            
    "326" = "Howland Island";                            "327" = "Jarvis Island";                     "328" = "Jersey";                                                                                                                                            
    "329" = "Kingman Reef";                              "330" = "Martinique";                        "331" = "Mayotte";                                                                                                                                            
    "332" = "Montserrat";                                "333" = "Netherlands Antilles (Former)";     "334" = "New Caledonia";                                                                                                                                            
    "335" = "Niue";                                      "336" = "Norfolk Island";                    "337" = "Northern Mariana Islands";                                                                                                                                            
    "338" = "Palmyra Atoll";                             "339" = "Pitcairn Islands";                  "34" = "Bhutan";                                                                                                                                            
    "340" = "Rota Island";                               "341" = "Saipan";                            "342" = "South Georgia and the South Sandwich Islands";                                                                                                                                            
    "343" = "St Helena, Ascension and Tristan da Cunha"; "346" = "Tinian Island";                     "347" = "Tokelau";                                                                                                                                            
    "348" = "Tristan da Cunha";                          "349" = "Turks and Caicos Islands";          "35" = "Bulgaria";                                                                                                                                            
    "351" = "British Virgin Islands";                    "352" = "Wallis and Futuna";                 "37" = "Brunei";                                                                                                                                            
    "38" = "Burundi";                                    "39" = "Canada";                             "39070" = "World";                                                                                                                                            
    "4" = "Algeria";                                     "40" = "Cambodia";                           "41" = "Chad";                                                                                                                                            
    "42" = "Sri Lanka";                                  "42483" = "Western Africa";                  "42484" = "Middle Africa";                                                                                                                                            
    "42487" = "Northern Africa";                         "43" = "Congo";                              "44" = "Congo (DRC)";                                                                                                                                            
    "45" = "China";                                      "46" = "Chile";                              "47590" = "Central Asia";                                                                                                                                            
    "47599" = "South-Eastern Asia";                      "47600" = "Eastern Asia";                    "47603" = "Eastern Africa";                                                                                                                                            
    "47609" = "Eastern Europe";                          "47610" = "Southern Europe";                 "47611" = "Middle East";                                                                                                                                            
    "47614" = "Southern Asia";                           "49" = "Cameroon";                           "5" = "Azerbaijan";                                                                                                                                            
    "50" = "Comoros";                                    "51" = "Colombia";                           "54" = "Costa Rica";                                                                                                                                            
    "55" = "Central African Republic";                   "56" = "Cuba";                               "57" = "Cabo Verde";                                                                                                                                            
    "59" = "Cyprus";                                     "6" = "Albania";                             "61" = "Denmark";                                                                                                                                            
    "62" = "Djibouti";                                   "63" = "Dominica";                           "65" = "Dominican Republic";                                                                                                                                            
    "66" = "Ecuador";                                    "67" = "Egypt";                              "68" = "Ireland";                                                                                                                                            
    "69" = "Equatorial Guinea";                          "7" = "Armenia";                             "70" = "Estonia";                                                                                                                                            
    "71" = "Eritrea";                                    "72" = "El Salvador";                        "7299303" = "Timor-Leste";                                                                                                                                            
    "73" = "Ethiopia";                                   "742" = "Africa";                            "75" = "Czech Republic";                                                                                                                                            
    "77" = "Finland";                                    "78" = "Fiji";                               "8" = "Andorra";                                                                                                                                            
    "80" = "Micronesia";                                 "81" = "Faroe Islands";                      "84" = "France";                                                                                                                                            
    "86" = "Gambia";                                     "87" = "Gabon";                              "88" = "Georgia";                                                                                                                                            
    "89" = "Ghana";                                      "9" = "Angola";                              "90" = "Gibraltar";                                                                                                                                            
    "91" = "Grenada";                                    "93" = "Greenland";                          "94" = "Germany";                                                                                                                                            
    "98" = "Greece";                                     "99" = "Guatemala";                          "9914689" = "Kosovo";                                                                                                                                            
}
$languageLookup = @{
    "aa" = "Afar";                                                "aa-DJ" = "Afar (Djibouti)";                                       "aa-ER" = "Afar (Eritrea)";                                                                                                                                            
    "aa-ET" = "Afar (Ethiopia)";                                  "af" = "Afrikaans";                                                "af-NA" = "Afrikaans (Namibia)";                                                                                                                                            
    "af-ZA" = "Afrikaans (South Africa)";                         "agq" = "Aghem";                                                   "agq-CM" = "Aghem (Cameroon)";                                                                                                                                            
    "ak" = "Akan";                                                "ak-GH" = "Akan (Ghana)";                                          "am" = "Amharic";                                                                                                                                            
    "am-ET" = "Amharic (Ethiopia)";                               "ar" = "Arabic";                                                   "ar-001" = "Arabic (World)";                                                                                                                                            
    "ar-AE" = "Arabic (U.A.E.)";                                  "ar-BH" = "Arabic (Bahrain)";                                      "ar-DJ" = "Arabic (Djibouti)";                                                                                                                                            
    "ar-DZ" = "Arabic (Algeria)";                                 "ar-EG" = "Arabic (Egypt)";                                        "ar-ER" = "Arabic (Eritrea)";                                                                                                                                            
    "ar-IL" = "Arabic (Israel)";                                  "ar-IQ" = "Arabic (Iraq)";                                         "ar-JO" = "Arabic (Jordan)";                                                                                                                                            
    "ar-KM" = "Arabic (Comoros)";                                 "ar-KW" = "Arabic (Kuwait)";                                       "ar-LB" = "Arabic (Lebanon)";                                                                                                                                            
    "ar-LY" = "Arabic (Libya)";                                   "ar-MA" = "Arabic (Morocco)";                                      "ar-MR" = "Arabic (Mauritania)";                                                                                                                                            
    "ar-OM" = "Arabic (Oman)";                                    "ar-PS" = "Arabic (Palestinian Authority)";                        "ar-QA" = "Arabic (Qatar)";                                                                                                                                            
    "ar-SA" = "Arabic (Saudi Arabia)";                            "ar-SD" = "Arabic (Sudan)";                                        "ar-SO" = "Arabic (Somalia)";                                                                                                                                            
    "ar-SS" = "Arabic (South Sudan)";                             "ar-SY" = "Arabic (Syria)";                                        "ar-TD" = "Arabic (Chad)";                                                                                                                                            
    "ar-TN" = "Arabic (Tunisia)";                                 "ar-YE" = "Arabic (Yemen)";                                        "arn" = "Mapudungun";                                                                                                                                            
    "arn-CL" = "Mapudungun (Chile)";                              "as" = "Assamese";                                                 "as-IN" = "Assamese (India)";                                                                                                                                            
    "asa" = "Asu";                                                "asa-TZ" = "Asu (Tanzania)";                                       "ast" = "Asturian";                                                                                                                                            
    "ast-ES" = "Asturian (Spain)";                                "az" = "Azerbaijani";                                              "az-Cyrl" = "Azerbaijani (Cyrillic)";                                                                                                                                            
    "az-Cyrl-AZ" = "Azerbaijani (Cyrillic, Azerbaijan)";          "az-Latn" = "Azerbaijani (Latin)";                                 "az-Latn-AZ" = "Azerbaijani (Latin, Azerbaijan)";                                                                                                                                            
    "ba" = "Bashkir";                                             "ba-RU" = "Bashkir (Russia)";                                      "bas" = "Basaa";                                                                                                                                            
    "bas-CM" = "Basaa (Cameroon)";                                "be" = "Belarusian";                                               "be-BY" = "Belarusian (Belarus)";                                                                                                                                            
    "bem" = "Bemba";                                              "bem-ZM" = "Bemba (Zambia)";                                       "bez" = "Bena";                                                                                                                                            
    "bez-TZ" = "Bena (Tanzania)";                                 "bg" = "Bulgarian";                                                "bg-BG" = "Bulgarian (Bulgaria)";                                                                                                                                            
    "bin" = "Edo";                                                "bin-NG" = "Edo (Nigeria)";                                        "bm" = "Bambara";                                                                                                                                            
    "bm-Latn" = "Bambara (Latin)";                                "bm-Latn-ML" = "Bambara (Latin, Mali)";                            "bn" = "Bangla";                                                                                                                                            
    "bn-BD" = "Bangla (Bangladesh)";                              "bn-IN" = "Bangla (India)";                                        "bo" = "Tibetan";                                                                                                                                            
    "bo-CN" = "Tibetan (PRC)";                                    "bo-IN" = "Tibetan (India)";                                       "br" = "Breton";                                                                                                                                            
    "br-FR" = "Breton (France)";                                  "brx" = "Bodo";                                                    "brx-IN" = "Bodo (India)";                                                                                                                                            
    "bs" = "Bosnian";                                             "bs-Cyrl" = "Bosnian (Cyrillic)";                                  "bs-Cyrl-BA" = "Bosnian (Cyrillic, Bosnia and Herzegovina)";                                                                                                                                            
    "bs-Latn" = "Bosnian (Latin)";                                "bs-Latn-BA" = "Bosnian (Latin, Bosnia and Herzegovina)";          "byn" = "Blin";                                                                                                                                            
    "byn-ER" = "Blin (Eritrea)";                                  "ca" = "Catalan";                                                  "ca-AD" = "Catalan (Andorra)";                                                                                                                                            
    "ca-ES" = "Catalan (Catalan)";                                "ca-ES-valencia" = "Valencian (Spain)";                            "ca-FR" = "Catalan (France)";                                                                                                                                            
    "ca-IT" = "Catalan (Italy)";                                  "ce" = "Chechen";                                                  "ce-RU" = "Chechen (Russia)";                                                                                                                                            
    "cgg" = "Chiga";                                              "cgg-UG" = "Chiga (Uganda)";                                       "chr" = "Cherokee";                                                                                                                                            
    "chr-Cher" = "Cherokee (Cherokee)";                           "chr-Cher-US" = "Cherokee (Cherokee)";                             "co" = "Corsican";                                                                                                                                            
    "co-FR" = "Corsican (France)";                                "cs" = "Czech";                                                    "cs-CZ" = "Czech (Czechia / Czech Republic)";                                                                                                                                            
    "cu" = "Church Slavic";                                       "cu-RU" = "Church Slavic (Russia)";                                "cy" = "Welsh";                                                                                                                                            
    "cy-GB" = "Welsh (United Kingdom)";                           "da" = "Danish";                                                   "da-DK" = "Danish (Denmark)";                                                                                                                                            
    "da-GL" = "Danish (Greenland)";                               "dav" = "Taita";                                                   "dav-KE" = "Taita (Kenya)";                                                                                                                                            
    "de" = "German";                                              "de-AT" = "German (Austria)";                                      "de-BE" = "German (Belgium)";                                                                                                                                            
    "de-CH" = "German (Switzerland)";                             "de-DE" = "German (Germany)";                                      "de-IT" = "German (Italy)";                                                                                                                                            
    "de-LI" = "German (Liechtenstein)";                           "de-LU" = "German (Luxembourg)";                                   "dje" = "Zarma";                                                                                                                                            
    "dje-NE" = "Zarma (Niger)";                                   "dsb" = "Lower Sorbian";                                           "dsb-DE" = "Lower Sorbian (Germany)";                                                                                                                                            
    "dua" = "Duala";                                              "dua-CM" = "Duala (Cameroon)";                                     "dv" = "Divehi";                                                                                                                                            
    "dv-MV" = "Divehi (Maldives)";                                "dyo" = "Jola-Fonyi";                                              "dyo-SN" = "Jola-Fonyi (Senegal)";                                                                                                                                            
    "dz" = "Dzongkha";                                            "dz-BT" = "Dzongkha (Bhutan)";                                     "ebu" = "Embu";                                                                                                                                            
    "ebu-KE" = "Embu (Kenya)";                                    "ee" = "Ewe";                                                      "ee-GH" = "Ewe (Ghana)";                                                                                                                                            
    "ee-TG" = "Ewe (Togo)";                                       "el" = "Greek";                                                    "el-CY" = "Greek (Cyprus)";                                                                                                                                            
    "el-GR" = "Greek (Greece)";                                   "en" = "English";                                                  "en-001" = "English (World)";                                                                                                                                            
    "en-029" = "English (Caribbean)";                             "en-150" = "English (Europe)";                                     "en-AG" = "English (Antigua and Barbuda)";                                                                                                                                            
    "en-AI" = "English (Anguilla)";                               "en-AS" = "English (American Samoa)";                              "en-AT" = "English (Austria)";                                                                                                                                            
    "en-AU" = "English (Australia)";                              "en-BB" = "English (Barbados)";                                    "en-BE" = "English (Belgium)";                                                                                                                                            
    "en-BI" = "English (Burundi)";                                "en-BM" = "English (Bermuda)";                                     "en-BS" = "English (Bahamas)";                                                                                                                                            
    "en-BW" = "English (Botswana)";                               "en-BZ" = "English (Belize)";                                      "en-CA" = "English (Canada)";                                                                                                                                            
    "en-CC" = "English (Cocos [Keeling] Islands)";                "en-CH" = "English (Switzerland)";                                 "en-CK" = "English (Cook Islands)";                                                                                                                                            
    "en-CM" = "English (Cameroon)";                               "en-CX" = "English (Christmas Island)";                            "en-CY" = "English (Cyprus)";                                                                                                                                            
    "en-DE" = "English (Germany)";                                "en-DK" = "English (Denmark)";                                     "en-DM" = "English (Dominica)";                                                                                                                                            
    "en-ER" = "English (Eritrea)";                                "en-FI" = "English (Finland)";                                     "en-FJ" = "English (Fiji)";                                                                                                                                            
    "en-FK" = "English (Falkland Islands)";                       "en-FM" = "English (Micronesia)";                                  "en-GB" = "English (United Kingdom)";                                                                                                                                            
    "en-GD" = "English (Grenada)";                                "en-GG" = "English (Guernsey)";                                    "en-GH" = "English (Ghana)";                                                                                                                                            
    "en-GI" = "English (Gibraltar)";                              "en-GM" = "English (Gambia)";                                      "en-GU" = "English (Guam)";                                                                                                                                            
    "en-GY" = "English (Guyana)";                                 "en-HK" = "English (Hong Kong SAR)";                               "en-ID" = "English (Indonesia)";                                                                                                                                            
    "en-IE" = "English (Ireland)";                                "en-IL" = "English (Israel)";                                      "en-IM" = "English (Isle of Man)";                                                                                                                                            
    "en-IN" = "English (India)";                                  "en-IO" = "English (British Indian Ocean Territory)";              "en-JE" = "English (Jersey)";                                                                                                                                            
    "en-JM" = "English (Jamaica)";                                "en-KE" = "English (Kenya)";                                       "en-KI" = "English (Kiribati)";                                                                                                                                            
    "en-KN" = "English (Saint Kitts and Nevis)";                  "en-KY" = "English (Cayman Islands)";                              "en-LC" = "English (Saint Lucia)";                                                                                                                                            
    "en-LR" = "English (Liberia)";                                "en-LS" = "English (Lesotho)";                                     "en-MG" = "English (Madagascar)";                                                                                                                                            
    "en-MH" = "English (Marshall Islands)";                       "en-MO" = "English (Macao SAR)";                                   "en-MP" = "English (Northern Mariana Islands)";                                                                                                                                            
    "en-MS" = "English (Montserrat)";                             "en-MT" = "English (Malta)";                                       "en-MU" = "English (Mauritius)";                                                                                                                                            
    "en-MW" = "English (Malawi)";                                 "en-MY" = "English (Malaysia)";                                    "en-NA" = "English (Namibia)";                                                                                                                                            
    "en-NF" = "English (Norfolk Island)";                         "en-NG" = "English (Nigeria)";                                     "en-NL" = "English (Netherlands)";                                                                                                                                            
    "en-NR" = "English (Nauru)";                                  "en-NU" = "English (Niue)";                                        "en-NZ" = "English (New Zealand)";                                                                                                                                            
    "en-PG" = "English (Papua New Guinea)";                       "en-PH" = "English (Philippines)";                                 "en-PK" = "English (Pakistan)";                                                                                                                                            
    "en-PN" = "English (Pitcairn Islands)";                       "en-PR" = "English (Puerto Rico)";                                 "en-PW" = "English (Palau)";                                                                                                                                            
    "en-RW" = "English (Rwanda)";                                 "en-SB" = "English (Solomon Islands)";                             "en-SC" = "English (Seychelles)";                                                                                                                                            
    "en-SD" = "English (Sudan)";                                  "en-SE" = "English (Sweden)";                                      "en-SG" = "English (Singapore)";                                                                                                                                            
    "en-SH" = "English (St Helena, Ascension, Tristan da Cunha)"; "en-SI" = "English (Slovenia)";                                    "en-SL" = "English (Sierra Leone)";                                                                                                                                            
    "en-SS" = "English (South Sudan)";                            "en-SX" = "English (Sint Maarten)";                                "en-SZ" = "English (Swaziland)";                                                                                                                                            
    "en-TC" = "English (Turks and Caicos Islands)";               "en-TK" = "English (Tokelau)";                                     "en-TO" = "English (Tonga)";                                                                                                                                            
    "en-TT" = "English (Trinidad and Tobago)";                    "en-TV" = "English (Tuvalu)";                                      "en-TZ" = "English (Tanzania)";                                                                                                                                            
    "en-UG" = "English (Uganda)";                                 "en-UM" = "English (US Minor Outlying Islands)";                   "en-US" = "English (United States)";                                                                                                                                            
    "en-VC" = "English (Saint Vincent and the Grenadines)";       "en-VG" = "English (British Virgin Islands)";                      "en-VI" = "English (US Virgin Islands)";                                                                                                                                            
    "en-VU" = "English (Vanuatu)";                                "en-WS" = "English (Samoa)";                                       "en-ZA" = "English (South Africa)";                                                                                                                                            
    "en-ZM" = "English (Zambia)";                                 "en-ZW" = "English (Zimbabwe)";                                    "eo" = "Esperanto";                                                                                                                                            
    "eo-001" = "Esperanto (World)";                               "es" = "Spanish";                                                  "es-419" = "Spanish (Latin America)";                                                                                                                                            
    "es-AR" = "Spanish (Argentina)";                              "es-BO" = "Spanish (Bolivia)";                                     "es-BR" = "Spanish (Brazil)";                                                                                                                                            
    "es-BZ" = "Spanish (Belize)";                                 "es-CL" = "Spanish (Chile)";                                       "es-CO" = "Spanish (Colombia)";                                                                                                                                            
    "es-CR" = "Spanish (Costa Rica)";                             "es-CU" = "Spanish (Cuba)";                                        "es-DO" = "Spanish (Dominican Republic)";                                                                                                                                            
    "es-EC" = "Spanish (Ecuador)";                                "es-ES" = "Spanish (Spain)";                                       "es-GQ" = "Spanish (Equatorial Guinea)";                                                                                                                                            
    "es-GT" = "Spanish (Guatemala)";                              "es-HN" = "Spanish (Honduras)";                                    "es-MX" = "Spanish (Mexico)";                                                                                                                                            
    "es-NI" = "Spanish (Nicaragua)";                              "es-PA" = "Spanish (Panama)";                                      "es-PE" = "Spanish (Peru)";                                                                                                                                            
    "es-PH" = "Spanish (Philippines)";                            "es-PR" = "Spanish (Puerto Rico)";                                 "es-PY" = "Spanish (Paraguay)";                                                                                                                                            
    "es-SV" = "Spanish (El Salvador)";                            "es-US" = "Spanish (United States)";                               "es-UY" = "Spanish (Uruguay)";                                                                                                                                            
    "es-VE" = "Spanish (Venezuela)";                              "et" = "Estonian";                                                 "et-EE" = "Estonian (Estonia)";                                                                                                                                            
    "eu" = "Basque";                                              "eu-ES" = "Basque (Basque)";                                       "ewo" = "Ewondo";                                                                                                                                            
    "ewo-CM" = "Ewondo (Cameroon)";                               "fa" = "Persian";                                                  "fa-IR" = "Persian (Iran)";                                                                                                                                            
    "ff" = "Fulah";                                               "ff-CM" = "Fulah (Cameroon)";                                      "ff-GN" = "Fulah (Guinea)";                                                                                                                                            
    "ff-Latn" = "Fulah (Latin)";                                  "ff-Latn-SN" = "Fulah (Latin, Senegal)";                           "ff-MR" = "Fulah (Mauritania)";                                                                                                                                            
    "ff-NG" = "Fulah (Nigeria)";                                  "fi" = "Finnish";                                                  "fi-FI" = "Finnish (Finland)";                                                                                                                                            
    "fil" = "Filipino";                                           "fil-PH" = "Filipino (Philippines)";                               "fo" = "Faroese";                                                                                                                                            
    "fo-DK" = "Faroese (Denmark)";                                "fo-FO" = "Faroese (Faroe Islands)";                               "fr" = "French";                                                                                                                                            
    "fr-029" = "French (Caribbean)";                              "fr-BE" = "French (Belgium)";                                      "fr-BF" = "French (Burkina Faso)";                                                                                                                                            
    "fr-BI" = "French (Burundi)";                                 "fr-BJ" = "French (Benin)";                                        "fr-BL" = "French (Saint Barthélemy)";                                                                                                                                            
    "fr-CA" = "French (Canada)";                                  "fr-CD" = "French (Congo DRC)";                                    "fr-CF" = "French (Central African Republic)";                                                                                                                                            
    "fr-CG" = "French (Congo)";                                   "fr-CH" = "French (Switzerland)";                                  "fr-CI" = "French (Côte d’Ivoire)";                                                                                                                                            
    "fr-CM" = "French (Cameroon)";                                "fr-DJ" = "French (Djibouti)";                                     "fr-DZ" = "French (Algeria)";                                                                                                                                            
    "fr-FR" = "French (France)";                                  "fr-GA" = "French (Gabon)";                                        "fr-GF" = "French (French Guiana)";                                                                                                                                            
    "fr-GN" = "French (Guinea)";                                  "fr-GP" = "French (Guadeloupe)";                                   "fr-GQ" = "French (Equatorial Guinea)";                                                                                                                                            
    "fr-HT" = "French (Haiti)";                                   "fr-KM" = "French (Comoros)";                                      "fr-LU" = "French (Luxembourg)";                                                                                                                                            
    "fr-MA" = "French (Morocco)";                                 "fr-MC" = "French (Monaco)";                                       "fr-MF" = "French (Saint Martin)";                                                                                                                                            
    "fr-MG" = "French (Madagascar)";                              "fr-ML" = "French (Mali)";                                         "fr-MQ" = "French (Martinique)";                                                                                                                                            
    "fr-MR" = "French (Mauritania)";                              "fr-MU" = "French (Mauritius)";                                    "fr-NC" = "French (New Caledonia)";                                                                                                                                            
    "fr-NE" = "French (Niger)";                                   "fr-PF" = "French (French Polynesia)";                             "fr-PM" = "French (Saint Pierre and Miquelon)";                                                                                                                                            
    "fr-RE" = "French (Reunion)";                                 "fr-RW" = "French (Rwanda)";                                       "fr-SC" = "French (Seychelles)";                                                                                                                                            
    "fr-SN" = "French (Senegal)";                                 "fr-SY" = "French (Syria)";                                        "fr-TD" = "French (Chad)";                                                                                                                                            
    "fr-TG" = "French (Togo)";                                    "fr-TN" = "French (Tunisia)";                                      "fr-VU" = "French (Vanuatu)";                                                                                                                                            
    "fr-WF" = "French (Wallis and Futuna)";                       "fr-YT" = "French (Mayotte)";                                      "fur" = "Friulian";                                                                                                                                            
    "fur-IT" = "Friulian (Italy)";                                "fy" = "Frisian";                                                  "fy-NL" = "Frisian (Netherlands)";                                                                                                                                            
    "ga" = "Irish";                                               "ga-IE" = "Irish (Ireland)";                                       "gd" = "Scottish Gaelic";                                                                                                                                            
    "gd-GB" = "Scottish Gaelic (United Kingdom)";                 "gl" = "Galician";                                                 "gl-ES" = "Galician (Galician)";                                                                                                                                            
    "gn" = "Guarani";                                             "gn-PY" = "Guarani (Paraguay)";                                    "gsw" = "Alsatian";                                                                                                                                            
    "gsw-CH" = "Alsatian (Switzerland)";                          "gsw-FR" = "Alsatian (France)";                                    "gsw-LI" = "Alsatian (Liechtenstein)";                                                                                                                                            
    "gu" = "Gujarati";                                            "gu-IN" = "Gujarati (India)";                                      "guz" = "Gusii";                                                                                                                                            
    "guz-KE" = "Gusii (Kenya)";                                   "gv" = "Manx";                                                     "gv-IM" = "Manx (Isle of Man)";                                                                                                                                            
    "ha" = "Hausa";                                               "ha-Latn" = "Hausa (Latin)";                                       "ha-Latn-GH" = "Hausa (Latin, Ghana)";                                                                                                                                            
    "ha-Latn-NE" = "Hausa (Latin, Niger)";                        "ha-Latn-NG" = "Hausa (Latin, Nigeria)";                           "haw" = "Hawaiian";                                                                                                                                            
    "haw-US" = "Hawaiian (United States)";                        "he" = "Hebrew";                                                   "he-IL" = "Hebrew (Israel)";                                                                                                                                            
    "hi" = "Hindi";                                               "hi-IN" = "Hindi (India)";                                         "hr" = "Croatian";                                                                                                                                            
    "hr-BA" = "Croatian (Latin, Bosnia and Herzegovina)";         "hr-HR" = "Croatian (Croatia)";                                    "hsb" = "Upper Sorbian";                                                                                                                                            
    "hsb-DE" = "Upper Sorbian (Germany)";                         "hu" = "Hungarian";                                                "hu-HU" = "Hungarian (Hungary)";                                                                                                                                            
    "hy" = "Armenian";                                            "hy-AM" = "Armenian (Armenia)";                                    "ia" = "Interlingua";                                                                                                                                            
    "ia-001" = "Interlingua (World)";                             "ia-FR" = "Interlingua (France)";                                  "ibb" = "Ibibio";                                                                                                                                            
    "ibb-NG" = "Ibibio (Nigeria)";                                "id" = "Indonesian";                                               "id-ID" = "Indonesian (Indonesia)";                                                                                                                                            
    "ig" = "Igbo";                                                "ig-NG" = "Igbo (Nigeria)";                                        "ii" = "Yi";                                                                                                                                            
    "ii-CN" = "Yi (PRC)";                                         "is" = "Icelandic";                                                "is-IS" = "Icelandic (Iceland)";                                                                                                                                            
    "it" = "Italian";                                             "it-CH" = "Italian (Switzerland)";                                 "it-IT" = "Italian (Italy)";                                                                                                                                            
    "it-SM" = "Italian (San Marino)";                             "it-VA" = "Italian (Vatican City)";                                "iu" = "Inuktitut";                                                                                                                                            
    "iu-Cans" = "Inuktitut (Syllabics)";                          "iu-Cans-CA" = "Inuktitut (Syllabics, Canada)";                    "iu-Latn" = "Inuktitut (Latin)";                                                                                                                                            
    "iu-Latn-CA" = "Inuktitut (Latin, Canada)";                   "ja" = "Japanese";                                                 "ja-JP" = "Japanese (Japan)";                                                                                                                                            
    "jgo" = "Ngomba";                                             "jgo-CM" = "Ngomba (Cameroon)";                                    "jmc" = "Machame";                                                                                                                                            
    "jmc-TZ" = "Machame (Tanzania)";                              "jv" = "Javanese";                                                 "jv-Java" = "Javanese (Javanese)";                                                                                                                                            
    "jv-Java-ID" = "Javanese (Javanese, Indonesia)";              "jv-Latn" = "Javanese";                                            "jv-Latn-ID" = "Javanese (Indonesia)";                                                                                                                                            
    "ka" = "Georgian";                                            "ka-GE" = "Georgian (Georgia)";                                    "kab" = "Kabyle";                                                                                                                                            
    "kab-DZ" = "Kabyle (Algeria)";                                "kam" = "Kamba";                                                   "kam-KE" = "Kamba (Kenya)";                                                                                                                                            
    "kde" = "Makonde";                                            "kde-TZ" = "Makonde (Tanzania)";                                   "kea" = "Kabuverdianu";                                                                                                                                            
    "kea-CV" = "Kabuverdianu (Cabo Verde)";                       "khq" = "Koyra Chiini";                                            "khq-ML" = "Koyra Chiini (Mali)";                                                                                                                                            
    "ki" = "Kikuyu";                                              "ki-KE" = "Kikuyu (Kenya)";                                        "kk" = "Kazakh";                                                                                                                                            
    "kk-KZ" = "Kazakh (Kazakhstan)";                              "kkj" = "Kako";                                                    "kkj-CM" = "Kako (Cameroon)";                                                                                                                                            
    "kl" = "Greenlandic";                                         "kl-GL" = "Greenlandic (Greenland)";                               "kln" = "Kalenjin";                                                                                                                                            
    "kln-KE" = "Kalenjin (Kenya)";                                "km" = "Khmer";                                                    "km-KH" = "Khmer (Cambodia)";                                                                                                                                            
    "kn" = "Kannada";                                             "kn-IN" = "Kannada (India)";                                       "ko" = "Korean";                                                                                                                                            
    "ko-KP" = "Korean (North Korea)";                             "ko-KR" = "Korean (Korea)";                                        "kok" = "Konkani";                                                                                                                                            
    "kok-IN" = "Konkani (India)";                                 "kr" = "Kanuri";                                                   "kr-NG" = "Kanuri (Nigeria)";                                                                                                                                            
    "ks" = "Kashmiri";                                            "ks-Arab" = "Kashmiri (Perso-Arabic)";                             "ks-Arab-IN" = "Kashmiri (Perso-Arabic)";                                                                                                                                            
    "ks-Deva" = "Kashmiri (Devanagari)";                          "ks-Deva-IN" = "Kashmiri (Devanagari, India)";                     "ksb" = "Shambala";                                                                                                                                            
    "ksb-TZ" = "Shambala (Tanzania)";                             "ksf" = "Bafia";                                                   "ksf-CM" = "Bafia (Cameroon)";                                                                                                                                            
    "ksh" = "Colognian";                                          "ksh-DE" = "Ripuarian (Germany)";                                  "ku" = "Central Kurdish";                                                                                                                                            
    "ku-Arab" = "Central Kurdish (Arabic)";                       "ku-Arab-IQ" = "Central Kurdish (Iraq)";                           "ku-Arab-IR" = "Kurdish (Perso-Arabic, Iran)";                                                                                                                                            
    "kw" = "Cornish";                                             "kw-GB" = "Cornish (United Kingdom)";                              "ky" = "Kyrgyz";                                                                                                                                            
    "ky-KG" = "Kyrgyz (Kyrgyzstan)";                              "la" = "Latin";                                                    "la-001" = "Latin (World)";                                                                                                                                            
    "lag" = "Langi";                                              "lag-TZ" = "Langi (Tanzania)";                                     "lb" = "Luxembourgish";                                                                                                                                            
    "lb-LU" = "Luxembourgish (Luxembourg)";                       "lg" = "Ganda";                                                    "lg-UG" = "Ganda (Uganda)";                                                                                                                                            
    "lkt" = "Lakota";                                             "lkt-US" = "Lakota (United States)";                               "ln" = "Lingala";                                                                                                                                            
    "ln-AO" = "Lingala (Angola)";                                 "ln-CD" = "Lingala (Congo DRC)";                                   "ln-CF" = "Lingala (Central African Republic)";                                                                                                                                            
    "ln-CG" = "Lingala (Congo)";                                  "lo" = "Lao";                                                      "lo-LA" = "Lao (Lao P.D.R.)";                                                                                                                                            
    "lrc" = "Northern Luri";                                      "lrc-IQ" = "Northern Luri (Iraq)";                                 "lrc-IR" = "Northern Luri (Iran)";                                                                                                                                            
    "lt" = "Lithuanian";                                          "lt-LT" = "Lithuanian (Lithuania)";                                "lu" = "Luba-Katanga";                                                                                                                                            
    "lu-CD" = "Luba-Katanga (Congo DRC)";                         "luo" = "Luo";                                                     "luo-KE" = "Luo (Kenya)";                                                                                                                                            
    "luy" = "Luyia";                                              "luy-KE" = "Luyia (Kenya)";                                        "lv" = "Latvian";                                                                                                                                            
    "lv-LV" = "Latvian (Latvia)";                                 "mas" = "Masai";                                                   "mas-KE" = "Masai (Kenya)";                                                                                                                                            
    "mas-TZ" = "Masai (Tanzania)";                                "mer" = "Meru";                                                    "mer-KE" = "Meru (Kenya)";                                                                                                                                            
    "mfe" = "Morisyen";                                           "mfe-MU" = "Morisyen (Mauritius)";                                 "mg" = "Malagasy";                                                                                                                                            
    "mg-MG" = "Malagasy (Madagascar)";                            "mgh" = "Makhuwa-Meetto";                                          "mgh-MZ" = "Makhuwa-Meetto (Mozambique)";                                                                                                                                            
    "mgo" = "Meta'";                                              "mgo-CM" = "Meta' (Cameroon)";                                     "mi" = "Maori";                                                                                                                                            
    "mi-NZ" = "Maori (New Zealand)";                              "mk" = "Macedonian (FYROM)";                                       "mk-MK" = "Macedonian (Former Yugoslav Republic of Macedonia)";                                                                                                                                            
    "ml" = "Malayalam";                                           "ml-IN" = "Malayalam (India)";                                     "mn" = "Mongolian";                                                                                                                                            
    "mn-Cyrl" = "Mongolian (Cyrillic)";                           "mn-MN" = "Mongolian (Cyrillic, Mongolia)";                        "mn-Mong" = "Mongolian (Traditional Mongolian)";                                                                                                                                            
    "mn-Mong-CN" = "Mongolian (Traditional Mongolian, PRC)";      "mn-Mong-MN" = "Mongolian (Traditional Mongolian, Mongolia)";      "mni" = "Manipuri";                                                                                                                                            
    "mni-IN" = "Manipuri (India)";                                "moh" = "Mohawk";                                                  "moh-CA" = "Mohawk (Mohawk)";                                                                                                                                            
    "mr" = "Marathi";                                             "mr-IN" = "Marathi (India)";                                       "ms" = "Malay";                                                                                                                                            
    "ms-BN" = "Malay (Brunei Darussalam)";                        "ms-MY" = "Malay (Malaysia)";                                      "ms-SG" = "Malay (Latin, Singapore)";                                                                                                                                            
    "mt" = "Maltese";                                             "mt-MT" = "Maltese (Malta)";                                       "mua" = "Mundang";                                                                                                                                            
    "mua-CM" = "Mundang (Cameroon)";                              "my" = "Burmese";                                                  "my-MM" = "Burmese (Myanmar)";                                                                                                                                            
    "mzn" = "Mazanderani";                                        "mzn-IR" = "Mazanderani (Iran)";                                   "naq" = "Nama";                                                                                                                                            
    "naq-NA" = "Nama (Namibia)";                                  "nb" = "Norwegian (Bokmål)";                                       "nb-NO" = "Norwegian, Bokmål (Norway)";                                                                                                                                            
    "nb-SJ" = "Norwegian, Bokmål (Svalbard and Jan Mayen)";       "nd" = "North Ndebele";                                            "nd-ZW" = "North Ndebele (Zimbabwe)";                                                                                                                                            
    "nds" = "Low German";                                         "nds-DE" = "Low German (Germany)";                                 "nds-NL" = "Low German (Netherlands)";                                                                                                                                            
    "ne" = "Nepali";                                              "ne-IN" = "Nepali (India)";                                        "ne-NP" = "Nepali (Nepal)";                                                                                                                                            
    "nl" = "Dutch";                                               "nl-AW" = "Dutch (Aruba)";                                         "nl-BE" = "Dutch (Belgium)";                                                                                                                                            
    "nl-BQ" = "Dutch (Bonaire, Sint Eustatius and Saba)";         "nl-CW" = "Dutch (Curaçao)";                                       "nl-NL" = "Dutch (Netherlands)";                                                                                                                                            
    "nl-SR" = "Dutch (Suriname)";                                 "nl-SX" = "Dutch (Sint Maarten)";                                  "nmg" = "Kwasio";                                                                                                                                            
    "nmg-CM" = "Kwasio (Cameroon)";                               "nn" = "Norwegian (Nynorsk)";                                      "nn-NO" = "Norwegian, Nynorsk (Norway)";                                                                                                                                            
    "nnh" = "Ngiemboon";                                          "nnh-CM" = "Ngiemboon (Cameroon)";                                 "no" = "Norwegian";                                                                                                                                            
    "nqo" = "N'ko";                                               "nqo-GN" = "N'ko (Guinea)";                                        "nr" = "South Ndebele";                                                                                                                                            
    "nr-ZA" = "South Ndebele (South Africa)";                     "nso" = "Sesotho sa Leboa";                                        "nso-ZA" = "Sesotho sa Leboa (South Africa)";                                                                                                                                            
    "nus" = "Nuer";                                               "nus-SS" = "Nuer (South Sudan)";                                   "nyn" = "Nyankole";                                                                                                                                            
    "nyn-UG" = "Nyankole (Uganda)";                               "oc" = "Occitan";                                                  "oc-FR" = "Occitan (France)";                                                                                                                                            
    "om" = "Oromo";                                               "om-ET" = "Oromo (Ethiopia)";                                      "om-KE" = "Oromo (Kenya)";                                                                                                                                            
    "or" = "Odia";                                                "or-IN" = "Odia (India)";                                          "os" = "Ossetic";                                                                                                                                            
    "os-GE" = "Ossetian (Cyrillic, Georgia)";                     "os-RU" = "Ossetian (Cyrillic, Russia)";                           "pa" = "Punjabi";                                                                                                                                            
    "pa-Arab" = "Punjabi (Arabic)";                               "pa-Arab-PK" = "Punjabi (Islamic Republic of Pakistan)";           "pa-IN" = "Punjabi (India)";                                                                                                                                            
    "pap" = "Papiamento";                                         "pap-029" = "Papiamento (Caribbean)";                              "pl" = "Polish";                                                                                                                                            
    "pl-PL" = "Polish (Poland)";                                  "prg" = "Prussian";                                                "prg-001" = "Prussian (World)";                                                                                                                                            
    "prs" = "Dari";                                               "prs-AF" = "Dari (Afghanistan)";                                   "ps" = "Pashto";                                                                                                                                            
    "ps-AF" = "Pashto (Afghanistan)";                             "pt" = "Portuguese";                                               "pt-AO" = "Portuguese (Angola)";                                                                                                                                            
    "pt-BR" = "Portuguese (Brazil)";                              "pt-CH" = "Portuguese (Switzerland)";                              "pt-CV" = "Portuguese (Cabo Verde)";                                                                                                                                            
    "pt-GQ" = "Portuguese (Equatorial Guinea)";                   "pt-GW" = "Portuguese (Guinea-Bissau)";                            "pt-LU" = "Portuguese (Luxembourg)";                                                                                                                                            
    "pt-MO" = "Portuguese (Macao SAR)";                           "pt-MZ" = "Portuguese (Mozambique)";                               "pt-PT" = "Portuguese (Portugal)";                                                                                                                                            
    "pt-ST" = "Portuguese (São Tomé and Príncipe)";               "pt-TL" = "Portuguese (Timor-Leste)";                              "quc" = "K'iche'";                                                                                                                                            
    "quc-Latn" = "K'iche'";                                       "quc-Latn-GT" = "K'iche' (Guatemala)";                             "quz" = "Quechua";                                                                                                                                            
    "quz-BO" = "Quechua (Bolivia)";                               "quz-EC" = "Quechua (Ecuador)";                                    "quz-PE" = "Quechua (Peru)";                                                                                                                                            
    "rm" = "Romansh";                                             "rm-CH" = "Romansh (Switzerland)";                                 "rn" = "Rundi";                                                                                                                                            
    "rn-BI" = "Rundi (Burundi)";                                  "ro" = "Romanian";                                                 "ro-MD" = "Romanian (Moldova)";                                                                                                                                            
    "ro-RO" = "Romanian (Romania)";                               "rof" = "Rombo";                                                   "rof-TZ" = "Rombo (Tanzania)";                                                                                                                                            
    "ru" = "Russian";                                             "ru-BY" = "Russian (Belarus)";                                     "ru-KG" = "Russian (Kyrgyzstan)";                                                                                                                                            
    "ru-KZ" = "Russian (Kazakhstan)";                             "ru-MD" = "Russian (Moldova)";                                     "ru-RU" = "Russian (Russia)";                                                                                                                                            
    "ru-UA" = "Russian (Ukraine)";                                "rw" = "Kinyarwanda";                                              "rw-RW" = "Kinyarwanda (Rwanda)";                                                                                                                                            
    "rwk" = "Rwa";                                                "rwk-TZ" = "Rwa (Tanzania)";                                       "sa" = "Sanskrit";                                                                                                                                            
    "sa-IN" = "Sanskrit (India)";                                 "sah" = "Sakha";                                                   "sah-RU" = "Sakha (Russia)";                                                                                                                                            
    "saq" = "Samburu";                                            "saq-KE" = "Samburu (Kenya)";                                      "sbp" = "Sangu";                                                                                                                                            
    "sbp-TZ" = "Sangu (Tanzania)";                                "sd" = "Sindhi";                                                   "sd-Arab" = "Sindhi (Arabic)";                                                                                                                                            
    "sd-Arab-PK" = "Sindhi (Islamic Republic of Pakistan)";       "sd-Deva" = "Sindhi (Devanagari)";                                 "sd-Deva-IN" = "Sindhi (Devanagari, India)";                                                                                                                                            
    "se" = "Sami (Northern)";                                     "se-FI" = "Sami, Northern (Finland)";                              "se-NO" = "Sami, Northern (Norway)";                                                                                                                                            
    "se-SE" = "Sami, Northern (Sweden)";                          "seh" = "Sena";                                                    "seh-MZ" = "Sena (Mozambique)";                                                                                                                                            
    "ses" = "Koyraboro Senni";                                    "ses-ML" = "Koyraboro Senni (Mali)";                               "sg" = "Sango";                                                                                                                                            
    "sg-CF" = "Sango (Central African Republic)";                 "shi" = "Tachelhit";                                               "shi-Latn" = "Tachelhit (Latin)";                                                                                                                                            
    "shi-Latn-MA" = "Tachelhit (Latin, Morocco)";                 "shi-Tfng" = "Tachelhit (Tifinagh)";                               "shi-Tfng-MA" = "Tachelhit (Tifinagh, Morocco)";                                                                                                                                            
    "si" = "Sinhala";                                             "si-LK" = "Sinhala (Sri Lanka)";                                   "sk" = "Slovak";                                                                                                                                            
    "sk-SK" = "Slovak (Slovakia)";                                "sl" = "Slovenian";                                                "sl-SI" = "Slovenian (Slovenia)";                                                                                                                                            
    "sma" = "Sami (Southern)";                                    "sma-NO" = "Sami, Southern (Norway)";                              "sma-SE" = "Sami, Southern (Sweden)";                                                                                                                                            
    "smj" = "Sami (Lule)";                                        "smj-NO" = "Sami, Lule (Norway)";                                  "smj-SE" = "Sami, Lule (Sweden)";                                                                                                                                            
    "smn" = "Sami (Inari)";                                       "smn-FI" = "Sami, Inari (Finland)";                                "sms" = "Sami (Skolt)";                                                                                                                                            
    "sms-FI" = "Sami, Skolt (Finland)";                           "sn" = "Shona";                                                    "sn-Latn" = "Shona (Latin)";                                                                                                                                            
    "sn-Latn-ZW" = "Shona (Latin, Zimbabwe)";                     "so" = "Somali";                                                   "so-DJ" = "Somali (Djibouti)";                                                                                                                                            
    "so-ET" = "Somali (Ethiopia)";                                "so-KE" = "Somali (Kenya)";                                        "so-SO" = "Somali (Somalia)";                                                                                                                                            
    "sq" = "Albanian";                                            "sq-AL" = "Albanian (Albania)";                                    "sq-MK" = "Albanian (Macedonia, FYRO)";                                                                                                                                            
    "sq-XK" = "Albanian (Kosovo)";                                "sr" = "Serbian";                                                  "sr-Cyrl" = "Serbian (Cyrillic)";                                                                                                                                            
    "sr-Cyrl-BA" = "Serbian (Cyrillic, Bosnia and Herzegovina)";  "sr-Cyrl-ME" = "Serbian (Cyrillic, Montenegro)";                   "sr-Cyrl-RS" = "Serbian (Cyrillic, Serbia)";                                                                                                                                            
    "sr-Cyrl-XK" = "Serbian (Cyrillic, Kosovo)";                  "sr-Latn" = "Serbian (Latin)";                                     "sr-Latn-BA" = "Serbian (Latin, Bosnia and Herzegovina)";                                                                                                                                            
    "sr-Latn-ME" = "Serbian (Latin, Montenegro)";                 "sr-Latn-RS" = "Serbian (Latin, Serbia)";                          "sr-Latn-XK" = "Serbian (Latin, Kosovo)";                                                                                                                                            
    "ss" = "Swati";                                               "ss-SZ" = "Swati (Eswatini former Swaziland)";                     "ss-ZA" = "Swati (South Africa)";                                                                                                                                            
    "ssy" = "Saho";                                               "ssy-ER" = "Saho (Eritrea)";                                       "st" = "Southern Sotho";                                                                                                                                            
    "st-LS" = "Sesotho (Lesotho)";                                "st-ZA" = "Southern Sotho (South Africa)";                         "sv" = "Swedish";                                                                                                                                            
    "sv-AX" = "Swedish (Åland Islands)";                          "sv-FI" = "Swedish (Finland)";                                     "sv-SE" = "Swedish (Sweden)";                                                                                                                                            
    "sw" = "Kiswahili";                                           "sw-CD" = "Kiswahili (Congo DRC)";                                 "sw-KE" = "Kiswahili (Kenya)";                                                                                                                                            
    "sw-TZ" = "Kiswahili (Tanzania)";                             "sw-UG" = "Kiswahili (Uganda)";                                    "syr" = "Syriac";                                                                                                                                            
    "syr-SY" = "Syriac (Syria)";                                  "ta" = "Tamil";                                                    "ta-IN" = "Tamil (India)";                                                                                                                                            
    "ta-LK" = "Tamil (Sri Lanka)";                                "ta-MY" = "Tamil (Malaysia)";                                      "ta-SG" = "Tamil (Singapore)";                                                                                                                                            
    "te" = "Telugu";                                              "te-IN" = "Telugu (India)";                                        "teo" = "Teso";                                                                                                                                            
    "teo-KE" = "Teso (Kenya)";                                    "teo-UG" = "Teso (Uganda)";                                        "tg" = "Tajik";                                                                                                                                            
    "tg-Cyrl" = "Tajik (Cyrillic)";                               "tg-Cyrl-TJ" = "Tajik (Cyrillic, Tajikistan)";                     "th" = "Thai";                                                                                                                                            
    "th-TH" = "Thai (Thailand)";                                  "ti" = "Tigrinya";                                                 "ti-ER" = "Tigrinya (Eritrea)";                                                                                                                                            
    "ti-ET" = "Tigrinya (Ethiopia)";                              "tig" = "Tigre";                                                   "tig-ER" = "Tigre (Eritrea)";                                                                                                                                            
    "tk" = "Turkmen";                                             "tk-TM" = "Turkmen (Turkmenistan)";                                "tn" = "Setswana";                                                                                                                                            
    "tn-BW" = "Setswana (Botswana)";                              "tn-ZA" = "Setswana (South Africa)";                               "to" = "Tongan";                                                                                                                                            
    "to-TO" = "Tongan (Tonga)";                                   "tr" = "Turkish";                                                  "tr-CY" = "Turkish (Cyprus)";                                                                                                                                            
    "tr-TR" = "Turkish (Turkey)";                                 "ts" = "Tsonga";                                                   "ts-ZA" = "Tsonga (South Africa)";                                                                                                                                            
    "tt" = "Tatar";                                               "tt-RU" = "Tatar (Russia)";                                        "twq" = "Tasawaq";                                                                                                                                            
    "twq-NE" = "Tasawaq (Niger)";                                 "tzm" = "Tamazight";                                               "tzm-Arab" = "Central Atlas Tamazight (Arabic)";                                                                                                                                            
    "tzm-Arab-MA" = "Central Atlas Tamazight (Arabic, Morocco)";  "tzm-Latn" = "Tamazight (Latin)";                                  "tzm-Latn-DZ" = "Tamazight (Latin, Algeria)";                                                                                                                                            
    "tzm-Latn-MA" = "Central Atlas Tamazight (Latin, Morocco)";   "tzm-Tfng" = "Tamazight (Tifinagh)";                               "tzm-Tfng-MA" = "Central Atlas Tamazight (Tifinagh, Morocco)";                                                                                                                                            
    "ug" = "Uyghur";                                              "ug-CN" = "Uyghur (PRC)";                                          "uk" = "Ukrainian";                                                                                                                                            
    "uk-UA" = "Ukrainian (Ukraine)";                              "ur" = "Urdu";                                                     "ur-IN" = "Urdu (India)";                                                                                                                                            
    "ur-PK" = "Urdu (Islamic Republic of Pakistan)";              "uz" = "Uzbek";                                                    "uz-Arab" = "Uzbek (Perso-Arabic)";                                                                                                                                            
    "uz-Arab-AF" = "Uzbek (Perso-Arabic, Afghanistan)";           "uz-Cyrl" = "Uzbek (Cyrillic)";                                    "uz-Cyrl-UZ" = "Uzbek (Cyrillic, Uzbekistan)";                                                                                                                                            
    "uz-Latn" = "Uzbek (Latin)";                                  "uz-Latn-UZ" = "Uzbek (Latin, Uzbekistan)";                        "vai" = "Vai";                                                                                                                                            
    "vai-Latn" = "Vai (Latin)";                                   "vai-Latn-LR" = "Vai (Latin, Liberia)";                            "vai-Vaii" = "Vai (Vai)";                                                                                                                                            
    "vai-Vaii-LR" = "Vai (Vai, Liberia)";                         "ve" = "Venda";                                                    "ve-ZA" = "Venda (South Africa)";                                                                                                                                            
    "vi" = "Vietnamese";                                          "vi-VN" = "Vietnamese (Vietnam)";                                  "vo" = "Volapük";                                                                                                                                            
    "vo-001" = "Volapük (World)";                                 "vun" = "Vunjo";                                                   "vun-TZ" = "Vunjo (Tanzania)";                                                                                                                                            
    "wae" = "Walser";                                             "wae-CH" = "Walser (Switzerland)";                                 "wal" = "Wolaytta";                                                                                                                                            
    "wal-ET" = "Wolaytta (Ethiopia)";                             "wo" = "Wolof";                                                    "wo-SN" = "Wolof (Senegal)";                                                                                                                                            
    "xh" = "isiXhosa";                                            "xh-ZA" = "isiXhosa (South Africa)";                               "xog" = "Soga";                                                                                                                                            
    "xog-UG" = "Soga (Uganda)";                                   "yav" = "Yangben";                                                 "yav-CM" = "Yangben (Cameroon)";                                                                                                                                            
    "yi" = "Yiddish";                                             "yi-001" = "Yiddish (World)";                                      "yo" = "Yoruba";                                                                                                                                            
    "yo-BJ" = "Yoruba (Benin)";                                   "yo-NG" = "Yoruba (Nigeria)";                                      "zgh" = "Standard Moroccan Tamazight";                                                                                                                                            
    "zgh-Tfng" = "Standard Moroccan Tamazight (Tifinagh)";        "zgh-Tfng-MA" = "Standard Moroccan Tamazight (Tifinagh, Morocco)"; "zh" = "Chinese";                                                                                                                                            
    "zh-CN" = "Chinese (Simplified, PRC)";                        "zh-Hans" = "Chinese (Simplified)";                                "zh-Hans-HK" = "Chinese (Simplified Han, Hong Kong SAR)";                                                                                                                                            
    "zh-Hans-MO" = "Chinese (Simplified Han, Macao SAR)";         "zh-Hant" = "Chinese (Traditional)";                               "zh-HK" = "Chinese (Traditional, Hong Kong S.A.R.)";                                                                                                                                            
    "zh-MO" = "Chinese (Traditional, Macao S.A.R.)";              "zh-SG" = "Chinese (Simplified, Singapore)";                       "zh-TW" = "Chinese (Traditional, Taiwan)";                                                                                                                                            
    "zu" = "isiZulu";                                             "zu-ZA" = "isiZulu (South Africa)"
}

function info_locale {
    # Get the current user's language and region using the registry
    $Region = $localeLookup[(Get-ItemProperty -Path "HKCU:Control Panel\International\Geo").Nation]
    # Iterate through registry key in case multiple languages are configured
    (Get-ItemProperty -Path "HKCU:Control Panel\International\User Profile").Languages | ForEach-Object {
        $Languages += " - $($languageLookup[$_])"
    }

    return @{
        title   = "Locale"
        content = "$Region$Languages"
    }
}

function info_region {
    $Region = $localeLookup[(Get-ItemProperty -Path "HKCU:Control Panel\International\Geo").Nation]
    return @{
        title   = "Locale"
        content = "$Region"
    }
}

# Retrieve the primary language (first language configured)
function info_language {
    $PrimaryLanguage = (Get-ItemProperty -Path "HKCU:Control Panel\International\User Profile").Languages[0]
    return @{
        title   = "Language"
        content = "$languageLookup[$PrimaryLanguage]"
    }
}

# ===== WEATHER =====
function info_weather {
    $currentTempC = $weatherInfoParts[1].TrimStart("+")
    $weatherCondition = ($weatherInfoParts[7..($weatherInfoParts.Length - 1)] -join " ").Trim()
    $feelsLikeTempC = $weatherInfoParts[2].TrimStart("+")
    $wind = $weatherInfoParts[4].Trim()

    # Check if any of the components contain "Network Error"
    if ($currentTempC -like "*Network Error*" -or
        $weatherCondition -like "*Network Error*" -or
        $feelsLikeTempC -like "*Network Error*" -or
        $wind -like "*Network Error*") {
        return @{
            title   = "Weather"
            content = "Network Error"
        }
    }

    return @{
        title   = "Weather"
        content = "$currentTempC - $weatherCondition (Feels Like: $feelsLikeTempC) $wind"
    }
}



function info_weather_condition {
    $weatherCondition = ($weatherInfoParts[7..($weatherInfoParts.Length - 1)] -join " ").Trim()
    if ($weatherCondition -like "*Network Error*") {
        $weatherCondition = "Network Error"
    }
    return @{
        title   = "Weather"
        content = $weatherCondition
    }
}

function info_humidity {
    $humidity = $weatherInfoParts[3]
    return @{
        title   = "Humidity"
        content = "$humidity"
    }
}

function info_sun { 
    $sunrise = $weatherInfoParts[5]
    $sunset = $weatherInfoParts[6]

    if ($sunrise -eq "Network Error" -or $sunset -eq "Network Error") {
        return @{
            title   = "Sunrise"
            content = "Network Error"
        }
    }
    
    $today = Get-Date -Format "yyyy-MM-dd"
    
    $sunriseDateTime = [DateTime]::ParseExact("$today $sunrise", "yyyy-MM-dd HH:mm:ss", $null)
    $sunsetDateTime = [DateTime]::ParseExact("$today $sunset", "yyyy-MM-dd HH:mm:ss", $null)
    $currentTime = Get-Date
    
    # Determine whether it's daytime or nighttime
    if ($currentTime -ge $sunriseDateTime -and $currentTime -lt $sunsetDateTime) {
        # Daytime: Show sunset time
        $timeToShow = $sunsetDateTime.ToString("hh:mm tt")
        $timeLabel = "Sunset"
    }
    else {
        # Nighttime: Show sunrise time
        $timeToShow = $sunriseDateTime.ToString("hh:mm tt")
        $timeLabel = "Sunrise"
    }

    return @{
        title   = $timeLabel
        content = "$timeToShow"
    }
}

function info_temp_celcius {
    $currentTempC = $weatherInfoParts[1]
    return @{
        title   = "Temperature"
        content = "$currentTempC"
    }
}

function info_temp_farenheit {
    $currentTempC = $weatherInfoParts[1]
    if ($currentTempC -ne "Network Error") {
        $currentTempF = "{0:N1}" -f (([double]($currentTempC -replace '[^0-9.-]') * 9 / 5) + 32)
    }
    return @{
        title   = "Temperature"
        content = "$currentTempF°F"
    }
}

function info_wind {
    $wind = $weatherInfoParts[4]
    return @{
        title   = "Wind"
        content = $wind
    }
}

function info_feels_like_celcius {
    $feelsLikeTempC = $weatherInfoParts[2]
    return @{
        title   = "Feels Like"
        content = $feelsLikeTempC
    }
}

function info_feels_like_farenheit {
    $feelsLikeTempC = $weatherInfoParts[2]
    if ($feelsLikeTempC -ne "Network Error") {
        $feelsLikeTempF = "{0:N1}" -f (([double]($feelsLikeTempC -replace '[^0-9.-]') * 9 / 5) + 32)
    }
    return @{
        title   = "Feels Like"
        content = "$feelsLikeTempF°F"
    }
}

# ===== IP =====
function info_local_ip {
    try {
        # Get all network adapters
        foreach ($ni in [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()) {
            # Get the IP information of each adapter
            $properties = $ni.GetIPProperties()
            # Check if the adapter is online, has a gateway address, and the adapter does not have a loopback address
            if ($ni.OperationalStatus -eq 'Up' -and !($null -eq $properties.GatewayAddresses[0]) -and !$properties.GatewayAddresses[0].Address.ToString().Equals("0.0.0.0")) {
                # Check if adapter is a WiFi or Ethernet adapter
                if ($ni.NetworkInterfaceType -eq "Wireless80211" -or $ni.NetworkInterfaceType -eq "Ethernet") {
                    foreach ($ip in $properties.UnicastAddresses) {
                        if ($ip.Address.AddressFamily -eq "InterNetwork") {
                            if (!$local_ip) { $local_ip = $ip.Address.ToString() }
                        }
                    }
                }
            }
        }
    }
    catch {
    }
    return @{
        title   = "Local IP"
        content = if (-not $local_ip) {
            "$e[91m(Unknown)"
        }
        else {
            $local_ip
        }
    }
}

function info_public_ip {
    return @{
        title   = "Public IP"
        content = try {
            Invoke-RestMethod -TimeoutSec 5 ifconfig.me/ip
        }
        catch {
            "$e[91m(Network Error)"
        }
    }
}

function info_gradient {
    if ($stripansi) {
        return
        @{
            title   = ""
            content = ""
        }
    }
    $e = [char]27
    $topColors = @(167, 173, 179, 185, 149, 113, 77, 80, 74, 68, 62, 98, 134, 170, 169, 168)
    $bottomColors = @(160, 202, 214, 226, 154, 82, 47, 51, 39, 33, 57, 93, 129, 165, 201, 199)

    $topContent = ($topColors | ForEach-Object {
            "{0}[0;48;5;{1}m{2}" -f $e, $_, '  '
        }) -join ''

    $bottomContent = ($bottomColors | ForEach-Object {
            "{0}[0;48;5;{1}m{2}" -f $e, $_, '  '
        }) -join ''
    return @(
        @{
            title   = ""
            content = "$e[1;33m$($topContent)$e[0m"
        },
        @{
            title   = ""
            content = "$e[1;33m$($bottomContent)$e[0m"
        }
    ) 
}

function info_colorbar {
    # If stripansi, avoid showing the empty space taken up by colorbar
    if ($stripansi) {
        return
        @{
            title   = ""
            content = ""
        }
    }
    return @(
        @{
            title   = ""
            content = ('{0}[0;40m{1}{0}[0;41m{1}{0}[0;42m{1}{0}[0;43m{1}{0}[0;44m{1}{0}[0;45m{1}{0}[0;46m{1}{0}[0;47m{1}{0}[0m') -f $e, '   '
        },
        @{
            title   = ""
            content = ('{0}[0;100m{1}{0}[0;101m{1}{0}[0;102m{1}{0}[0;103m{1}{0}[0;104m{1}{0}[0;105m{1}{0}[0;106m{1}{0}[0;107m{1}{0}[0m') -f $e, '   '
        }
    )
}

function info_colorbar_center {
    info_colorbar
}

function info_gradient_center {
    info_gradient
}

# Center the logo when bottom_max_length > logo_max_length
function pad_line_center {
    param (
        [string]$line,
        [int]$targetLength
    )
    $plain_line = $line -replace $ansiRegex, ""
    $line_length = $plain_line.Length
    $padding_needed = $targetLength - $line_length
    if ($padding_needed -le 0) { return $line }

    $left_padding = " " * [Math]::Floor($padding_needed / 2)
    return "$left_padding$line"
}

# Determine the longest line in the logo
$logo_max_length = 0
if ($img) {
    for ($i = 0; $i -lt $img.Count; $i++) {
        $plain_line = $img[$i] -replace $ansiRegex, ""
        if ($plain_line.Length -gt $logo_max_length) {
            $logo_max_length = $plain_line.Length
        }
        $img[$i] = " $($img[$i])" # Add space to the left
    }
}

# ===== Text + Bar Alignment Helper Functions =====
function CalculateTextLengths {
    param (
        [array]$Lines,
        [string]$Pattern
    )

    $textLengths = foreach ($line in $Lines) {
        $cleanContent = $line.Content -replace $ansiRegex, ""
        if ($cleanContent -match $Pattern) {
            $matches[1].Length
        }
        else {
            $cleanContent.Length
        }
    }
    return $textLengths
}

function AlignLineContent {
    param (
        [string]$OriginalContent,
        [string]$Pattern,
        [int]$MaxTextLength,
        [bool]$IsTextbar,
        [int]$GroupCount
    )

    $cleanContent = $OriginalContent -replace $ansiRegex, ""

    if ($cleanContent -match $Pattern) {
        $textPart = $matches[1]

        if ($IsTextbar) {
            $spacesToAdd = $GroupCount -gt 1 ? $MaxTextLength + 1 - $textPart.Length : $MaxTextLength - $textPart.Length
        }
        else {
            $spacesToAdd = $MaxTextLength - $textPart.Length
        }

        $spacing = ' ' * $spacesToAdd

        # Find insert position preserving ANSI codes
        $insertPosition = 0
        $visibleChars = 0

        while ($visibleChars -lt $matches[1].Length -and $insertPosition -lt $OriginalContent.Length) {
            if ($OriginalContent[$insertPosition] -eq "`e") {
                # Skip ANSI codes
                $ansiEnd = $OriginalContent.IndexOf("m", $insertPosition)
                if ($ansiEnd -ge 0) {
                    $insertPosition = $ansiEnd + 1
                }
                else {
                    break
                }
            }
            else {
                $insertPosition += 1
                $visibleChars += 1
            }
        }

        # Insert spacing
        return $OriginalContent.Insert($insertPosition, $spacing)
    }
    else {
        return $OriginalContent
    }
}

# Used when only config_left
function AlignAndOutputLines {
    param (
        [array]$Lines,
        [string]$Pattern,
        [switch]$IsTextbar
    )

    # Calculate text lengths
    $textLengths = CalculateTextLengths -Lines $Lines -Pattern $Pattern
    $maxTextLength = ($textLengths | Measure-Object -Maximum).Maximum

    # Iterate through each line to align
    foreach ($line in $Lines) {
        $newContent = AlignLineContent -OriginalContent $line.Content -Pattern $Pattern -MaxTextLength $maxTextLength -IsTextbar $IsTextbar -GroupCount $Lines.Count

        if ($stripansi) {
            $output = $newContent -replace $ansiRegex, ""
            if ($output.Length -gt $freeSpace) {
                $output = $output.Substring(0, $freeSpace)
            }
        }
        else {
            $output = truncate_line $newContent $freeSpace
        }

        Write-Output $output
    }
}

# Used in ProcessConfigItems
function AlignLinesInGroup {
    param (
        [array]$Group,
        [string]$Pattern,
        [bool]$IsTextbar
    )

    $textLengths = CalculateTextLengths -Lines $Group -Pattern $Pattern
    $maxTextLength = ($textLengths | Measure-Object -Maximum).Maximum
    foreach ($line in $Group) {
        $line.Content = AlignLineContent -OriginalContent $line.Content -Pattern $Pattern -MaxTextLength $maxTextLength -IsTextbar $IsTextbar -GroupCount $Group.Count
    }
}

function ProcessHeaderItems {
    param (
        [array]$headerItems,
        [ref]$outputLines,
        [ref]$maxLength,
        [hashtable]$colorMap = @{}
    )

    # Default color to apply to all elements
    $defaultColor = Get-AnsiCode -colorInput "white"

    foreach ($itemArray in $headerItems) {
        $lineContents = @()
        foreach ($item in $itemArray) {
            $functionToCall = "info_$item"

            if (Get-Command -Name $functionToCall -ErrorAction SilentlyContinue) {
                $info = & $functionToCall
            }
            else {
                $info = @{ content = "`e[31mFunction '$functionToCall' not found`e[0m" }
            }

            if ($info -is [array]) {
                # If the info is an array, take the first element
                $info = $info[0]
            }

            if ($info["content"]) {
                $content = $info["content"]
                # Determine the color for this item
                $color = if ($colorMap.ContainsKey($item)) { Get-AnsiCode -colorInput $colorMap[$item] } else { $defaultColor }
                if ($color) {
                    $content = "${ansiReset}`e[${color}m$content`e[0m"
                }
            }
            else {
                $content = ""
            }
            
            $lineContents += $content
        }

        $lineContent = $lineContents -join " "

        # Remove ANSI codes to compute plain line length
        $plain_line = $lineContent -replace $ansiRegex, ""
        if ($plain_line.Length -gt $maxLength.Value) {
            $maxLength.Value = $plain_line.Length
        }

        # Append the processed line to output
        $outputLines.Value += $lineContent
    }

    # Remove any trailing empty lines
    if ($outputLines.Value[-1] -eq "") {
        $outputLines.Value = $outputLines.Value[0..($outputLines.Value.Count - 2)]
    }
}

$isRightColumn = $false
$isBottomSection = $false

function ColorOutput {
    param (
        [string]$Title,
        [string]$Content,
        [string]$ColorKey,
        [string]$ColorValue
    )

    # Detect if line["content"] has altbar + text
    # If found, determine the starting index of the text after bar and apply color codes from that position onward.
    $pattern = '^(▇+)\s*(.+)$'
    $ansiPattern = "`e\[[0-9;]*m"

    # Construct colored title if it exists
    $coloredTitle = if ($Title) {
        "`e[1;${ColorKey}m${Title}"
    }
    else {
        ""
    }

    # Construct colored content if it exists
    $coloredContent = if ($Content) {
        $modContent = $Content -replace $ansiPattern, ""

        if ($modContent -match $pattern) {
            $bar = $matches[1]
            $text = $matches[2]

            # Initialize counters to find the insertion point in the original content
            $originalIndex = 0
            $cleanIndex = 0

            # Find the position in originalContent after the bar
            while ($cleanIndex -lt $bar.Length -and $originalIndex -lt $Content.Length) {
                if ($Content[$originalIndex] -eq "`e") {
                    # Detected start of ANSI code
                    $ansiEnd = $Content.IndexOf("m", $originalIndex)
                    if ($ansiEnd -ge 0) {
                        # Skip the entire ANSI code
                        $originalIndex = $ansiEnd + 1
                    }
                    else {
                        # Malformed ANSI code, break
                        break
                    }
                }
                else {
                    # Regular character
                    $originalIndex += 1
                    $cleanIndex += 1
                }
            }

            # Prepare the color codes
            $colorStart = "`e[1;${ColorValue}m"
            $colorEnd = "`e[0m"

            $spaceIndex = $originalIndex
            while ($spaceIndex -lt $Content.Length -and $Content[$spaceIndex] -eq ' ') {
                $spaceIndex += 1
            }

            # Insert the color start code before the text
            $newContent = $Content.Insert($spaceIndex, $colorStart)

            # Insert the reset code after the text
            $textEndIndex = $spaceIndex + $colorStart.Length + $text.Length
            $newContent = $newContent.Insert($textEndIndex, $colorEnd)

            # Assign the modified content
            $newContent
        }
        else {
            # If pattern does not match, apply color to the entire content
            "`e[1;${ColorValue}m${Content}`e[0m"
        }
    }
    else {
        ""
    }

    # Combine the parts based on their existence
    if ($coloredTitle -and $coloredContent) {
        "${ansiReset}${coloredTitle}: ${coloredContent}"
    }
    elseif ($coloredTitle) {
        "$coloredTitle"
    }
    else {
        "$coloredContent"
    }
}

function ProcessConfigItems {
    param (
        [array]$configItems,
        [ref]$outputLines,
        [ref]$maxLength
    )

    switch ($true) {
        $isBottomSection { 
            $colorKey = Get-AnsiCode -colorInput $colorBottomKey
            $colorValue = Get-AnsiCode -colorInput $colorBottomValue
            break
        }
        $isRightColumn { 
            $colorKey = Get-AnsiCode -colorInput $colorRightKey
            $colorValue = Get-AnsiCode -colorInput $colorRightValue
            break
        }
        default {
            $colorKey = Get-AnsiCode -colorInput $colorLeftKey
            $colorValue = Get-AnsiCode -colorInput $colorLeftValue
        }
    }

    # Pre-fetch all available info_* functions
    $availableInfoFunctions = @{}
    Get-Command info_* -CommandType Function -ErrorAction SilentlyContinue | ForEach-Object {
        $availableInfoFunctions[$_.Name] = $_
    }

    # Initialize a list to store deferred items (colorbar and colorbar_center)
    # colorbar_center should be deferred until the maximum length of the section is determined.
    # To find the maximum length, all elements need to be processed first.
    $deferredItems = @()
    $lineIndex = 0
    $ansiPattern = "\e\[[0-9;]*m" 

    foreach ($item in $configItems) {
        # Determine if the item has the 'general_' prefix
        $isGeneralItem = $false
        if ($item.StartsWith('general_')) {
            $isGeneralItem = $true
            $itemName = $item.Substring(8)  # Remove 'general_' prefix
            $functionToCall = "info_$itemName"
            if (-not [string]::IsNullOrWhiteSpace($colorGeneralKey)) {
                $currentColorKey = Get-AnsiCode -colorInput $colorGeneralKey
            }
            else {
                $currentColorKey = $colorKey
            }

            if (-not [string]::IsNullOrWhiteSpace($colorGeneralValue)) {
                $currentColorValue = Get-AnsiCode -colorInput $colorGeneralValue
            }
            else {
                $currentColorValue = $colorValue
            }
        }
        else {
            $functionToCall = "info_$item"
            $currentColorKey = $colorKey
            $currentColorValue = $colorValue
        }

        # Retrieve the corresponding info function if it exists, else create an error message
        if ($availableInfoFunctions.ContainsKey($functionToCall)) {
            $info = & $functionToCall
        }
        else {
            $info = @{ title = "`e[31mFunction '$functionToCall' not found" }
        }

        # Skip processing if $info is null or empty
        if (-not $info) {
            $lineIndex++
            continue
        }

        if ($info -isnot [array]) {
            $info = @($info)
        }

        # Process each line in the info object
        foreach ($line in $info) {
            if ($item -in @("colorbar_center", "colorbar", "gradient", "gradient_center")) {
                # Defer processing for colorbar items
                $deferredItems += [PSCustomObject]@{
                    LineIndex       = $lineIndex
                    LineData        = $line
                    IsBottomSection = $isBottomSection
                    ConfigItem      = $item
                    IsGeneralItem   = $isGeneralItem
                }
                # Placeholder in outputLines
                $outputLines.Value += $null
            }
            else {
                # Apply ANSI colors to title and content
                $title = $line["title"]
                $content = $line["content"]

                $output = ColorOutput -Title $title -Content $content -ColorKey $currentColorKey -ColorValue $currentColorValue

                # Calculate the plain text length by removing ANSI codes
                $plainOutputLength = ($output -replace $ansiPattern, "").Length

                # Update maxLength if necessary (excluding general items)
                if (-not $isGeneralItem -and $plainOutputLength -gt $maxLength.Value) {
                    $maxLength.Value = $plainOutputLength
                }

                # Append the processed line to outputLines
                $outputLines.Value += [PSCustomObject]@{
                    Content       = $output
                    ConfigItem    = $item
                    IsGeneralItem = $isGeneralItem
                }
            }
            $lineIndex++
        }
    }

    # Detects groups of text + bar or bar + text based on the pattern passed in
    function DetectPatternGroups {
        param (
            [array]$Lines,
            [string]$Pattern
        )
    
        $groups = @()
        $currentGroup = @()
        $AnsiPattern = "\e\[[0-9;]*m"
    
        foreach ($line in $Lines) {
            $cleanContent = $line.Content -replace $AnsiPattern, ""
            # If content matches pattern, add to current group
            if ($cleanContent -match $Pattern) {
                $currentGroup += $line
            }
            else {
                # End of matching implies one group has ended, and so add currentGroup to groups
                # Reset currentGroup and and gt -0 condition to prevent unmatched patterns being added to currentGroup
                if ($currentGroup.Count -gt 0) {
                    $groups += , @($currentGroup)
                    $currentGroup = @()
                }
            }
        }
        # In case a section only contains of bars
        if ($currentGroup.Count -gt 0) {
            $groups += , @($currentGroup)
        }
        # Append @(), because otherwise, if a section has only one group with 3 bars, it will be interpreted
        # as 3 groups, each with one bar
        $groups += , @()
        return $groups
    }

    $ansiPattern = "\e\[[0-9;]*m"

    # Detect and align bartext groups
    $bartextPattern = '^(.*?)(▇+|\[[\s■\-]+\])\s+(.+)$'
    $bartextGroups = DetectPatternGroups -Lines $outputLines.Value -Pattern $bartextPattern
    foreach ($group in $bartextGroups) {
        AlignLinesInGroup -Group $group -Pattern $bartextPattern -IsTextbar:$false
    }

    # Detect and align textbar groups
    $textbarPattern = '^(?!\s*$).+(?:▇+$|\[[\s■\-]+\])$'
    $textbarGroups = DetectPatternGroups -Lines $outputLines.Value -Pattern $textbarPattern
    $textbarPattern = '^(.*?)(▇+|\[[\s■\-]+\])$'
    foreach ($group in $textbarGroups) {
        AlignLinesInGroup -Group $group -Pattern $textbarPattern -IsTextbar:$true
    }

    # Process deferred colorbar and colorbar_center items
    foreach ($deferredItem in $deferredItems) {
        $line = $deferredItem.LineData
        $index = $deferredItem.LineIndex
        $item = $deferredItem.ConfigItem
        $isGeneralItem = $deferredItem.IsGeneralItem

        $outputLine = $line["content"]

        # Determine target length for centering
        if ($deferredItem.IsBottomSection) {
            $targetLength = [Math]::Max($maxLength.Value, $logo_max_length)
        }
        else {
            $targetLength = $maxLength.Value
        }

        # Center the output line using the pad_line_center function
        $centeredLine = pad_line_center $outputLine $targetLength
        # Create the output object
        $outputObject = [PSCustomObject]@{
            Content       = $centeredLine
            ConfigItem    = $item
            IsGeneralItem = $isGeneralItem
        }

        # Insert the centered line into outputLines at the correct index
        $outputLines.Value[$index] = $outputObject
    }
}

# Returns true if config has items other than 'blank'
function check_non_blank {
    param (
        [string[]]$ConfigArray
    )
    $elements = @('blank', 'colorbar', 'colorbar_center', 'gradient', 'gradient_bar_center')
    
    if ($stripansi) {
        foreach ($item in $ConfigArray) {
            if (-not $($elements -contains $item.Trim().ToLower())) {
                return $true
            }
        }
    }
    else {
        foreach ($item in $ConfigArray) {
            if ($item.Trim().ToLower() -ne 'blank') {
                return $true
            }
        }
    }
    return $false
}

# ===== COLLECT WEATHER DATA =====
$all_config = ($config_left + $config_right + $config_bottom | Select-Object -Unique)
$weather_functions = @(
    "weather",
    "humidity",
    "sun",
    "temp_celcius",
    "temp_farenheit",
    "wind",
    "feels_like_celcius",
    "feels_like_farenheit"
)

function get_weather_data {
    $url = "http://wttr.in?format=%c+%t+%f+%h+%w+%S+%s+%C&m"
    try {
        $response = Invoke-RestMethod -TimeoutSec 3 -Uri $url
        return $response -split "\s+"
    }
    catch {
        $output = @()
        for ($i = 0; $i -lt $weather_functions.Length; $i++) {
            $output += "Network Error"
        }
        return $output
    }
}

$contains_weather_function = $weather_functions | ForEach-Object {
    if ($all_config -contains $_) {
        return $true
    }
}

if ($contains_weather_function) {
    $weatherInfoParts = get_weather_data
}

if (-not $stripansi) {
    # Unhide the cursor after a terminating error
    trap { "$e[?25h"; break }

    # Reset terminal sequences and display a newline
    Write-Output "$e[0m$e[?25l"
}
else {
    Write-Output ""
}

$config_bottom_not_blank = check_non_blank -ConfigArray $config_bottom 

if (!$config_bottom_not_blank -and -not $stripansi ) {
    foreach ($line in $img) {
        Write-Output $line
    }
}

$bottom_output_lines = @()
$bottom_max_length = 0

$isRightColumn = $false
$isBottomSection = $true

if ($config_bottom_not_blank) {
    ProcessConfigItems -configItems $config_bottom -outputLines ([ref]$bottom_output_lines) -maxLength ([ref]$bottom_max_length)
}

for ($i = 0; $i -lt $bottom_output_lines.Count; $i++) {
    $bottom_output_lines[$i].Content = " " + $bottom_output_lines[$i].Content
}

# Add 1 to account for the space in the front
$bottom_max_length += 1

$max_logo_bottom_length = [Math]::Max($logo_max_length, $bottom_max_length)
$bottom_gt_logo = $bottom_max_length -gt $logo_max_length

# The "Bottom not blank" condition prevents double printing of the logo.
# If $bottom_gt_logo is true, it indicates that the logo needs to be processed for centering.
# When the number of bottom output lines is too long and the terminal height is insufficient,
# the cursor movement technique may not work correctly.
# If the terminal window cannot display all lines at once, it scrolls.
# As a result, moving the cursor up by a relative number of lines will not return it to the top of the logo.
# To manage this situation, we concatenate different sections and print all the information together at once.
# Skip the printing process if stripansi is false because cursor movment not possible witout ANSI escape codes
if ($(($config_bottom_not_blank -and -not $bottom_gt_logo ) -and ( $bottom_output_lines.Length -lt 6 ) -and -not $stripansi)) {
    foreach ($line in $img) {
        Write-Output $line
    }
    foreach ($line in $bottom_output_lines) {
        $lineContent = truncate_line $line.Content $max_logo_bottom_length
        Write-Output "$lineContent"
    }
}
# $GAP = 3
# $writtenLines = 0

# Process Header Items
$header_output_lines = @()
$footer_output_lines = @()
$header_max_length = 0
$footer_max_length = 0

ProcessHeaderItems -headerItems $header -outputLines ([ref]$header_output_lines) -maxLength ([ref]$header_max_length) -colorMap $headerColorMap
ProcessHeaderItems -headerItems $footer -outputLines ([ref]$footer_output_lines) -maxLength ([ref]$footer_max_length) -colorMap $footerColorMap

$config_right_blank = -not $(check_non_blank -ConfigArray $config_right) 
$center_functions = @("colorbar_center", "gradient_center")
$not_contain_center = ($center_functions | ForEach-Object { $_ -notin $config_left }) -notcontains $false
$freeSpace = 0


function AlignBartextLines {
    param (
        [array]$BartextLines,
        [string]$Pattern = '^(.*?)(▇+|\[[\s■\-]+\])\s+(.+)$'
    )

    AlignAndOutputLines -Lines $BartextLines -Pattern $Pattern -IsTextbar:$false
}

function AlignTextbarLines {
    param (
        [array]$TextbarLines,
        [string]$Pattern = '^(.*?)(▇+|\[[\s■\-]+\])$'
    )
    AlignAndOutputLines -Lines $TextbarLines -Pattern $Pattern -IsTextbar:$true 
}


if ($($config_right_blank -and $not_contain_center) -and -not $bottom_gt_logo) {
    $GAP = 3
    $writtenLines = 0
    $freeSpace = $Host.UI.RawUI.WindowSize.Width - 1

    # move cursor to top of image and to its right
    if ($img -and -not $stripansi) {
        $bottomSectionLines = $bottom_output_lines.Count
        $logoHeight = $img.Length
        $moveUpLines = $logoHeight + $bottomSectionLines + 1
        $freeSpace -= 1 + $COLUMNS + $GAP
        Write-Output "$e[${moveUpLines}A"
    }

    $colorKey = Get-AnsiCode -colorInput $colorLeftKey
    $colorValue = Get-AnsiCode -colorInput $colorLeftValue

    for ($i = 0; $i -lt $header_output_lines.Count; $i++) {
        $output = $header_output_lines[$i]

        if ($img) {
            if (-not $stripansi) {
                # move cursor to right of image
                $output = "$e[$(2 + $COLUMNS + $GAP)G$output"
            }
            else {
                # write image progressively
                $imgline = ("$($img[$writtenLines])" -replace $ansiRegex, "").PadRight($COLUMNS)
                $output = " $imgline   $output"
            }
        }
    
        $writtenLines++
    
        if ($stripansi) {
            $output = $output -replace $ansiRegex, ""
            if ($output.Length -gt $freeSpace) {
                $output = $output.Substring(0, $freeSpace)
            }
        }
        else {
            $output = truncate_line $output $($freeSpace)
        }
        Write-Output $output
    }

    # Initialize variables
    $bufferedBartextLines = @()
    $bufferedTextbarLines = @()
    $bartextPattern = '^(.*?)(▇+|\[[\s■\-]+\])\s+(.+)$'
    $textbarPattern = '^(?!\s*$).+(?:▇+$|\[[\s■\-]+\])$'

    foreach ($item in $config_left) {
        $isRightColumn = $false
        $isBottomSection = $false

        $isGeneralItem = $false
        if ($item.StartsWith('general_')) {
            $isGeneralItem = $true
            $itemName = $item.Substring(8)  # Remove 'general_' prefix
            $functionToCall = "info_$itemName"
        }
        else {
            $functionToCall = "info_$item"
        }

        # Check if the function exists before calling
        if (Get-Command -Name $functionToCall -ErrorAction SilentlyContinue) {
            $info = & $functionToCall
        }
        else {
            $info = @{ title = "`e[31mFunction '$functionToCall' not found" }
        }

        if (-not $info) {
            continue
        }

        if ($info -isnot [array]) {
            $info = @($info)
        }

        foreach ($line in $info) {
            $title = $line["title"]
            $content = $line["content"]

            $output = ColorOutput -Title $title -Content $content -ColorKey $colorKey -ColorValue $colorValue

            if ($img) {
                if (-not $stripansi) {
                    # Move cursor to the right of the image
                    $output = "$e[$(2 + $COLUMNS + $GAP)G$output"
                }
                else {
                    # Write image progressively
                    # Added +2 to fix the indentation issue when there is no image
                    $imgline = ("$($img[$writtenLines])" -replace $ansiRegex, "").PadRight($COLUMNS + 2)
                    $output = " $imgline   $output"
                }
            }

            $writtenLines++

            if ($stripansi) {
                $output = $output -replace $ansiRegex, ""
                if ($output.Length -gt $freeSpace) {
                    $output = $output.Substring(0, $freeSpace)
                }
            }
            else {
                $output = truncate_line $output $($freeSpace)
            }

            # Determine if the current line matches the bartext or textbar pattern
            # If yes, hold on printing until the streak ends and then output them together aligned
            $cleanOutput = $output -replace $ansiRegex, ""
            $isBartext = $cleanOutput -match $bartextPattern
            $isTextbar = $cleanOutput -match $textbarPattern

            if ($isBartext) {
                # Add the current line to the buffer
                $bufferedBartextLines += @{ Content = $output }
                continue
            }
            if ($isTextbar) {
                $bufferedTextbarLines += @{ Content = $output }
                continue
            }
            else {
                # If there are buffered bartext lines, process and output them first
                if ($bufferedBartextLines.Count -gt 0) {
                    AlignBartextLines -BartextLines $bufferedBartextLines
                    $bufferedBartextLines = @()
                }

                if ($bufferedTextbarLines.Count -gt 0) {
                    AlignTextbarLines -TextbarLines $bufferedTextbarLines
                    $bufferedTextbarLines = @()
                }

                Write-Output $output
            }
        }
    }

    # After processing all items, check if there are any remaining buffered bartext or textbar lines
    if ($bufferedBartextLines.Count -gt 0) {
        AlignBartextLines -BartextLines $bufferedBartextLines
        $bufferedBartextLines = @()
    }
    if ($bufferedTextbarLines.Count -gt 0) {
        AlignTextbarLines -TextbarLines $bufferedTextbarLines
        $bufferedTextbarLines = @()
    }


    for ($i = 0; $i -lt $footer_output_lines.Count; $i++) {
        $output = $footer_output_lines[$i]

        if ($img) {
            if (-not $stripansi) {
                # move cursor to right of image
                $output = "$e[$(2 + $COLUMNS + $GAP)G$output"
            }
            else {
                # write image progressively
                $imgline = ("$($img[$writtenLines])" -replace $ansiRegex, "").PadRight($COLUMNS)
                if ($writtenLines -lt $img.Length) {
                    $output = " ${imgline}   ${output}"
                }
                else {
                    $output = " ${imgline}     ${output}"
                }
            }
        }

        $writtenLines++

        if ($stripansi) {
            $output = $output -replace $ansiRegex, ""
            if ($output.Length -gt $freeSpace) {
                $output = $output.Substring(0, $freeSpace)
            }
        }
        else {
            $output = truncate_line $output $($freeSpace)
        }

        Write-Output $output
    }

    if ($stripansi) {
        # write out remaining image lines
        for ($i = $writtenLines; $i -lt $img.Length; $i++) {
            $imgline = ("$($img[$i])" -replace $ansiRegex, "").PadRight($COLUMNS)
            Write-Output " $imgline"
        }
    }

    # move cursor back to the bottom and print 2 newlines
    if (-not $stripansi) {
        $diff = $img.Length - $writtenLines
        if ($img -and $diff -gt 0) {
            Write-Output "$e[${diff}B"
        }
        else {
            Write-Output ""
        }
        Write-Output "$e[?25h"
    }
    else {
        Write-Output "`n"
    }
}
else {
    $left_output_lines = @()
    $right_output_lines = @()

    $left_max_length = 0
    $right_max_length = 0

    $isRightColumn = $false
    $isBottomSection = $false

    if (check_non_blank -ConfigArray $config_left) {
        ProcessConfigItems -configItems $config_left -outputLines ([ref]$left_output_lines) -maxLength ([ref]$left_max_length)
    }

    $isRightColumn = $true
    $isBottomSection = $false

    if (check_non_blank -ConfigArray $config_right) {
        ProcessConfigItems -configItems $config_right -outputLines ([ref]$right_output_lines) -maxLength ([ref]$right_max_length)
    }

    $total_length = $max_logo_bottom_length + 6 + [Math]::Max([Math]::Max($right_max_length + $left_max_length, $header_max_length), $footer_max_length)

    $cutoff = $false
    if ($total_length -gt $Host.UI.RawUI.WindowSize.Width -and $bottom_gt_logo) {
        $indentation_length = $logo_max_length + 4
        $cutoff = $true
        $max_logo_bottom_length = $logo_max_length
    }
    else {
        $indentation_length = $max_logo_bottom_length + 4 # Add 4 spaces
        if ($stripansi) {
            $indentation_length = $max_logo_bottom_length + 3
        }
    }

    $freeSpace = $Host.UI.RawUI.WindowSize.Width - $indentation_length - 1
    $indentation = " " * $indentation_length
    $max_lines = [Math]::Max($left_output_lines.Count, $right_output_lines.Count)

    $combinedLines = @()

    # Center the logo if $centerlogo is true and image exists
    # If cutoff is true, the max length of bottom section is restricted by logo_max_length. 
    # In consequence, if cutoff is true, centering the logo is not necessary.
    if ($img -and $centerlogo -and (-not $cutoff -or $bottom_max_length -le $logo_max_length)) {
        for ($i = 0; $i -lt $img.Count; $i++) {
            $img[$i] = pad_line_center $img[$i] ($max_logo_bottom_length + 1) # +1 for the added space to the left
        }
    }

    for ($i = 0; $i -lt $max_lines; $i++) {
        $left_line = if ($i -lt $left_output_lines.Count) { $left_output_lines[$i].Content } else { "" }
        $left_config_item = if ($i -lt $left_output_lines.Count) { $left_output_lines[$i].ConfigItem } else { "" }
        $left_is_general = if ($i -lt $left_output_lines.Count) { $left_output_lines[$i].IsGeneralItem } else { $false }

        $right_line = if ($i -lt $right_output_lines.Count) { $right_output_lines[$i].Content } else { "" }
        $right_config_item = if ($i -lt $right_output_lines.Count) { $right_output_lines[$i].ConfigItem } else { "" }

        # Remove extra space in the first row except colorbar_center or gradient_center
        if ($left_config_item -ne 'colorbar_center' -or $left_config_item -ne 'gradient_center') {
            $left_line = $left_line.TrimStart()
        }
        if ($right_config_item -ne 'colorbar_center' -or $right_config_item -ne 'gradient_center') {
            $right_line = $right_line.TrimStart()
        }
    
        # Calculate spaces needed
        $plain_left_line = $left_line -replace $ansiRegex, ""
        if ($right_line -eq "" -Or $null -eq $right_line) {
            $spaces_needed = $left_max_length - $plain_left_line.Length
        }
        else {
            $spaces_needed = $left_max_length - $plain_left_line.Length + 3
        }

        if ($spaces_needed -lt 0) { $spaces_needed = 0 }
        $spaces = " " * $spaces_needed

        if ($img) {
            if (-not $stripansi) {
                # Move cursor to the indentation position
                $left_line = "$e[${indentation_length}G$left_line"
            }
            else {
                $index = $i + $header_output_lines.Length
                if ($index -lt $img.Length) {
                    if ($cutoff) {
                        $left_line = "   $left_line"
                    }
                    else {
                        $mod_img = $img[$i] -replace $ansiRegex, ""
                        if ($bottom_max_length -gt $mod_img.Length) {
                            $space_count = " " * $($bottom_max_length - $mod_img.Length + 3)
                        }
                        else {
                            $space_count = " " * 3
                        }
                        $left_line = "$space_count$left_line"
                    }
                }
                    
                else {
                    if (!$config_bottom_not_blank) {
                        $left_line = "   $left_line"
                    }
                    else {
                        $index = $index - $img.Length
                        $current_text = $bottom_output_lines[$index].Content -replace $ansiRegex, ""
                        if ($cutoff) {
                            if ($current_text.Length -gt $logo_max_length) {
                                $space_count = " " * 3
                            }
                            else {
                                $space_count = " " * $($logo_max_length - $current_text.Length + 3)
                            }
                        }
                        else {
                            $space_count = " " * $($max_logo_bottom_length - $current_text.Length + 3)
                        }
                        $left_line = "$space_count$left_line"
                    }
                }
            }
        }
        else {
            # If no image, no indentation
            $left_line = "$left_line"
        }

        # If config_left has general flag, skip corresponding right item
        if ($left_is_general) {
            $combined_line = "$left_line"
        }
        else {
            $combined_line = "$left_line$spaces$right_line"
        }
        $combinedLines += $combined_line
    }

    # Handle header and footer spacing, specifically in stripansi mode
    function HeaderFooterSpacing {
        param (
            [string]$line,
            [int]$index
        )

        if ($img) {
            if (-not $stripansi) {
                # Move cursor to the indentation position
                $line = "$e[${indentation_length}G$line"
            }
            else {
                if ($index -lt $img.Length) {
                    if ($cutoff) {
                        $line = "   $line"
                    }
                    else {
                        $mod_img = $img[$index] -replace $ansiRegex, ""
                        if ($bottom_max_length -gt $mod_img.Length) {
                            $space_count = " " * ($bottom_max_length - $mod_img.Length + 3)
                        }
                        else {
                            $space_count = " " * 3
                        }
                        $line = "$space_count$line"
                    }
                }
                else {
                    if (-not $config_bottom_not_blank) {
                        $line = "   $line"
                    }
                    else {
                        $index = $index - $img.Length
                        $current_text = $bottom_output_lines[$index].Content -replace $ansiRegex, ""
                        if ($cutoff) {
                            if ($current_text.Length -gt $logo_max_length) {
                                $space_count = " " * 3
                            }
                            else {
                                $space_count = " " * ($logo_max_length - $current_text.Length + 3)
                            }
                        }
                        else {
                            $space_count = " " * ($max_logo_bottom_length - $current_text.Length + 3)
                        }
                        $line = "$space_count$line"
                    }
                }
            }
        }
        return $line
    }

    for ($i = 0; $i -lt $header_output_lines.Count; $i++) {
        $line = $header_output_lines[$i]
        $header_output_lines[$i] = HeaderFooterSpacing $line $i
    }

    for ($i = 0; $i -lt $footer_output_lines.Count; $i++) {
        $line = $footer_output_lines[$i]
        $index = $i + $header_output_lines.Length + $combinedLines.Length
        $footer_output_lines[$i] = HeaderFooterSpacing $line $index
    }

    $combinedLines = $header_output_lines + $combinedLines + $footer_output_lines

    if ($bottom_output_lines.Length -lt 6 -and $logo_max_length -ge $bottom_max_length -and -not $stripansi) {
        if ($img) {
            $bottomSectionLines = $bottom_output_lines.Count
            $logoHeight = $img.Length
            $moveUpLines = $logoHeight + $bottomSectionLines + 1
            Write-Output "$e[${moveUpLines}A"
        }

        foreach ($combined_line in $combinedLines) {
            $lineContent = ""
            $lineContent = truncate_line $combined_line $freeSpace
    
            Write-Output $lineContent
            $writtenLines++
        }

        $max_lines = [Math]::Max($img.Count + $bottom_output_lines.Count, $combinedLines.Count) 
        Write-Host ""
    }

    else {
        # Determine the maximum number of lines needed
        $max_lines = [Math]::Max($img.Count + $bottom_output_lines.Count, $combinedLines.Count) 

        # Index for bottom_output_lines
        $bottomIndex = 0

        for ($i = 0; $i -lt $max_lines; $i++) {
            $imgLine = ""
            $bottomLine = ""
            $combinedLine = ""

            # Get the current line from $img if within range, otherwise $bottom_output_lines
            if ($i -lt $img.Count) {
                $imgLine = $img[$i]
            }
            elseif ($bottomIndex -lt $bottom_output_lines.Count) {
                $bottomLine = $bottom_output_lines[$bottomIndex].Content
                $bottomIndex++
            }

            # Get the current combined line if within range
            if ($i -lt $combinedLines.Count) {
                $combinedLine = $combinedLines[$i]
            }

            if ($imgLine) {
                $processedLine1 = truncate_line $imgLine $max_logo_bottom_length
            }
            elseif ($bottomLine) {
                $processedLine1 = truncate_line $bottomLine $($max_logo_bottom_length)
            }
            else {
                $processedLine1 = ""
                if ($stripansi) {
                    $processedLine1 = " " * $max_logo_bottom_length
                }
            }

            if ($combinedLine) {

                $processedLine2 = truncate_line $combinedLine $freeSpace
            }
            else {
                $processedLine2 = ""
            }

            $finalLine = "$processedLine1$processedLine2"
            if ($stripansi) {
                $finalLine = $finalLine -replace $ansiRegex, ""
            }
            # Uncomment to test if all ANSI removed in stripansi mode
            # $finalLine = $finalLine -replace "`e", "\\e"

            Write-Output $finalLine
        }
    }

    # Reset the color on terminal
    if (-not $stripansi) {
        [console]::Write("`e[0m")
    }

    if (-not $stripansi) {
        Write-Output "$e[?25h"
    }
    else {
        Write-Output ""
    }
}
