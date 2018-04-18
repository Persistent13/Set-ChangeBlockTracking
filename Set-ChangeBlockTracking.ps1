function Set-ChangeBlockTracking {
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
       Snapshots created by the cmdlet are prefixed with cbt- and end with a GUID.
       E.G. cbt-78861abc-e46a-4404-921b-5d1458d09127
    #>
    [CmdletBinding(PositionalBinding=$true,SupportsShouldProcess=$true)]
    Param (
        # Name of the virtual machine(s).
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ValueFromRemainingArguments=$false)]
        [ValidateNotNullOrEmpty()]
        [String[]]$Name,
        # Whether to enable or disable change tracking.
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$false)]
        [ValidateNotNullOrEmpty()]
        [Bool]$ChangeTrackingEnable
    )

    Begin {
        $vmConfig = New-Object VMware.Vim.VirtualMachineConfigSpec
        $vmConfig.ChangeTrackingEnabled = $ChangeTrackingEnable
    }
    Process {
        foreach($targetVM in $Name) {
            if($PSCmdlet.ShouldProcess($targetVM, 'Take snapshot, enable change block tracking, and delete snapshot'))
            {
                try {
                    $workingVM = VMware.VimAutomation.Core\Get-VM -Name $targetVM -ErrorAction Stop | VMware.VimAutomation.Core\Get-View
                    $workingVM.ReconfigVM($vmConfig)
                    $snapshotName = 'cbt-{0}' -f [Guid]::NewGuid().Guid
                    VMware.VimAutomation.Core\New-Snapshot -VM $workingVM.Name -Name $snapshotName | Out-Null
                    VMware.VimAutomation.Core\Get-Snapshot -VM $workingVM.Name -Name $snapshotName | VMware.VimAutomation.Core\Remove-Snapshot -Confirm:$false
                    if(-not (Get-VM -Name $targetVM | Get-View).Config.ChangeTrackingEnabled -and $ChangeTrackingEnable) {
                        Write-Warning "Unable to change the change block tracking setting for $targetVM."
                    }
                }
                catch {
                    Write-Warning "Could not find the virtual machine $targetVM."
                }
            }
        }
    }
}
