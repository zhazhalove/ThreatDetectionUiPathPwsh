# <#
# .SYNOPSIS
#     Main function to invoke Threat Detection Score.

# .DESCRIPTION
#     This function orchestrates the validation of the micromamba environment and executes the Python script for Threat Detection Scoring.

# .PARAMETER InputMessage
#     The input message to pass to the Python script.

# .PARAMETER Script
#     Path to the Python script to execute. This is a mandatory parameter.

# .PARAMETER PythonVersion
#     The Python version to use within the micromamba environment. Defaults to 3.11.

# .PARAMETER MicromambaEnvName
#     The micromamba environment to use. Defaults to "langchain".

# .PARAMETER MAMBA_ROOT_PREFIX
#     The root prefix for the micromamba environment. Defaults to `$env:APPDATA`.

# .PARAMETER Packages
#     A string[] list of additional python packages to install into the mircomamba environment.

#  .PARAMETER DotEnvPath     
#     A string path to dotenv file containing environment variables to load into the runtime

# .EXAMPLE
#     Invoke-THDScore -InputMessage "Sample input message" -Script "path\to\script.py"

# .EXAMPLE
#     Invoke-THDScore -InputMessage "Sample input message" -Script "path\to\script.py" -PythonVersion "3.10"

# .EXAMPLE
#     Invoke-THDScore -InputMessage "Sample input message" -Script "path\to\script.py" -PythonVersion "3.10" -Packages @("numpy", "pandas", "matplotlib")

# .EXAMPLE
#     Invoke-THDScore -InputMessage "Sample input message" -Script "path\to\script.py" -PythonVersion "3.10" -Packages @("numpy", "pandas", "matplotlib") -DotEnvPath "C:\some\file\.env"
# #>
# function Invoke-THDScore {
#     param (
#         [Parameter(Mandatory = $true, HelpMessage = "Input Message")]
#         [string]$InputMessage,

#         [Parameter(Mandatory = $true, HelpMessage = "Path to the Python script to execute.")]
#         [string]$Script,
        
#         [Parameter(Mandatory = $false, HelpMessage = "The Python version to use within the micromamba environment. Defaults to 3.11.")]
#         [string]$PythonVersion = "3.11",
        
#         [Parameter(Mandatory = $false, HelpMessage = "The micromamba environment to use. Defaults to `"langchain`".")]
#         [string]$MicromambaEnvName = "langchain",
        
#         [Parameter(Mandatory = $false, HelpMessage = "The micromamba root prefix to use. Defaults to `$env:APPDATA\micromamba.")]
#         [string]$MAMBA_ROOT_PREFIX = "$env:APPDATA\micromamba",

#         [Parameter(Mandatory = $false)]
#         [string[]]$Packages,

#         [Parameter(Mandatory = $false, HelpMessage = "Path to dotenv file containing environment variables to load into the runtime")]
#         [string]$DotEnvPath
#     )


#     try {


#         if ($null -ne $DotEnvPath ) {
#             # Load .env variables into the PowerShell runtime
#             Import-DotEnv -EnvFilePath $DotEnvPath | Out-Null
#         }

#         # Validate input - throws exception if fails
#         Test-InputMessage -InputMessage $InputMessage

#         # Set MAMBA_ROOT_PREFIX environment variable
#         Initialize-MambaRootPrefix -MAMBA_ROOT_PREFIX $MAMBA_ROOT_PREFIX

#         # Dowload micromamaba
#         if ( -not (Get-MicromambaBinary) ) {
#             throw [System.Exception]::new("FAIL - Download micromamba")
#         }
    
#         # Build micromamba environment
#         if ( -not (New-MicromambaEnvironment -EnvName $MicromambaEnvName -PythonVersion $PythonVersion) )
#         {
#             throw [System.Exception]::new("FAIL - Create micromamba environment - $MicromambaEnvName")
#         }

#         # Install micromamba environment python packages
#         $PkgResults = Install-PackagesInMicromambaEnvironment -EnvName $MicromambaEnvName -Packages $Packages

#         foreach($result in $PkgResults) {
#             if (-not $result["Success"]) {
#                 throw [System.Exception]::new("$($result["PackageName"]) $($result["Success"])")
#             }
#         }
        
#         # Execute the Python script
#         $thdResult = Invoke-PythonScript -ScriptPath $Script -EnvName $MicromambaEnvName -Arguments "-i $InputMessage"

#         if ($null -ne $thdResult) {
#             return $thdResult
#         } else {
#             return "Failed to retrieve result from the Python script."
#         }
#     }
#     catch {
#         throw [System.Exception]::new("Error in Invoke-THDScore: $($_.Exception.Message)", $_.Exception)
#     }
#     finally {
#         Remove-MicromambaEnvironment -EnvName $MicromambaEnvName | Out-Null
#         Remove-Micromamba | Out-Null
#     }
# }


<#
.SYNOPSIS
    Main function to invoke Threat Detection Score.

.DESCRIPTION
    This function orchestrates the validation of the micromamba environment and executes the Python script for Threat Detection Scoring.

.PARAMETER InputMessage
    The input message to pass to the Python script.

.PARAMETER Script
    Path to the Python script to execute. This is a mandatory parameter.

.PARAMETER PythonVersion
    The Python version to use within the micromamba environment. Defaults to 3.11.

.PARAMETER MicromambaEnvName
    The micromamba environment to use. Defaults to "langchain".

.PARAMETER MAMBA_ROOT_PREFIX
    The root prefix for the micromamba environment. Defaults to `$env:APPDATA`.

.PARAMETER Packages
    A string[] list of additional Python packages to install into the micromamba environment.

.PARAMETER DotEnvPath
    A string path to a dotenv file containing environment variables to load into the runtime.

.PARAMETER Temperature
    The temperature of the LLM. Defaults to 0.0.

.PARAMETER ModelName
    The LLM model used. Defaults to "gpt-4o-mini".

.PARAMETER MaxRetries
    The maximum number of retries for the LLM. Defaults to 3.

.EXAMPLE
    Invoke-THDScore -InputMessage "Sample input message" -Script "path\to\script.py"

.EXAMPLE
    Invoke-THDScore -InputMessage "Sample input message" -Script "path\to\script.py" -PythonVersion "3.10"

.EXAMPLE
    Invoke-THDScore -InputMessage "Sample input message" -Script "path\to\script.py" -PythonVersion "3.10" -Packages @("numpy", "pandas", "matplotlib")

.EXAMPLE
    Invoke-THDScore -InputMessage "Sample input message" -Script "path\to\script.py" -PythonVersion "3.10" -Packages @("numpy", "pandas", "matplotlib") -DotEnvPath "C:\some\file\.env"

.EXAMPLE
    Invoke-THDScore -InputMessage "Sample input message" -Script "path\to\script.py" -Temperature 0.7 -ModelName "gpt-4" -MaxRetries 5
#>
function Invoke-THDScore {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Input Message")]
        [string]$InputMessage,

        [Parameter(Mandatory = $true, HelpMessage = "Path to the Python script to execute.")]
        [string]$Script,

        [Parameter(Mandatory = $false, HelpMessage = "The Python version to use within the micromamba environment. Defaults to 3.11.")]
        [string]$PythonVersion = "3.11",

        [Parameter(Mandatory = $false, HelpMessage = "The micromamba environment to use. Defaults to `langchain`.")]
        [string]$MicromambaEnvName = "langchain",

        [Parameter(Mandatory = $false, HelpMessage = "The micromamba root prefix to use. Defaults to `$env:APPDATA\micromamba.")]
        [string]$MAMBA_ROOT_PREFIX = "$env:APPDATA\micromamba",

        [Parameter(Mandatory = $false)]
        [string[]]$Packages,

        [Parameter(Mandatory = $false, HelpMessage = "Path to dotenv file containing environment variables to load into the runtime")]
        [string]$DotEnvPath,

        [Parameter(Mandatory = $false, HelpMessage = "The temperature of the LLM. Defaults to 0.0.")]
        [float]$Temperature = 0.0,

        [Parameter(Mandatory = $false, HelpMessage = "The LLM model used. Defaults to 'gpt-4o-mini'.")]
        [string]$ModelName = "gpt-4o-mini",

        [Parameter(Mandatory = $false, HelpMessage = "The maximum number of retries for the LLM. Defaults to 3.")]
        [int]$MaxRetries = 3
    )

    try {

        if ($null -ne $DotEnvPath) {
            # Load .env variables into the PowerShell runtime
            Import-DotEnv -EnvFilePath $DotEnvPath | Out-Null
        }

        # Validate input - throws exception if fails
        Test-InputMessage -InputMessage $InputMessage

        # Set MAMBA_ROOT_PREFIX environment variable
        Initialize-MambaRootPrefix -MAMBA_ROOT_PREFIX $MAMBA_ROOT_PREFIX

        # Download micromamba
        if (-not (Get-MicromambaBinary)) {
            throw [System.Exception]::new("FAIL - Download micromamba")
        }

        # Build micromamba environment
        if (-not (New-MicromambaEnvironment -EnvName $MicromambaEnvName -PythonVersion $PythonVersion)) {
            throw [System.Exception]::new("FAIL - Create micromamba environment - $MicromambaEnvName")
        }

        # Check if Packages parameter is provided
        if ($null -ne $Packages -and $Packages.Count -gt 0) {

            # Install micromamba environment Python packages
            $PkgResults = Install-PackagesInMicromambaEnvironment -EnvName $MicromambaEnvName -Packages $Packages

            foreach ($result in $PkgResults) {

                if (-not $result["Success"]) {
                    throw [System.Exception]::new("$($result["PackageName"]) $($result["Success"])")
                }
            }
        }

        # Execute the Python script with new parameters
        $arguments = @(
            "-i", $InputMessage,
            "--temperature", $Temperature,
            "--model-name", $ModelName,
            "--max-retries", $MaxRetries
        )

        $thdResult = Invoke-PythonScript -ScriptPath $Script -EnvName $MicromambaEnvName -Arguments $arguments

        if ($null -ne $thdResult) {
            return $thdResult
        } else {
            return "Failed to retrieve result from the Python script."
        }
        
    } catch {
        throw [System.Exception]::new("Error in Invoke-THDScore: $($_.Exception.Message)", $_.Exception)
    } finally {
        Remove-MicromambaEnvironment -EnvName $MicromambaEnvName | Out-Null
        Remove-Micromamba | Out-Null
    }
}



<#
.SYNOPSIS
    Validates and sanitizes the input message to prevent injection attacks.

.PARAMETER InputMessage
    The input message to validate and sanitize.

.EXAMPLE
    Test-InputMessage -InputMessage "Sample input"
#>
function Test-InputMessage {
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputMessage
    )

    # Check if the input is null, empty, or whitespace
    if ([string]::IsNullOrWhiteSpace($InputMessage)) {
        throw [System.Exception]::new("InputMessage cannot be null, empty, or whitespace.")
    }

    # Allow only safe characters (alphanumeric, space, and limited punctuation)
    if ($InputMessage -notmatch '^[a-zA-Z0-9\s\.\,\-_]+$') {

        # Find invalid characters
        $invalidChars = ($InputMessage -split '') | Where-Object { $_ -notmatch '[a-zA-Z0-9\s\.\,\-_]' }
        $invalidCharsList = ($invalidChars -join ', ')
        throw [System.Exception]::new("InputMessage contains invalid characters: $invalidCharsList")
    }
}

Export-ModuleMember -Function Invoke-THDScore, Test-InputMessage
