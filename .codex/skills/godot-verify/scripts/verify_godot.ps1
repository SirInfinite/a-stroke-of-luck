[CmdletBinding()]
param(
	[string]$ProjectPath = (Get-Location).Path,
	[string]$GodotPath = "",
	[int]$LaunchIterations = 3
)

$ErrorActionPreference = "Stop"
$automatedPasses = [System.Collections.Generic.List[string]]::new()
$automatedFailures = [System.Collections.Generic.List[string]]::new()
$diffReview = [System.Collections.Generic.List[string]]::new()
$manualPlaytest = [System.Collections.Generic.List[string]]::new()
$errorPattern = '(?im)(SCRIPT ERROR|PARSE ERROR|ERROR:|Failed to (load|open)|Can''t (load|open)|Resource[^\r\n]*(missing|not found)|Invalid UID)'

function Resolve-GodotExecutable {
	param([string]$RequestedPath)
	if ($RequestedPath) {
		if (Test-Path -LiteralPath $RequestedPath -PathType Leaf) { return (Resolve-Path -LiteralPath $RequestedPath).Path }
		throw "Requested Godot executable does not exist: $RequestedPath"
	}
	foreach ($name in @('godot4', 'godot')) {
		$command = Get-Command $name -CommandType Application, ExternalScript -ErrorAction SilentlyContinue | Select-Object -First 1
		if ($command) { return $command.Source }
	}
	foreach ($knownLauncher in @('C:\Users\Rony\bin\godot4.cmd')) {
		if (Test-Path -LiteralPath $knownLauncher -PathType Leaf) { return $knownLauncher }
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
		$automatedFailures.Add("${Label}: $reason")
		$succeeded = $false
	} else {
		$automatedPasses.Add("${Label}: exit 0 with no parser/runtime/resource error signature")
		$succeeded = $true
	}
	return [pscustomobject]@{
		ExitCode = $code
		Text = $text
		Succeeded = $succeeded
	}
}

function Find-FirstCount {
	param([string]$Text, [string[]]$Patterns)
	foreach ($pattern in $Patterns) {
		$match = [regex]::Match($Text, $pattern)
		if ($match.Success) { return [int]$match.Groups[1].Value }
	}
	return $null
}

function Add-GutResult {
	param([pscustomobject]$Result)
	if (-not $Result.Succeeded) { return }

	$total = Find-FirstCount $Result.Text @(
		'(?im)^\s*Tests\s*:?\s*(\d+)\s*$',
		'(?im)^\s*Total Tests\s*:?\s*(\d+)\s*$'
	)
	$passing = Find-FirstCount $Result.Text @(
		'(?im)^\s*Passing Tests\s*:?\s*(\d+)\s*$',
		'(?im)^\s*Passing\s*:?\s*(\d+)\s*$'
	)
	$failing = Find-FirstCount $Result.Text @(
		'(?im)^\s*Failing Tests\s*:?\s*(\d+)\s*$',
		'(?im)^\s*Failing\s*:?\s*(\d+)\s*$'
	)

	if ($null -eq $total -and $null -ne $passing -and $null -ne $failing) { $total = $passing + $failing }
	if ($null -eq $failing -and $null -ne $total -and $null -ne $passing) { $failing = $total - $passing }
	if ($null -eq $passing -and $null -ne $total -and $null -ne $failing) { $passing = $total - $failing }
	if ($null -eq $failing -and $null -ne $total) {
		$failing = 0
		$passing = $total
	}
	if ($null -eq $total -or $null -eq $passing -or $null -eq $failing) {
		$automatedFailures.Add('GUT results: runner completed, but test totals could not be parsed from its output.')
		return
	}
	if ($failing -gt 0) {
		$automatedFailures.Add("GUT results: $total total, $passing passing, $failing failing.")
	} else {
		$automatedPasses.Add("GUT results: $total total, $passing passing, $failing failing.")
	}
}

function Test-PlayerFacingPath {
	param([string]$Path)
	return $Path -match '^(assets|data|levels|scenes|scripts|ui)[\\/]' -or $Path -in @('project.godot', 'export_presets.cfg')
}

try {
	$project = (Resolve-Path -LiteralPath $ProjectPath).Path
	if (-not (Test-Path -LiteralPath (Join-Path $project 'project.godot') -PathType Leaf)) { throw "project.godot not found in $project" }
	$godot = Resolve-GodotExecutable $GodotPath
	Write-Host "Project: $project"
	Write-Host "Godot:  $godot"

	$null = Invoke-GodotCheck 'Godot version' $godot @('--version')
	$null = Invoke-GodotCheck 'Project import' $godot @('--headless', '--path', $project, '--import')
	$null = Invoke-GodotCheck 'Main-scene launch' $godot @('--headless', '--path', $project, '--quit-after', $LaunchIterations.ToString())

	$gut = Join-Path $project 'addons\gut\gut_cmdln.gd'
	$tests = Join-Path $project 'tests'
	if ((Test-Path -LiteralPath $gut -PathType Leaf) -and (Test-Path -LiteralPath $tests -PathType Container)) {
		$gutResult = Invoke-GodotCheck 'GUT tests' $godot @('--headless', '--path', $project, '--script', 'res://addons/gut/gut_cmdln.gd', '-gdir=res://tests', '-gexit')
		Add-GutResult $gutResult
	} elseif (Test-Path -LiteralPath $tests -PathType Container) {
		$automatedFailures.Add('Test discovery: a tests directory exists without the supported vendored GUT runner.')
	} else {
		$automatedPasses.Add('Test discovery: 0 tests run because no tests directory or vendored GUT runner is available.')
	}

	Push-Location $project
	try {
		if ((& git rev-parse --is-inside-work-tree 2>$null) -ne 'true') {
			$automatedFailures.Add('Git review preparation: project is not inside a Git working tree.')
		} else {
			foreach ($check in @(
				@('Git diff check', 'diff', '--check'),
				@('Git staged diff check', 'diff', '--cached', '--check')
			)) {
				Write-Host "`n--- $($check[0]) ---"
				$output = @(& git @($check[1..($check.Count - 1)]) 2>&1 | ForEach-Object { $_.ToString() })
				$code = $LASTEXITCODE
				if ($output) { Write-Host ($output -join [Environment]::NewLine) }
				if ($code -eq 0) {
					$automatedPasses.Add("$($check[0]): no whitespace errors.")
				} else {
					$automatedFailures.Add("$($check[0]): exit $code")
				}
			}
			Write-Host "`n--- Git working tree ---"
			$status = @(& git status --short 2>&1 | ForEach-Object { $_.ToString() })
			$code = $LASTEXITCODE
			if ($status) { Write-Host ($status -join [Environment]::NewLine) } else { Write-Host '(clean)' }
			if ($code -eq 0) {
				$automatedPasses.Add('Git inventory: staged, unstaged, and untracked paths listed.')
				$diffReview.Add('PENDING: inspect complete staged and unstaged diffs plus every relevant untracked file; inventory is printed above.')
				$changedPaths = @($status | ForEach-Object {
					$path = $_.Substring(3).Trim()
					if ($path -match ' -> ') { $path = ($path -split ' -> ')[-1] }
					$path
				})
				$playerFacingPaths = @($changedPaths | Where-Object { Test-PlayerFacingPath $_ })
				if ($playerFacingPaths.Count -gt 0) {
					$manualPlaytest.Add("Player-facing paths are present in the working tree: $($playerFacingPaths -join ', '). Run the relevant QUALITY_BAR and MVP_TEST_CHECKLIST scenarios.")
				}
			} else {
				$automatedFailures.Add("Git status: exit $code")
			}
		}
	} finally { Pop-Location }
} catch {
	$automatedFailures.Add($_.Exception.Message)
}

Write-Host "`n=== AUTOMATED PASS ==="
if ($automatedPasses.Count) { $automatedPasses | ForEach-Object { Write-Host "- $_" } } else { Write-Host 'None' }
Write-Host "`n=== AUTOMATED FAIL ==="
if ($automatedFailures.Count) { $automatedFailures | ForEach-Object { Write-Host "- $_" } } else { Write-Host 'None' }
Write-Host "`n=== DIFF REVIEW ==="
if ($diffReview.Count) { $diffReview | ForEach-Object { Write-Host "- $_" } } else { Write-Host 'None' }
Write-Host "`n=== MANUAL PLAYTEST REQUIRED ==="
if ($manualPlaytest.Count) { $manualPlaytest | ForEach-Object { Write-Host "- $_" } } else { Write-Host 'None' }

if ($automatedFailures.Count) { Write-Host "`nAUTOMATED RESULT: FAIL"; exit 1 }
Write-Host "`nAUTOMATED RESULT: PASS"
exit 0
