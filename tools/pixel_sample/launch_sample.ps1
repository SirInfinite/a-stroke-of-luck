[CmdletBinding()]
param(
	[switch]$Original,
	[ValidateSet('A', 'B')][string]$Track = 'A',
	[string]$GodotPath = '',
	[ValidateSet('1280x720', '1920x1080', '2560x1440', '3440x1440')]
	[string]$Resolution = '1920x1080'
)
$ErrorActionPreference = 'Stop'
$sampleProject = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
if (-not $GodotPath) {
	$sampleCommand = Get-Command godot4 -ErrorAction SilentlyContinue
	if (-not $sampleCommand) { throw 'Godot 4.6.2 is required. Supply -GodotPath with its executable path.' }
	$GodotPath = $sampleCommand.Source
}
$sampleArgs = @('--path', $sampleProject, 'res://tools/pixel_sample/pixel_sample.tscn', '--', "--sample-size=$Resolution")
if (-not $Original) { $sampleArgs += '--sample-after' }
if ($Track -eq 'B') { $sampleArgs += '--sample-track-b' }
& $GodotPath @sampleArgs
exit $LASTEXITCODE
