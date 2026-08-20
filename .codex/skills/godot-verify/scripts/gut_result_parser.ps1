function Find-FirstGutCount {
	param([string]$Text, [string[]]$Patterns)
	foreach ($pattern in $Patterns) {
		$match = [regex]::Match($Text, $pattern)
		if ($match.Success) { return [int]$match.Groups[1].Value }
	}
	return $null
}

function Get-GutResultReport {
	param([Parameter(Mandatory)][pscustomobject]$Result)

	$total = Find-FirstGutCount $Result.Text @(
		'(?im)^\s*Tests\s*:?\s*(\d+)\s*$',
		'(?im)^\s*Total Tests\s*:?\s*(\d+)\s*$'
	)
	$passing = Find-FirstGutCount $Result.Text @(
		'(?im)^\s*Passing Tests\s*:?\s*(\d+)\s*$',
		'(?im)^\s*Passing\s*:?\s*(\d+)\s*$'
	)
	$failing = Find-FirstGutCount $Result.Text @(
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

	$hasSummary = $null -ne $total -and $null -ne $passing -and $null -ne $failing
	if (-not $hasSummary) {
		if ($Result.Succeeded) {
			$classification = 'UnusableResults'
			$message = 'GUT results: runner completed, but test totals could not be parsed from its output.'
		} else {
			$classification = 'ExecutionFailed'
			$message = 'GUT execution failed before producing usable test results.'
		}
		return [pscustomobject]@{
			Outcome = 'AutomatedFail'
			Classification = $classification
			HasSummary = $false
			Total = $null
			Passing = $null
			Failing = $null
			Message = $message
		}
	}

	if ($failing -gt 0) {
		$outcome = 'AutomatedFail'
		$classification = 'SuiteFailed'
		$message = "GUT suite failed: $total total, $passing passing, $failing failing."
	} elseif (-not $Result.Succeeded) {
		$outcome = 'AutomatedFail'
		$classification = 'ExecutionFailed'
		$message = "GUT execution failed after reporting results: $total total, $passing passing, $failing failing."
	} else {
		$outcome = 'AutomatedPass'
		$classification = 'Passed'
		$message = "GUT results: $total total, $passing passing, $failing failing."
	}

	return [pscustomobject]@{
		Outcome = $outcome
		Classification = $classification
		HasSummary = $true
		Total = $total
		Passing = $passing
		Failing = $failing
		Message = $message
	}
}
