[CmdletBinding()]
param(
	[switch]$Previous,
	[string]$GodotPath = '',
	[ValidateSet('1280x720', '1600x900', '1920x1080', '2560x1440', '3440x1440')]
	[string]$Resolution = '1920x1080'
)
$ErrorActionPreference = 'Stop'
$sampleProject = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
if (-not $GodotPath) {
	$sampleCommand = Get-Command godot4 -ErrorAction SilentlyContinue
	if (-not $sampleCommand) { throw 'Godot 4.6.2 is required. Supply -GodotPath.' }
	$GodotPath = $sampleCommand.Source
}
$sampleArgs = @('--path', $sampleProject, 'res://tools/pixel_correction/correction.tscn', '--', "--sample-size=$Resolution")
if ($Previous) { $sampleArgs += '--correction-previous' }
& $GodotPath @sampleArgs
exit $LASTEXITCODE
