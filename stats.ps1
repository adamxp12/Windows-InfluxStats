# I am still fighting this. I currently think Performance counters do not count in Hyper-V stats as the result of this
# + the 4% constant Hyper-V usage from Xprotect gets me in very close to what task manager says the CPU usage is
# If only microsoft gave me a Give-MeTheCPUUsageFromTaskManager function :|
$proc =get-counter -Counter "\Processor(_total)\% Processor Time" -SampleInterval 2 -MaxSamples 3
$proc = $proc | select -expand CounterSamples
[System.Collections.ArrayList]$a = @()

Foreach ($o in $proc) {
    $a.Add($o.CookedValue)
} 
$cpu = ($a | Measure-Object -Average).Average
$cpu = [math]::Round($cpu)

$mem = Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
$mem = $mem.sum
$freemem = Get-Counter '\Memory\Available MBytes'
$freemem = $freemem.countersamples.cookedvalue

$disk = Get-PSDrive C | Select-Object Used,Free
$cused = $disk.used
$cfree = $disk.free

$vm = Get-VM
$vmcount = $vm.count
$vmrun = $vm | Where { $_.State –eq ‘Running’ }
$vmruncount = $vmrun.count


$metrics = @{cpu=$cpu;
totalmem=$mem; 
freemem=$freemem; 
cfree=$cfree; 
cused=$cused;
vmcount=$vmcount;
vmruncount=$vmruncount}

Write-Influx -Measure Test -Tags @{Hostname=$env:COMPUTERNAME} -Metrics $metrics -Database windows-stat -Server http://10.0.6.5:8086 -Verbose
