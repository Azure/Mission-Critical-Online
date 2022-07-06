

function Compare-LocustStats {
    [CmdletBinding()] # indicate that this is advanced function (with additional params automatically added)
    param (
      $statsFile,
      $baselineFile
    )

    if (Test-Path -Path "$baselineFile") {
        $baselineJson = Get-ChildItem $baselineFile | Get-Content | ConvertFrom-JSON | Sort-Object -Property @{expression={$_.operator};Descending=$true} # sorted by test name
    } else {
        throw "*** ERROR - File $baselineFile not found."
    }

    if (Test-Path -Path "$statsFile") {
        $statsCsv = Import-CSV "$statsFile" # load csv stats file
    } else {
        throw "*** ERROR - File $statsFile not found."
    }

    $fail = 0 # set fail to zero - >0 will fail the test

    $baselineJson | ForEach-Object {
        # browse through baseline definitions
        $name = $_.name
        $values = $_.values

        $operator = $_.Operator
        # default to le (lowerequal)
        if ($operator -ne 'ge') { $operator = 'le' }

        Write-Host "Baseline Item $name"

        $statsCsv | Where-Object { $_.Name -eq $name } | ForEach-Object {
                $statsCsvData = $_

                $values | Get-Member | Where-Object { $_.MemberType -eq "NoteProperty" } | ForEach-Object {

                    $name = $($_.name) # metric name
                    $resultValue = [double]$($statsCsvData."$($_.name)") # load test result value
                    $baselineValue = [double]$($values."$($_.name)") # base line target value

                    # switch based on the operator set in baseline json
                    switch ($operator)
                    {
                        'ge' {
                            # when operator is set to ge (greater or equal)
                            if ( $resultValue -ge $baselineValue ) {
                                Write-Host "PASS - $name of $resultValue is greater or equal than $baselineValue" -ForegroundColor Green
                            } else {
                                Write-Host "FAIL - $name is lower than $baselineValue ($resultValue)" -ForegroundColor Red
                                $fail++
                            }

                         }
                         'le' {
                            # when operator is set to le (lowerequal)
                            if ( $resultValue -le $baselineValue ) {
                                Write-Host "PASS - $name of $resultValue is lower or equal than $baselineValue" -ForegroundColor Green
                            } else {
                                Write-Host "FAIL - $name is greater than $baselineValue ($resultValue)" -ForegroundColor Red
                                $fail++
                            }
                         }
                    }
                }
            }
    }
    return $fail
}

# Example how to test Compare-LocustStats
#
# $baselinePath = "./.ado/pipelines/config/loadtest-baseline.json"
# $statsPath = "aoe2e2f40_stats.csv"
# Compare-LocustStats -baselineFile $baselinePath -statsFile $statsPath