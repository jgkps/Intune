#Region the usual boiler plane
<#

you will need to us the AzureADPreview module to create the dynamic groups
Install-Module -Name AzureADPreview

and the graph to grab the device details
Install-Module -Name Microsoft.Graph.Intune

you will bump into issues if you have the regular azuread module installed

#>
#EndRegion


#Region Set group name prefix

# Example: this will result in a AAD group called "AAD Device OptiPlex 7050"
# note the intentional trailing space
$NamePrefix = "AAD Device "
#EndRegion


#Region Connect to the azure services


Connect-AzureAD
Connect-MSGraph

#EndRegion

#Region 
#EndRegion

# grabbing all the dell devices
$AllDellDevices = Get-IntuneManagedDevice | Where-Object { $_.manufacturer -eq "Dell Inc." } | Select-Object -Unique -ExpandProperty model



#Region create dynamic groups


foreach ($model in $AllDellDevices) {

    $Groupname = $NamePrefix + $Model

    # check if the group exists
    if ( (Get-AzureADMSGroup -SearchString $Groupname) -ne $null ) {

        Write-Output " $groupname already exists"

    }
    elseif ( (Get-AzureADMSGroup -SearchString $Groupname) -eq $null ) {

        Write-Output "$groupname does not exist, lets boogie!"

        $mailnickname = $model.replace(' ','')

        # we use splatting because we are cultured professionals
        $HashArgs = @{
            DisplayName                   = "$groupname"
            Description                   = "A Dynamic group that contains $model"
            MailEnabled                   = $False
            MailNickName                  = "$mailnickname"
            SecurityEnabled               = $True
            GroupTypes                    = "DynamicMembership"
            MembershipRule                = "(Device.deviceModel contains ""$model"")"
            MembershipRuleProcessingState = "On"
        }
        New-AzureADMSGroup @HashArgs
    }
}

#EndRegion