# Public Function:
Function Set-LocationWSLOverride {
	[CmdletBinding(DefaultParameterSetName = 'Path', HelpUri = 'https://go.microsoft.com/fwlink/?LinkID=2097049')]
	param(
		[Parameter(
			ParameterSetName = 'Path',
			Position = 0,
			ValueFromPipeline = $true,
			ValueFromPipelineByPropertyName = $true
		)]
		[string]${Path},

		[Parameter(
			ParameterSetName = 'LiteralPath',
			Mandatory = $true,
			ValueFromPipelineByPropertyName = $true
		)]
		[Alias('PSPath', 'LP')]
		[string]${LiteralPath},

		[switch]${PassThru},

		[Parameter(
			ParameterSetName = 'Stack',
			ValueFromPipelineByPropertyName = $true
		)]
		[string]${StackName}
	)

	dynamicparam {
		try {
			$targetCmd = $ExecutionContext.InvokeCommand.GetCommand(
				'Microsoft.PowerShell.Management\Set-Location',
				[System.Management.Automation.CommandTypes]::Cmdlet,
				$PSBoundParameters
			)
			$dynamicParams = @(
				$targetCmd.Parameters.GetEnumerator() | Microsoft.PowerShell.Core\Where-Object { $_.Value.IsDynamic }
			)
			if ($dynamicParams.Length -gt 0) {
				$paramDictionary = [Management.Automation.RuntimeDefinedParameterDictionary]::new()
				foreach ($param in $dynamicParams) {
					$param = $param.Value

					if (-not $MyInvocation.MyCommand.Parameters.ContainsKey($param.Name)) {
						$dynParam = [Management.Automation.RuntimeDefinedParameter]::new(
							$param.Name,
							$param.ParameterType,
							$param.Attributes
						)
						$paramDictionary.Add($param.Name, $dynParam)
					}
				}

				return $paramDictionary
			}
		} catch {
			throw
		}
	}

	begin {
		try {
			$outBuffer = $null
			if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
				$PSBoundParameters['OutBuffer'] = 1
			}

			if ($IsLinux) {
				$matchParams = @{
					Pattern    = $script:DriveRegex
					AllMatches = $true
				}
				switch ($PsCmdlet.ParameterSetName) {
					'Path' {
						$matchParams.Add('InputObject', $Path)
						$ReplacePath = $Path
					}
					'LiteralPath' {
						$matchParams.Add('InputObject', $LiteralPath)
						$ReplacePath = $LiteralPath
					}
					Default { break }
				}

				$driveMatches = (Select-String @matchParams).Matches.Groups
					| Where-Object { $_.Name -in $script:WindowsDrives.driveName }

				foreach ($group in $driveMatches) {
					$Drive = $script:WindowsDrives | Where-Object { $group.Name -eq $_.driveName }
					$replacedText = $ReplacePath -Replace "^$($Drive.escapedDrive)", "/mnt/$($Drive.nakedDrive)/"
					$PSBoundParameters[$PsCmdlet.ParameterSetName] = $replacedText
				}
			}

			$wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand(
				'Microsoft.PowerShell.Management\Set-Location',
				[System.Management.Automation.CommandTypes]::Cmdlet
			)
			$scriptCmd = { & $wrappedCmd @PSBoundParameters }

			$steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
			$steppablePipeline.Begin($PSCmdlet)
		} catch {
			throw
		}
	}

	process {
		try {
			$steppablePipeline.Process($_)
		} catch {
			throw
		}
	}

	end {
		try {
			$steppablePipeline.End()
		} catch {
			throw
		}
	}
<#
	.ForwardHelpTargetName Microsoft.PowerShell.Management\Set-Location
	.ForwardHelpCategory Cmdlet
#>
}


# Public Function:
Function Update-WindowsDrivesList {
	# Create/Update WindowsDrives module scope variable
	$script:WindowsDrives = Get-WindowsFileSystemDrives
	$script:DriveRegex = New-WindowsDriveRegex $script:WindowsDrives
}


# Private Function:
Function New-WindowsDriveRegex {
	Param(
		[Parameter(Mandatory, Position = 0)]
		[PSCustomObject]$winDrives
	)
	$result = ''
	Foreach ($Drive in $winDrives) {
		$result += "(?<$($Drive.driveName)>$($Drive.escapedDrive))|"
	}
	return $result.TrimEnd('|')
}


# Private Function:
Function Get-WindowsFileSystemDrives {
	$result = [System.Collections.Generic.List[PSCustomObject]]::New()
	$defaultInstallPath = '/mnt/c/Program Files/PowerShell/7/pwsh.exe'

	# Try to find the windows pwsh instance.
	$wslMappedWinPwshPath = if (Test-Path -Path $defaultInstallPath -PathType Leaf) {
		$defaultInstallPath
	} else {
		$WherePath = '/mnt/c/Windows/system32/where.exe'
		if (Test-Path -Path $WherePath -PathType Leaf) {
			$WindowsPwshPath = (& $WherePath 'pwsh')
			$Disk = ($WindowsPwshPath -match ':') ? $WindowsPwshPath.Split(':')[0].ToLower() : $null

			if ([String]::IsNullOrWhiteSpace($Disk) -eq $false) {
				Join-Path -Path '/mnt' -ChildPath $Disk $WindowsPwshPath.Split(':')[1]
			} elseif ($WindowsPwshPath.StartsWith('\\')) {
				$WindowsPwshPath.Replace('\', '/')
			}
		}
	}

	# If we can't find windows pwsh then giveup.
	if ([string]::IsNullOrWhiteSpace($wslMappedWinPwshPath)) { return $result }

	# Call out to windows pwsh and correlate drives.
	$mntPoints = Get-ChildItem '/mnt' -Directory -Exclude 'wsl' | Select-Object -ExpandProperty Name
	$PwshCmd =
		'Get-PSDrive -PSProvider FileSystem ' +
		'| Where-Object {$_.Name -ine ''Temp''} ' +
		'| ForEach-Object { @{ Name = $_.Name ; Root = Select-Object -InputObject $_ -ExpandProperty Root } } ' +
		'| ConvertTo-Json -compress'
	$WinPSDrives = & $wslMappedWinPwshPath -c $PwshCmd | ConvertFrom-Json
	Foreach ($Drive in $WinPSDrives) {
		$WinDrive = [PSCustomObject]@{
			driveName    = $Drive.Name
			nakedDrive   = $Drive.Root.Replace(':\', '').ToLower()
			escapedDrive = $Drive.Root.Replace('\', '\\')
		}
		if ($mntPoints.Contains($WinDrive.nakedDrive)) {
			$result.Add($WinDrive)
		}
	}

	return $result
}


# Module Import Steps:
Update-WindowsDrivesList
New-Alias -Name 'Set-Location' -Value 'Set-LocationWSLOverride'
Export-ModuleMember 'Set-LocationWSLOverride', 'Update-WindowsDrivesList' -Alias '*' # Export the public function
