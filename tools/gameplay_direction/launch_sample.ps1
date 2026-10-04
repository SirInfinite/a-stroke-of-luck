[CmdletBinding()]
param(
	[ValidateSet('A1','A2','A3','B1','B2','B3','C1','C2','C3','ART')]
	[string]$Hole = 'A1',
	[ValidateSet('easy','normal','hard')]
	[string]$Difficulty = 'normal',
	[string]$GodotPath = ''
)
$ErrorActionPreference = 'Stop'
$project = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
if (-not $GodotPath) {
	$engine = Get-Command Godot_v4.6.2-stable_win64.exe -ErrorAction SilentlyContinue | Select-Object -First 1
	if (-not $engine) { throw 'Godot 4.6.2 was not found. Supply -GodotPath with its executable path.' }
	$GodotPath = $engine.Source
}
$executable = (Resolve-Path -LiteralPath $GodotPath).Path
# This is the explicitly requested visible interactive game, with no replay,
# movie, headless or automatic quit flags. Closing its window ends the session.
$game = Start-Process -FilePath $executable -WorkingDirectory $project -ArgumentList @(
	'--path', ('"{0}"' -f $project), '--resolution', '1600x900',
	'res://tests/gameplay_direction.tscn', '--', "--benchmark=$Hole", "--difficulty=$Difficulty"
) -PassThru
Write-Output "Playable sample opened: PID $($game.Id) | $project | $Hole | $Difficulty"
