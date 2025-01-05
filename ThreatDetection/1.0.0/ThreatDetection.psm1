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

.OUTPUTS
    System.String
        Returns the result from the Python script or an error message if execution fails.

.NOTES
    Requires: MicromambaTools PowerShell module available at https://github.com/zhazhalove/MicromambaTools

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

        try {
            # Validate input - throws exception if fails
            Test-InputMessage -InputMessage $InputMessage
        }
        catch {
            $InputMessage = Remove-UnsafeString -InputString $InputMessage
        }

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
    Executes a Python script in a specified micromamba environment, passing specific parameters and retrieving results.

.DESCRIPTION
    The `Invoke-THDScoreRunOnly` function facilitates executing a Python script using a specified micromamba environment. 
    It supports loading environment variables from a dotenv file, validates the input message, and passes parameters
    such as model temperature, model name, and maximum retries to the script. The function returns the output of the
    Python script or an appropriate error message if execution fails.

.PARAMETER InputMessage
    The input message to be processed. This is a mandatory parameter.

.PARAMETER Script
    The path to the Python script to execute. This is a mandatory parameter.

.PARAMETER MicromambaEnvName
    The micromamba environment to use for executing the Python script. Defaults to `langchain`.

.PARAMETER MAMBA_ROOT_PREFIX
    The root prefix path for micromamba. Defaults to `$env:APPDATA\micromamba`.

.PARAMETER DotEnvPath
    The path to a dotenv file containing environment variables to be loaded into the runtime. Optional.

.PARAMETER Temperature
    The temperature value for the LLM. Affects the randomness of the model's output. Defaults to `0.0`.

.PARAMETER ModelName
    The LLM model to be used. Defaults to `gpt-4o-mini`.

.PARAMETER MaxRetries
    The maximum number of retries for the LLM. Defaults to `3`.

.OUTPUTS
    System.String
        Returns the result from the Python script or an error message if execution fails.

.NOTES
    Requires: MicromambaTools PowerShell module available at https://github.com/zhazhalove/MicromambaTools

.EXAMPLE
    Invoke-THDScoreRunOnly -InputMessage "Process this text." -Script "C:\Scripts\run_model.py"

    Executes the `run_model.py` script in the `langchain` micromamba environment, passing the input message
    and default parameters for temperature, model name, and retries.

.EXAMPLE
    Invoke-THDScoreRunOnly -InputMessage "Analyze this data." -Script "C:\Scripts\analyze.py" -Temperature 0.7 -ModelName "gpt-3.5-turbo"

    Executes the `analyze.py` script with a higher temperature setting and a different model name in the `langchain` environment.

.EXAMPLE
    Invoke-THDScoreRunOnly -InputMessage "Check this." -Script "C:\Scripts\check.py" -DotEnvPath "C:\env\settings.env" -MicromambaEnvName "custom-env"

    Executes the `check.py` script with environment variables loaded from a dotenv file and using the `custom-env` micromamba environment.

#>
function Invoke-THDScoreRunOnly {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Input Message")]
        [string]$InputMessage,

        [Parameter(Mandatory = $true, HelpMessage = "Path to the Python script to execute.")]
        [string]$Script,

        [Parameter(Mandatory = $false, HelpMessage = "The micromamba environment to use. Defaults to `langchain`.")]
        [string]$MicromambaEnvName = "langchain",

        [Parameter(Mandatory = $false, HelpMessage = "The micromamba root prefix to use. Defaults to `$env:APPDATA\micromamba.")]
        [string]$MAMBA_ROOT_PREFIX = "$env:APPDATA\micromamba",

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

        # Set MAMBA_ROOT_PREFIX environment variable
        Initialize-MambaRootPrefix -MAMBA_ROOT_PREFIX $MAMBA_ROOT_PREFIX

        if (Test-MicromambaEnvironment -EnvName $MicromambaEnvName) {

            if ($null -ne $DotEnvPath) {
                # Load .env variables into the PowerShell runtime
                Import-DotEnv -EnvFilePath $DotEnvPath | Out-Null
            }
    
            # Validate input - throws exception if fails
            # Test-InputMessage -InputMessage $InputMessage
            
            try {
                # Validate input - throws exception if fails
                Test-InputMessage -InputMessage $InputMessage
            }
            catch {
                $InputMessage = Remove-UnsafeString -InputString $InputMessage
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
        }
    }
    catch {
        throw [System.Exception]::new("Error in Invoke-THDScore: $($_.Exception.Message)", $_.Exception)
    }
}

<#
.SYNOPSIS
    Function to build a micromamba environment.

.DESCRIPTION
    This function sets up the micromamba environment, including specifying the Python version
    and installing required packages.

.PARAMETER PythonVersion
    The Python version to use within the micromamba environment. Defaults to 3.11.

.PARAMETER MicromambaEnvName
    The name of the micromamba environment to create. Defaults to "langchain".

.PARAMETER MAMBA_ROOT_PREFIX
    The root prefix for the micromamba environment. Defaults to `$env:APPDATA\micromamba`.

.PARAMETER Packages
    A string[] list of additional Python packages to install into the micromamba environment.

.OUTPUTS
    [bool]
        Returns $true for successful build and $false for failed build

.NOTES
    Requires: MicromambaTools PowerShell module available at https://github.com/zhazhalove/MicromambaTools

.EXAMPLE
    New-THDScoreMicromambaEnv -MicromambaEnvName "myenv" -PythonVersion "3.10" -Packages @("numpy", "pandas")
#>
function New-THDScoreMicromambaEnv {
    param (
        [Parameter(Mandatory = $false, HelpMessage = "The Python version to use within the micromamba environment. Defaults to 3.11.")]
        [string]$PythonVersion = "3.11",

        [Parameter(Mandatory = $false, HelpMessage = "The name of the micromamba environment to create. Defaults to `langchain`.")]
        [string]$MicromambaEnvName = "langchain",

        [Parameter(Mandatory = $false, HelpMessage = "The micromamba root prefix to use. Defaults to `$env:APPDATA\micromamba`.")]
        [string]$MAMBA_ROOT_PREFIX = "$env:APPDATA\micromamba",

        [Parameter(Mandatory = $false, HelpMessage = "Additional Python packages to install into the micromamba environment.")]
        [string[]]$Packages
    )

    try {
        # Set MAMBA_ROOT_PREFIX environment variable
        Initialize-MambaRootPrefix -MAMBA_ROOT_PREFIX $MAMBA_ROOT_PREFIX

        # Download micromamba
        if ( -not (Test-Path -Path "$MAMBA_ROOT_PREFIX\micromamba.exe") ) {

            if (-not (Get-MicromambaBinary)) {
                throw [System.Exception]::new("FAIL - Download micromamba")
            }
        }

        # Create the micromamba environment
        if (-not (Test-MicromambaEnvironment -EnvName $MicromambaEnvName) ) {

            if (-not (New-MicromambaEnvironment -EnvName $MicromambaEnvName -PythonVersion $PythonVersion)) {
                throw [System.Exception]::new("FAIL - Create micromamba environment - $MicromambaEnvName")
            }

            # Check if Packages parameter is provided
            if ($null -ne $Packages -and $Packages.Count -gt 0) {
                # Install packages
                $PkgResults = Install-PackagesInMicromambaEnvironment -EnvName $MicromambaEnvName -Packages $Packages

                foreach ($result in $PkgResults) {
                    if (-not $result["Success"]) {
                        throw [System.Exception]::new("Package installation failed: $($result["PackageName"])")
                    }
                }
            }

            if ( (Test-MicromambaEnvironment -EnvName $MicromambaEnvName) ) {
                return $true
            }
            else {
                throw [System.Exception]::new("Test-MicromambaEnvironment failed!")
            }
        }
        else {
            return $true
        }
    } catch {
        throw [System.Exception]::new("Error in New-THDScoreMicromambaEnv: $($_.Exception.Message)", $_.Exception)
    }
}

<#
.SYNOPSIS
    Removes a specified micromamba environment.

.DESCRIPTION
    This function deletes a micromamba environment and cleans up related resources. It ensures that the specified environment is removed completely.

.PARAMETER MicromambaEnvName
    The name of the micromamba environment to remove. Defaults to "langchain".

.PARAMETER MAMBA_ROOT_PREFIX
    The root prefix for the micromamba environment. Defaults to `$env:APPDATA\micromamba`.

.OUTPUTS
    System.Boolean
        Returns $true if the environment was removed successfully, $false otherwise.

.EXAMPLE
    Remove-THDScoreMicromambaEnv -MicromambaEnvName "myenv"

.EXAMPLE
    Remove-THDScoreMicromambaEnv -MicromambaEnvName "testenv" -MAMBA_ROOT_PREFIX "C:\\micromamba"

.NOTES
    Requires: MicromambaTools PowerShell module available at https://github.com/zhazhalove/MicromambaTools
#>

function Remove-THDScoreMicromambaEnv {

    param (
        [Parameter(Mandatory = $false, HelpMessage = "The micromamba environment to remove. Defaults to 'langchain'.")]
        [string]$MicromambaEnvName = "langchain",

        [Parameter(Mandatory = $false, HelpMessage = "The root prefix for the micromamba environment. Defaults to `$env:APPDATA\\micromamba`.")]
        [string]$MAMBA_ROOT_PREFIX = "$env:APPDATA\micromamba"
    )

    try {
        # Set MAMBA_ROOT_PREFIX environment variable
        Initialize-MambaRootPrefix -MAMBA_ROOT_PREFIX $MAMBA_ROOT_PREFIX

        # Check if the environment exists
        if (-not (Test-MicromambaEnvironment -EnvName $MicromambaEnvName)) {
            throw [System.Exception]::new("Environment '$MicromambaEnvName' does not exist.")
        }

        # Remove the micromamba environment
        if (-not (Remove-MicromambaEnvironment -EnvName $MicromambaEnvName)) {
            throw [System.Exception]::new("Failed to remove micromamba environment '$MicromambaEnvName'.")
        }

        # Remove micromamba binary
        if (-not (Remove-Micromamba)) {
            throw [System.Exception]::new("Failed to remove micromamba binary.")
        }

        return $true
    } catch {
        throw [System.Exception]::new("Error in Remove-THDScoreMicromambaEnv: $($_.Exception.Message)", $_.Exception)
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

<#
.SYNOPSIS
    Sanitizes the input string to remove unsafe characters and ensures it adheres to safe standards.

.DESCRIPTION
    The Remove-UnsafeString function validates the input string, checks for unsafe characters, and removes them.
    If violations are found, they are logged or thrown as errors.

.PARAMETER InputString
    The string to sanitize.

.EXAMPLE
    Remove-UnsafeString -InputString "Hello, World!"

    Returns: "Hello, World!"

.EXAMPLE
    Remove-UnsafeString -InputString "Hello <script>"

    Returns: "Hello"

#>
function Remove-UnsafeString {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputString
    )

    # Validate the input using Test-InputMessage
    try {
        Test-InputMessage -InputMessage $InputString
    } catch {
        Write-Verbose "Input validation failed: $_"
        # Sanitize the string by removing unsafe characters
        $sanitizedString = $InputString -replace '[^a-zA-Z0-9\s\.,\-_]', ''
        return $sanitizedString
    }

    # Return the input if it is valid
    return $InputString
}


Export-ModuleMember -Function Remove-UnsafeString, Remove-THDScoreMicromambaEnv, New-THDScoreMicromambaEnv, Invoke-THDScoreRunOnly, Invoke-THDScore, Test-InputMessage