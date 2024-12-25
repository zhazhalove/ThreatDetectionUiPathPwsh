# Threat Detection Score

## Overview

This project provides PowerShell functions `Invoke-THDScore` and `Invoke-THDScoreRunOnly` to orchestrate the validation of the micromamba environment and execute Python scripts for Threat Detection Scoring.

## Dependencies

- **Requires**: MicromambaTools PowerShell module available at https://github.com/zhazhalove/MicromambaTools

## Functions

### Invoke-THDScore

#### Synopsis

Main function to invoke Threat Detection Score.

#### Description

This function orchestrates the validation of the micromamba environment and executes the Python script for Threat Detection Scoring.

#### Parameters

- **InputMessage**: The input message to pass to the Python script. (Mandatory)
- **Script**: Path to the Python script to execute. (Mandatory)
- **PythonVersion**: The Python version to use within the micromamba environment. Defaults to 3.11. (Optional)
- **MicromambaEnvName**: The micromamba environment to use. Defaults to "langchain". (Optional)
- **MAMBA_ROOT_PREFIX**: The root prefix for the micromamba environment. Defaults to `$env:APPDATA`. (Optional)
- **Packages**: A string[] list of additional python packages to install into the micromamba environment. (Optional)
- **DotEnvPath**: Path to dotenv file containing environment variables to load into the runtime (Optional)
- **Temperature**: The temperature of the LLM. Defaults to 0.0 (Optional)
- **ModelName**: The LLM model used. Defaults to "gpt-4o-mini" (Optional)
- **MaxRetries**: The maximum number of retries for the LLM. Defaults to 3 (Optional)

#### Examples

```powershell
Invoke-THDScore -InputMessage "Sample input message" -Script "path\to\script.py"

Invoke-THDScore -InputMessage "Sample input message" -Script "path\to\script.py" -PythonVersion "3.10"

Invoke-THDScore -InputMessage "Sample input message" -Script "path\to\script.py" -PythonVersion "3.10" -Packages @("numpy", "pandas", "matplotlib")

Invoke-THDScore -InputMessage "Sample input message" -Script "path\to\script.py" -PythonVersion "3.10" -Packages @("numpy", "pandas", "matplotlib") -DotEnvPath "\some\path\.env"

Invoke-THDScore -Script "python_app" -PythonVersion "3.11" -MicromambaEnvName "langchain" -MAMBA_ROOT_PREFIX "\some\path\langchain" -Packages @("threat_detection_score_py_package") -DotEnvPath "C:\some\path.env" -Temperature 0.0 -ModelName "gpt-4o-mini" -MaxRetries 1 -InputMessage "some text"
```

### Invoke-THDScoreRunOnly

#### Synopsis

Executes a Python script in a specified micromamba environment, passing specific parameters and retrieving results.

#### Description

This function facilitates executing a Python script using a specified micromamba environment. It supports loading environment variables from a dotenv file, validates the input message, and passes parameters such as model temperature, model name, and maximum retries to the script. The function returns the output of the Python script or an appropriate error message if execution fails.

#### Parameters

- **InputMessage**: The input message to be processed. (Mandatory)
- **Script**: The path to the Python script to execute. (Mandatory)
- **MicromambaEnvName**: The micromamba environment to use for executing the Python script. Defaults to `langchain`. (Optional)
- **MAMBA_ROOT_PREFIX**: The root prefix path for micromamba. Defaults to `$env:APPDATA\micromamba`. (Optional)
- **DotEnvPath**: The path to a dotenv file containing environment variables to be loaded into the runtime. (Optional)
- **Temperature**: The temperature value for the LLM. Affects the randomness of the model's output. Defaults to `0.0`. (Optional)
- **ModelName**: The LLM model to be used. Defaults to `gpt-4o-mini`. (Optional)
- **MaxRetries**: The maximum number of retries for the LLM. Defaults to `3`. (Optional)

#### Examples

```powershell
Invoke-THDScoreRunOnly -InputMessage "Process this text." -Script "C:\Scripts\run_model.py"

Invoke-THDScoreRunOnly -InputMessage "Analyze this data." -Script "C:\Scripts\analyze.py" -Temperature 0.7 -ModelName "gpt-3.5-turbo"

Invoke-THDScoreRunOnly -InputMessage "Check this." -Script "C:\Scripts\check.py" -DotEnvPath "C:\env\settings.env" -MicromambaEnvName "custom-env"
```

### Test-InputMessage

#### Synopsis

Validates and sanitizes the input message to prevent injection attacks.

#### Parameters

- **InputMessage**: The input message to validate and sanitize. (Mandatory)

#### Examples

```powershell
Test-InputMessage -InputMessage "Sample input"
```

## Usage

1. **Validate Input**: The `Test-InputMessage` function checks if the input message is valid.
2. **Initialize Environment**: The `Invoke-THDScore` and `Invoke-THDScoreRunOnly` functions set up the micromamba environment.
3. **Execute Script**: The Python script is executed within the micromamba environment.
4. **Cleanup**: The micromamba environment is removed after execution.

## Error Handling

Both functions include error handling to manage exceptions during the process, ensuring that the environment is cleaned up even if an error occurs.

## License

This project is licensed under the MIT License.
