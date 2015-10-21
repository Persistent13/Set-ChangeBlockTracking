function Enable-ChangeBlockTracking
{
    <#
    .Synopsis
       Enables change block tracking on a list of VMs.
    .DESCRIPTION
       Enables change block tracking on a list of VMs and then stuns/un-stuns the VM with a snapshot to apply the change.
    .EXAMPLE
       Enable-ChangeBlockTracking -VM 2012r2

       This command will enable change block tracking for all disks attached to the virutal machine and then take a
       snapshot and remove it immediately after in order to apply the configuration changes during the stun period.
    .EXAMPLE
       PS C:\>Enable-ChangeBlockTracking -VM 2012r2, "ubuntu 15.04"

       This command will enable change block tracking on the list of virtual machines.
       An string array may be used as well.
    .INPUTS
       System.String

            You can pipe a string the contains a virtual machine name to Enable-ChangeBlockTracking
    .OUTPUTS
       None
    .NOTES
       Snapshots created by the cmdlet are prefixed with cbt- and end with a timestamp.
       E.G. cbt-2015-10-21T14:23:50.6819207-07:00
    #>
    [CmdletBinding()]
    [Alias()]
    [OutputType()]
    #Requires -Modules VMware.VimAutomation.Core
    Param
    (
        # Name of the virtual machines.
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [String[]]$Name
    )

    Begin
    {
        $vmConfig = New-Object VMware.Vim.VirtualMachineConfigSpec
        $vmConfig.ChangeTrackingEnabled = $true
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
                New-Snapshot -VM $workingVM.Name -Name $snapshotName | Out-Null
                Get-Snapshot -VM $workingVM.Name -Name $snapshotName | Remove-Snapshot -Confirm:$false
            }
            catch
            {
                Write-Warning "Could not find the virtual machine $targetVM."
            }
        }
    }
    End
    {
        Write-Verbose "the end."
    }
}