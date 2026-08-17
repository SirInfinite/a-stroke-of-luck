[CmdletBinding()]
param(
	[string]$ProjectPath = (Get-Location).Path,
	[string]$GodotPath = "",
	[int]$LaunchIterations = 3
)

$ErrorActionPreference = "Stop"
$passes = [System.Collections.Generic.List[string]]::new()
$failures = [System.Collections.Generic.List[string]]::new()
$manual = [System.Collections.Generic.List[string]]::new()
$errorPattern = '(?im)(SCRIPT ERROR|PARSE ERROR|ERROR:|Failed to (load|open)|Can''t (load|open)|Resource[^\r\n]*(missing|not found)|Invalid UID)'

function Resolve-GodotExecutable {
	param([string]$RequestedPath)
	if ($RequestedPath) {
		if (Test-Path -LiteralPath $RequestedPath -PathType Leaf) { return (Resolve-Path -LiteralPath $RequestedPath).Path }
		throw "Requested Godot executable does not exist: $RequestedPath"
	}
	$knownLauncher = 'C:\Users\Rony\bin\godot4.cmd'
	if (Test-Path -LiteralPath $knownLauncher -PathType Leaf) { return $knownLauncher }
	foreach ($name in @('godot4', 'godot')) {
		$command = Get-Command $name -ErrorAction SilentlyContinue | Select-Object -First 1
		if ($command) { return $command.Source }
	}
	throw 'Godot was not found. Pass -GodotPath or install a godot4/godot command.'
}

function Invoke-GodotCheck {
	param([string]$Label, [string]$Executable, [string[]]$Arguments)
	Write-Host "`n--- $Label ---"
	$lines = @(& $Executable @Arguments 2>&1 | ForEach-Object { $_.ToString() })
	$code = $LASTEXITCODE
	$text = $lines -join [Environment]::NewLine
	if ($text) { Write-Host $text }
	if ($code -ne 0 -or $text -match $errorPattern) {
		$reason = "exit $code"
		if ($text -match $errorPattern) { $reason += ', error signature detected' }
		$failures.Add("${Label}: $reason")
	} else {
		$passes.Add("${Label}: exit 0 with no parser/runtime/resource error signature")
	}
}

try {
	$project = (Resolve-Path -LiteralPath $ProjectPath).Path
	if (-not (Test-Path -LiteralPath (Join-Path $project 'project.godot') -PathType Leaf)) { throw "project.godot not found in $project" }
	$godot = Resolve-GodotExecutable $GodotPath
	Write-Host "Project: $project"
	Write-Host "Godot:  $godot"

	Invoke-GodotCheck 'Godot version' $godot @('--version')
	Invoke-GodotCheck 'Project import' $godot @('--headless', '--path', $project, '--import')
	Invoke-GodotCheck 'Main-scene launch' $godot @('--headless', '--path', $project, '--quit-after', $LaunchIterations.ToString())

	$gut = Join-Path $project 'addons\gut\gut_cmdln.gd'
	$tests = Join-Path $project 'tests'
	if ((Test-Path -LiteralPath $gut -PathType Leaf) -and (Test-Path -LiteralPath $tests -PathType Container)) {
		Invoke-GodotCheck 'GUT tests' $godot @('--headless', '--path', $project, '--script', 'res://addons/gut/gut_cmdln.gd', '-gdir=res://tests', '-gexit')
	} elseif (Test-Path -LiteralPath $tests -PathType Container) {
		$manual.Add('A tests directory exists without a supported GUT runner; determine and run its command manually.')
	} else {
		$passes.Add('Test discovery: no automated tests directory or GUT run is available.')
	}

	Push-Location $project
	try {
		if ((& git rev-parse --is-inside-work-tree 2>$null) -ne 'true') {
			$failures.Add('Git review: project is not inside a Git working tree.')
		} else {
			foreach ($check in @(
				@('Git diff check', 'diff', '--check'),
				@('Git staged diff check', 'diff', '--cached', '--check')
			)) {
				Write-Host "`n--- $($check[0]) ---"
				$output = @(& git @($check[1..($check.Count - 1)]) 2>&1 | ForEach-Object { $_.ToString() })
				$code = $LASTEXITCODE
				if ($output) { Write-Host ($output -join [Environment]::NewLine) }
				if ($code -eq 0) { $passes.Add("$($check[0]): no whitespace errors.") } else { $failures.Add("$($check[0]): exit $code") }
			}
			Write-Host "`n--- Git working tree ---"
			$status = @(& git status --short 2>&1 | ForEach-Object { $_.ToString() })
			$code = $LASTEXITCODE
			if ($status) { Write-Host ($status -join [Environment]::NewLine) } else { Write-Host '(clean)' }
			if ($code -eq 0) { $passes.Add('Git inventory: staged, unstaged, and untracked paths listed.') } else { $failures.Add("Git status: exit $code") }
		}
	} finally { Pop-Location }

	$manual.Add('Review complete staged and unstaged diffs plus every relevant untracked file.')
	$manual.Add('Run relevant QUALITY_BAR and MVP_TEST_CHECKLIST scenarios for player-facing changes.')
} catch {
	$failures.Add($_.Exception.Message)
}

Write-Host "`n=== PASS ==="
if ($passes.Count) { $passes | ForEach-Object { Write-Host "- $_" } } else { Write-Host 'None' }
Write-Host "`n=== FAIL ==="
if ($failures.Count) { $failures | ForEach-Object { Write-Host "- $_" } } else { Write-Host 'None' }
Write-Host "`n=== MANUAL PLAYTEST REQUIRED ==="
if ($manual.Count) { $manual | ForEach-Object { Write-Host "- $_" } } else { Write-Host 'None' }

if ($failures.Count) { Write-Host "`nOVERALL: FAIL"; exit 1 }
Write-Host "`nOVERALL: PASS"
exit 0
