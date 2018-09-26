$proc =get-counter -Counter "\Processor(_Total)\% Processor Time" -SampleInterval 2
$cpu=[float]($proc.readings -split ":")[-1]
$cpu = [math]::Round($cpu*10)

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
