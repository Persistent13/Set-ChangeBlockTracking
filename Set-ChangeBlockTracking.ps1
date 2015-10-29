function Set-ChangeBlockTracking
{
    <#
    .Synopsis
       Enables change block tracking on a list of virtual machines.
    .DESCRIPTION
       Enables change block tracking on a list of virtual machines and then stuns/un-stuns the virtual machines
       with a snapshot to apply the change.
    .EXAMPLE
       Set-ChangeBlockTracking -VM 2012r2

       This command will enable change block tracking for all disks attached to the virutal machine and then take a
       snapshot and remove it immediately after in order to apply the configuration changes during the stun period.
    .EXAMPLE
       PS C:\>Set-ChangeBlockTracking -VM 2012r2, "ubuntu 15.04", srv-ad03

       This command will enable change block tracking for the list of virtual machines.
       An string variable may be used as well.
    .EXAMPLE
       PS C:\>Set-ChangeBlockTracking -VM srv-ad* -ChangeTrackingEnable:$false

       This command will disable change block tracking for all virtual machines that start with the name srv-ad.
       A value of $true is default and will enable change block tracking, $false will disable change block tracking.
    .INPUTS
       System.String

            You can pipe a string the contains a virtual machine name to Set-ChangeBlockTracking.
    .OUTPUTS
       None
    .NOTES
       Snapshots created by the cmdlet are prefixed with cbt- and end with a timestamp.
       E.G. cbt-2015-10-21T14:23:50.6819207-07:00
    #>
    [CmdletBinding()]
    [Alias()]
    [OutputType()]
    #Requires -Version 3
    #Requires -Modules VMware.VimAutomation.Core
    Param
    (
        # Name of the virtual machines.
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ValueFromRemainingArguments=$false,
                   Position=0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String[]]$Name,
        # Whether to enable or disable change tracking.
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$false,
                   Position=1)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Bool]$ChangeTrackingEnable
    )

    Begin
    {
        if(-not (Get-Module vmware.*))
        {
            Write-Host 'PowerCLI 6+ must be installed to use this cmdlet.'
            exit 1
        }
        $vmConfig = New-Object VMware.Vim.VirtualMachineConfigSpec
        $vmConfig.ChangeTrackingEnabled = $ChangeTrackingEnable
    }
    Process
    {
        foreach($targetVM in $Name)
        {
            try
            {
                $workingVM = Get-VM -Name $targetVM -ErrorAction Stop | Get-View
                $workingVM.ReconfigVM($vmConfig)
                $snapshotName = "cbt-$(Get-Date -Format o)"
                New-Snapshot -VM $workingVM.Name -Name $snapshotName -WarningAction Ignore | Out-Null
                Get-Snapshot -VM $workingVM.Name -Name $snapshotName | Remove-Snapshot -Confirm:$false
                if(-not (Get-VM -Name $targetVM | Get-View).Config.ChangeTrackingEnabled -and $ChangeTrackingEnable)
                {
                    Write-Warning "Unable to change the change block tracking setting for $targetVM."
                }
            }
            catch
            {
                Write-Warning "Could not find the virtual machine $targetVM."
            }
        }
    }
    End
    {
    }
}