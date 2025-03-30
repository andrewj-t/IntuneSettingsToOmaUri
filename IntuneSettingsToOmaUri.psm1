$ErrorActionPreference = 'Stop'

# Update to path of local copy of https://github.com/pl4nty/intune-change-tracking
$DCv2SettingsRoot = 'D:\git\intune-change-tracking\DCv2\Settings'

function Convert-IntuneSettingsToOmaUri {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )

    $IntuneExportFromJson = Get-Content $Path | ConvertFrom-Json

    $Settings = @()
    foreach ($SettingInstance in $IntuneExportFromJson.Settings.settingInstance) {
        $Settings += Convert-SettingInstance -DCv2SettingInstance $SettingInstance -DCv2SettingsRoot $DCv2SettingsRoot
    }

    $result = $Settings

    if ($OutputPath) {
        $result | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
    } else {
        $result
    }
}

function Export-SettingsCatalogAsOmiUri {
    param (
        [string]$SettingsCatalogId,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )

    $ObjectId = $SettingsCatalogId
    $SettingsCatalogPolicy = Invoke-GraphRequest -Method GET -Uri "beta/deviceManagement/configurationPolicies/$ObjectId"
    Write-Host "Processing Policy: $($SettingsCatalogPolicy.name)"
    $SettingsCatalogPolicySettings = (Invoke-GraphRequest -Method GET -Uri "beta/deviceManagement/configurationPolicies/$ObjectId/settings").Value

    $Settings = @()
    foreach ($PolicySetting in $SettingsCatalogPolicySettings) {
        $Settings += Convert-SettingInstance -DCv2SettingInstance $PolicySetting.settingInstance -DCv2SettingsRoot $DCv2SettingsRoot
    }

    $result = $Settings

    if ($OutputPath) {
        $result | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
    } else {
        $result
    }
}

function Convert-SettingInstance {
    param (
        [Parameter(Mandatory)]
        [object]$DCv2SettingInstance,

        [Parameter(Mandatory)]
        [string]$DCv2SettingsRoot
    )

    $SettingConfigFileName = $DCv2SettingInstance.settingDefinitionId + '.json'
    $SettingConfigFilePath = Join-Path -Path $DCv2SettingsRoot -ChildPath $SettingConfigFileName

    if (-not (Test-Path $SettingConfigFilePath)) {
        Write-Warning "Could not find $SettingConfigFileName"
        return $null
    }

    try {
        $SettingDefinition = Get-Content $SettingConfigFilePath | ConvertFrom-Json
    } catch {
        Write-Error "Failed to parse JSON for $SettingConfigFilePath. Error: $_"
        return $null
    }

    $OmaUri = $SettingDefinition.baseUri + $SettingDefinition.offsetUri
    $InstanceType = $DCv2SettingInstance.'@odata.type'

    switch ($InstanceType) {
        "#microsoft.graph.deviceManagementConfigurationChoiceSettingInstance" {
            $SelectedOption = $SettingDefinition.options | Where-Object { $_.itemId -eq $DCv2SettingInstance.choiceSettingValue.value }
            if ($null -eq $SelectedOption) {
                Write-Warning "No matching option found for ChoiceSettingValue: $($DCv2SettingInstance.choiceSettingValue.value)"
                $SettingValue = $null
            } else {
                $SettingValue = $SelectedOption.optionValue.value
            }
        }
        "#microsoft.graph.deviceManagementConfigurationSimpleSettingInstance" {
            $SettingValue = $DCv2SettingInstance.simpleSettingValue.value
        }
        "#microsoft.graph.deviceManagementConfigurationSimpleSettingCollectionInstance" {
            $SettingValue = @($DCv2SettingInstance.simpleSettingCollectionValue.value)
        }
        "#microsoft.graph.deviceManagementConfigurationGroupSettingCollectionInstance" {
            $AllValues = @()
            foreach ($Child in $DCv2SettingInstance.groupSettingCollectionValue.children) {
                $SettingValueDefDefinitionFileName = $Child.settingDefinitionId + '.json'
                $SettingValueDefDefinitionFilePath = Join-Path -Path $DCv2SettingsRoot -ChildPath $SettingValueDefDefinitionFileName

                if (-not (Test-Path $SettingValueDefDefinitionFilePath)) {
                    Write-Warning "Could not find definition file: $SettingValueDefDefinitionFilePath"
                    continue
                }

                try {
                    $SettingValueDefinition = Get-Content -Path $SettingValueDefDefinitionFilePath | ConvertFrom-Json
                    $ChoiceSettingValue = $SettingValueDefinition.options | Where-Object { $_.itemId -eq $Child.choiceSettingValue.value }
                    if ($null -eq $ChoiceSettingValue) {
                        Write-Warning "No matching option found for ChoiceSettingValue: $($Child.choiceSettingValue.value)"
                        continue
                    }
                    $AllValues += $ChoiceSettingValue.optionValue.value
                } catch {
                    Write-Error "Failed to process definition file: $SettingValueDefDefinitionFilePath. Error: $_"
                    continue
                }
            }
            $SettingValue = $AllValues
        }
        default {
            Write-Warning "Unknown instance type: $InstanceType"
            $SettingValue = $null
        }
    }

    return [PSCustomObject]@{
        OmaUri        = $OmaUri
        Value         = $SettingValue
    }
}