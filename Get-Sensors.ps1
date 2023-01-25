<#
.SYNOPSIS
Output Script Details from all Sensors in an OG

.NOTES
  Version:        1.0
  Author:         Chris Halstead - chalstead@vmware.com
  Creation Date:  1/25/2023
  Purpose/Change: Initial script development
  
#>

#----------------------------------------------------------[Declarations]----------------------------------------------------------
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#-----------------------------------------------------------[Functions]------------------------------------------------------------



Function GetSensors {

if ([string]::IsNullOrEmpty($wsoserver))
  {
    $script:WSOServer = Read-Host -Prompt 'Enter the Workspace ONE UEM Server Name'
  
  }
 if ([string]::IsNullOrEmpty($header))
  {
    $Username = Read-Host -Prompt 'Enter the Username'
    $Password = Read-Host -Prompt 'Enter the Password' -AsSecureString
    $apikey = Read-Host -Prompt 'Enter the API Key'
    $script:og = Read-Host -Prompt 'Enter the OG UUID to list sensors from'

    #Convert the Password
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    $UnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

    #Base64 Encode AW Username and Password
    $combined = $Username + ":" + $UnsecurePassword
    $encoding = [System.Text.Encoding]::ASCII.GetBytes($combined)
    $cred = [Convert]::ToBase64String($encoding)

    $script:header = @{
    "Authorization"  = "Basic $cred";
    "aw-tenant-code" = $apikey;
    "Accept"		 = "application/json;version=2";
    "Content-Type"   = "application/json";}
  }


  $Script:stemp = $env:TEMP


try {

  
  $sresult = Invoke-RestMethod -Method Get -Uri "https://$wsoserver/api/mdm/devicesensors/list/$og" -ContentType "application/json" -Header $header

}

catch {
  Write-Host "An error occurred when logging on $_"
  break
}

write-host $sresult.total_results " sensors found"

$script:soutput = ""


foreach ($sensor in $sresult.result_set)

{


  $sensoruuid = $sensor.uuid

  $sensordetail = Invoke-RestMethod -Method Get -Uri "https://$script:wsoserver/api/mdm/devicesensors/$sensoruuid" -ContentType "application/json" -Header $header


$script = $sensordetail.script_data

$hrscript = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($script))

$soutput = $soutput + "Sensor Name: $($sensor.name)" + [Environment]::Newline
$soutput = $soutput + "Sensor Script Data: $hrscript" + [Environment]::Newline + [Environment]::Newline




}

$soutput | out-file -FilePath "$stemp\sensors.txt"

write-host "Sensor Data Written to $stemp\sensors.txt"


}
  
  

function Show-Menu
  {
    param (
          [string]$Title = 'VMware Workspace ONE UEM API Menu'
          )
       Clear-Host
       Write-Host "================ $Title ================"
       Write-Host "Press '1' to export Sensor scripts"
       Write-Host "Press 'Q' to quit."
         }

do

 {
    Show-Menu
    $selection = Read-Host "Please make a selection"
    switch ($selection)
    {
    
    '1' {  

         GetSensors
    } 
    
      
    }
    pause
 }
 until ($selection -eq 'q')

