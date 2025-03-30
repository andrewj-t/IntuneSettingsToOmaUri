Import-Module D:\git\IntuneSettingsToOmaUri\IntuneSettingsToOmaUri.psm1 -Force

# Export from IntuneManagement
Convert-IntuneSettingsToOmaUri -Path '.\exports\Microsoft 365 Apps for Enterprise Security Baseline.json' -OutputPath '.\output\Microsoft_365_Apps_for_Enterprise_Security_Baseline.json'
Convert-IntuneSettingsToOmaUri -Path '.\exports\Security Baseline for Windows 10 and later.json' -OutputPath '.\output\Security_Baseline_for_Windows_10_and_later.json'

return
Convert-IntuneSettingsToOmaUri -Path '.\exports\ASD Windows Hardening Guidelines.json' -OutputPath '.\output\ASD_Windows_Hardening_Guidelines.json'
Convert-IntuneSettingsToOmaUri -Path '.\exports\Win - OIB - SC - Internet Explorer (Legacy) - D - Security - v3.1.1.json' -OutputPath '.\output\Win_IE_Legacy_Security_v3.1.1.json'
Convert-IntuneSettingsToOmaUri -Path '.\exports\Win - OIB - SC - Device Security - D - Security Hardening - v3.5.json' -OutputPath '.\output\Win_Device_Security_Hardening_v3.5.json'
Convert-IntuneSettingsToOmaUri -Path '.\exports\Win - OIB - ES - Attack Surface Reduction - D - ASR Rules (L2) - v3.3.json' -OutputPath '.\output\Win_ASR_Rules_L2_v3.3.json'


#Export-SettingsCatalogAsOmiUri -SettingsCatalogId "028a4f25-6383-4067-9485-1bf63535aa1c" #-OutputPath '.\output\ASD_Edge_Hardening_Guidelines.json'
