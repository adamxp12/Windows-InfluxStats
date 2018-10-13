#settings
$pwd = ConvertTo-SecureString "PASSWORD" -AsPlainText -Force
$credz = New-Object System.Management.Automation.PSCredential("USERNAME", $pwd)

#infitie loop so data continuously gets sent to DB
DO
{
    [System.Collections.ArrayList]$a = @()
    
    $dcollect = Get-Counter -Counter "\Hyper-V Hypervisor Logical Processor(*)\% Guest Run Time" | select -expand CounterSamples | where -property InstanceName -notmatch -Value '_total'
    $a = @()

    Foreach ($o in $dcollect) {
        $a.Add($o.CookedValue)
    }

    $hvguestrun = [math]::Round(($a | Measure-Object -Average).Average)

    $dcollect = Get-Counter -Counter "\Hyper-V Hypervisor Logical Processor(*)\% Hypervisor Run Time" | select -expand CounterSamples | where -property InstanceName -notmatch -Value '_total'
    $a = @()

    Foreach ($o in $dcollect) {
        $a.Add($o.CookedValue)
    }

    $hvhvisorrun = [math]::Round(($a | Measure-Object -Average).Average)

    $dcollect = Get-Counter -Counter "\Hyper-V Hypervisor Logical Processor(*)\% Total Run Time" | select -expand CounterSamples | where -property InstanceName -notmatch -Value '_total'
    $a = @()

    Foreach ($o in $dcollect) {
        $a.Add($o.CookedValue)
    }

    $hvtotalrun = [math]::Round(($a | Measure-Object -Average).Average)

    $dcollect = Get-Counter -Counter "\Hyper-V Hypervisor Logical Processor(*)\% Idle Time" | select -expand CounterSamples | where -property InstanceName -notmatch -Value '_total'
    $a = @()

    Foreach ($o in $dcollect) {
        $a.Add($o.CookedValue)
    }

    $hvidle = [math]::Round(($a | Measure-Object -Average).Average)

    $mem = (Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum

    $freemem = (Get-Counter '\Memory\Available MBytes').countersamples.cookedvalue

    $disk = Get-PSDrive C | Select-Object Used,Free
    $cused = $disk.used
    $cfree = $disk.free

    $vmcount = (Get-VM).count
    $vmruncount = (Get-VM | Where { $_.State -eq 'Running' }).count

    $metrics = @{
    totalmem=$mem; 
    freemem=$freemem; 
    cfree=$cfree; 
    cused=$cused;
    vmcount=$vmcount;
    vmruncount=$vmruncount;
    guestcpuruntime=$hvguestrun;
    hypervisorcpuruntime=$hvhvisorrun;
    totalcpuruntime=$hvtotalrun;
    cpuidletime=$hvidle;}

    Write-Influx -Measure HV -Tags @{Hostname=$env:COMPUTERNAME} -Metrics $metrics -Database DBNAME -Server http://SERVERADDRESS:8086 -Credential $credz
} While($true)