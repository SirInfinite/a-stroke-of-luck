[CmdletBinding()]
param(
	[switch]$Previous,
	[switch]$Chunky,
	[switch]$Volcanic,
	[switch]$CaptureProof,
	[ValidateSet('A', 'B')][string]$Track = 'A',
	[ValidateSet('1280x720', '1920x1080', '2560x1440', '3440x1440')][string]$Resolution = '1920x1080',
	[string]$GodotPath = ''
)
$ErrorActionPreference = 'Stop'
$sliceProject = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
if (-not $GodotPath) {
	$sliceCommand = Get-Command godot4 -ErrorAction SilentlyContinue
	if (-not $sliceCommand) { throw 'Supply -GodotPath with the Godot 4.6.2 executable.' }
	$GodotPath = $sliceCommand.Source
}
$sliceArgs = @('--path', $sliceProject, '--audio-driver', 'WASAPI', 'res://tools/reference_slice/reference_slice.tscn', '--', "--sample-size=$Resolution")
if ($Previous) { $sliceArgs += '--previous' }
if ($Chunky) { $sliceArgs += '--chunky' }
if ($Volcanic) { $sliceArgs += '--volcanic' }
if ($CaptureProof) { $sliceArgs += '--sample-proof' }
if ($Track -eq 'B') { $sliceArgs += '--sample-track-b' }
# Explicitly interactive: no headless flag, Dummy driver, fixed shots or quit limit.
& $GodotPath @sliceArgs
exit $LASTEXITCODE
