[CmdletBinding()]
param(
	[Parameter(Mandatory)]
	[ValidateSet('Passing', 'Failing', 'ExecutionFailure')]
	[string]$Fixture
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'gut_result_parser.ps1')

function Assert-Equal {
	param($Actual, $Expected, [string]$Label)
	if ($Actual -ne $Expected) {
		throw "$Label expected '$Expected' but got '$Actual'."
	}
}

switch ($Fixture) {
	'Passing' {
		$commandResult = [pscustomobject]@{
			ExitCode = 0
			Succeeded = $true
			Text = @'
Tests: 6
Passing Tests: 6
Failing Tests: 0
'@
		}
		$expected = @{
			Outcome = 'AutomatedPass'
			Classification = 'Passed'
			HasSummary = $true
			Total = 6
			Passing = 6
			Failing = 0
			Message = 'GUT results: 6 total, 6 passing, 0 failing.'
		}
	}
	'Failing' {
		$commandResult = [pscustomobject]@{
			ExitCode = 1
			Succeeded = $false
			Text = @'
Tests: 7
Passing Tests: 5
Failing Tests: 2
'@
		}
		$expected = @{
			Outcome = 'AutomatedFail'
			Classification = 'SuiteFailed'
			HasSummary = $true
			Total = 7
			Passing = 5
			Failing = 2
			Message = 'GUT suite failed: 7 total, 5 passing, 2 failing.'
		}
	}
	'ExecutionFailure' {
		$commandResult = [pscustomobject]@{
			ExitCode = 2
			Succeeded = $false
			Text = 'GUT could not load the test runner.'
		}
		$expected = @{
			Outcome = 'AutomatedFail'
			Classification = 'ExecutionFailed'
			HasSummary = $false
			Total = $null
			Passing = $null
			Failing = $null
			Message = 'GUT execution failed before producing usable test results.'
		}
	}
}

$report = Get-GutResultReport $commandResult
foreach ($field in @('Outcome', 'Classification', 'HasSummary', 'Total', 'Passing', 'Failing', 'Message')) {
	Assert-Equal $report.$field $expected[$field] $field
}

Write-Output "$Fixture fixture PASS: outcome=$($report.Outcome), classification=$($report.Classification), message=$($report.Message)"
