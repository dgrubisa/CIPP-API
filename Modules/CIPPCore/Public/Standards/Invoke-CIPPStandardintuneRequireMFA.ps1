function Invoke-CIPPStandardintuneRequireMFA {
    <#
    .FUNCTIONALITY
        Internal
    .COMPONENT
        (APIName) intuneRequireMFA
    .SYNOPSIS
        (Label) Require Multi-factor Authentication to register or join devices with Microsoft Entra
    .DESCRIPTION
        (Helptext) Requires MFA for all users to register devices with Intune. This is useful when not using Conditional Access.
        (DocsDescription) Requires MFA for all users to register devices with Intune. This is useful when not using Conditional Access.
    .NOTES
        CAT
            Intune Standards
        TAG
        IMPACT
            Medium Impact
        ADDEDDATE
            2023-10-23
        POWERSHELLEQUIVALENT
            Update-MgBetaPolicyDeviceRegistrationPolicy
        RECOMMENDEDBY
        UPDATECOMMENTBLOCK
            Run the Tools\Update-StandardsComments.ps1 script to update this comment block
    .LINK
        https://docs.cipp.app/user-documentation/tenant/standards/list-standards
    #>

    param($Tenant, $Settings)
    $TestResult = Test-CIPPStandardLicense -StandardName 'intuneRequireMFA' -TenantFilter $Tenant -RequiredCapabilities @('INTUNE_A', 'MDM_Services', 'EMS', 'SCCM', 'MICROSOFTINTUNEPLAN1')
    ##$Rerun -Type Standard -Tenant $Tenant -Settings $Settings 'intuneRequireMFA'

    if ($TestResult -eq $false) {
        Write-Host "We're exiting as the correct license is not present for this standard."
        return $true
    } #we're done.

    try {
        $PreviousSetting = New-GraphGetRequest -uri 'https://graph.microsoft.com/beta/policies/deviceRegistrationPolicy' -tenantid $Tenant
    }
    catch {
        $ErrorMessage = Get-NormalizedError -Message $_.Exception.Message
        Write-LogMessage -API 'Standards' -Tenant $Tenant -Message "Could not get the intuneRequireMFA state for $Tenant. Error: $ErrorMessage" -Sev Error
        return
    }

    If ($Settings.remediate -eq $true) {
        if ($PreviousSetting.multiFactorAuthConfiguration -eq 'required') {
            Write-LogMessage -API 'Standards' -tenant $tenant -message 'Require to use MFA when joining/registering Entra Devices is already enabled.' -sev Info
        } else {
            try {
                $NewSetting = $PreviousSetting
                $NewSetting.multiFactorAuthConfiguration = 'required'
                $NewBody = ConvertTo-Json -Compress -InputObject $NewSetting -Depth 10
                New-GraphPostRequest -tenantid $tenant -Uri 'https://graph.microsoft.com/beta/policies/deviceRegistrationPolicy' -Type PUT -Body $NewBody -ContentType 'application/json'
                Write-LogMessage -API 'Standards' -tenant $tenant -message 'Set required to use MFA when joining/registering Entra Devices' -sev Info
            } catch {
                $ErrorMessage = Get-NormalizedError -Message $_.Exception.Message
                Write-LogMessage -API 'Standards' -tenant $tenant -message "Failed to set require to use MFA when joining/registering Entra Devices: $ErrorMessage" -sev Error
            }
        }
    }

    if ($Settings.alert -eq $true) {

        if ($PreviousSetting.multiFactorAuthConfiguration -eq 'required') {
            Write-LogMessage -API 'Standards' -tenant $tenant -message 'Require to use MFA when joining/registering Entra Devices is enabled.' -sev Info
        } else {
            Write-StandardsAlert -message 'Require to use MFA when joining/registering Entra Devices is not enabled' -object $PreviousSetting -tenant $tenant -standardName 'intuneRequireMFA' -standardId $Settings.standardId
            Write-LogMessage -API 'Standards' -tenant $tenant -message 'Require to use MFA when joining/registering Entra Devices is not enabled.' -sev Info
        }
    }

    if ($Settings.report -eq $true) {
        $RequireMFA = if ($PreviousSetting.multiFactorAuthConfiguration -eq 'required') { $true } else { $false }
        Set-CIPPStandardsCompareField -FieldName 'standards.intuneRequireMFA' -FieldValue $RequireMFA -Tenant $tenant
        Add-CIPPBPAField -FieldName 'intuneRequireMFA' -FieldValue $RequireMFA -StoreAs bool -Tenant $tenant
    }
}
