# If you are playing with this and do not want to use a very complex password
# you can use this function.
function remove_policy_password_complexity() {
  secedit /export /cfg c:\\secpol.cfg
  (gc C:\\secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0") | Out-File C:\\secpol.cfg
  secedit /configure /db c:\\windows\\security\\local.sdb /cfg c:\\secpol.cfg /areas SECURITYPOLICY
  rm -force c:\\secpol.cfg -confirm:$false
}

function add_user($username, $password) {
  net user $username "${password}" /add /y
  net localgroup administrators $username /add
}

# Installing Chocolatey - Package manager for Windows
function install_choco_and_packages() {
  Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
  choco install -y notepadplusplus.install
  choco install -y git > C:\\Temp\\git.txt
  choco install -y puppet-agent > C:\\Temp\\puppet-agent.txt
}

function fw_open_http_ports() {
  New-NetFirewallRule -Name http -DisplayName 'HTTP' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 80
}

function import_server_manager() {
  Import-Module ServerManager
}

function install_dot_net_35() {
  Add-WindowsFeature Net-Framework-Core
}

function install_iis_and_components() {
  Add-WindowsFeature Web-Server, Web-WebServer, Web-Security, Web-Filtering, Web-Health, Web-Http-Logging, Web-Custom-Logging, Web-Request-Monitor, Web-Http-Tracing, Web-App-Dev, Web-Asp-Net, Web-Asp-Net45, Web-CGI, Web-Scripting-Tools, Web-Mgmt-Console
}

function is_program_installed($name) {
  $to_match = "The install of ${name} was successful."
  $file = "C:\\temp\\${name}.txt"

  if ((Test-Path $file) -eq $false ) {
    return $false
  }

  if ((Get-Content $file | %{$_ -match $to_match}) -contains $true) {
    return $true
  }

  return $false
}

function clone_puppet_repo() {
  Set-Location "C:\\"
  cmd /c "git clone git@whatever.git"
}

function reload_path() {
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 
}

function get_s3_files($bucket_name, $files, $target_dir) {
  Import-Module "${Env:ProgramFiles(x86)}\AWS Tools\PowerShell\AWSPowerShell\AWSPowerShell.psd1"
  New-Item -ItemType Directory -Force -Path $target_dir
  foreach ($file in $files) {
    Read-S3Object -BucketName $bucket_name -Key $file -File "${target_dir}\${file}"
  }
}

function download_ssh_config_files($bucket_name) {
  $files = $("config", "private.key", "publickey.pub")
  $target_dir = "C:\Users\Administrator\.ssh"

  get_s3_files $bucket_name $files $target_dir
}

function download_beats_and_aws_es_proxy() {
  $files = $("beats.zip", "aws-es-proxy-0.8-windows-amd64.exe")
  $target_dir = "C:\Temp"

  get_s3_files $files $target_dir
}

# The missing file aws_es_proxy_service.ps1 is actually an adaptation to my necessities of the file
# PSService.ps1 that you can find in https://github.com/JFLarvoire/SysToolsLib/tree/master/PowerShell
function set_up_aws-es-proxy() {
  $proxy_dir = "$Env:ProgramFiles\AWS-ES-Proxy"
  $service_proxy_ps1_name = "aws_es_proxy_service.ps1"
  New-Item -ItemType Directory -Force -Path $proxy_dir
  Copy-Item -Force "C:\Temp\aws-es-proxy-0.8-windows-amd64.exe" "${proxy_dir}\aws-es-proxy.exe"
  (gc ${proxy_dir}\${service_proxy_ps1_name}).replace("#ELASTICSEARCH_ENDPOINT#", "$Env:ES_ENDPOINT") | Out-File ${proxy_dir}\${service_proxy_ps1_name}
  & ${proxy_dir}\${service_proxy_ps1_name} -Setup
}

function set_up_beats() {
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [System.IO.Compression.ZipFile]::ExtractToDirectory("C:\Temp\beats.zip", "$Env:ProgramFiles")
  & "$Env:ProgramFiles\Filebeat\install-service-filebeat.ps1"
  & "$Env:ProgramFiles\Metricbeat\install-service-metricbeat.ps1"
}

function init($my_username, $my_password, $my_bucket) {
  New-Item -ItemType Directory -Force -Path C:\Temp
  remove_policy_password_complexity
  add_user ${my_username} ${my_password}
  install_choco_and_packages
  fw_open_http_ports
  download_ssh_config_files $my_bucket
  download_beats_and_aws_es_proxy
  set_up_aws-es-proxy
  set_up_beats
  set_computer_name_true
}

function set_computer_name_true() {
  (gc $Env:ProgramData\Amazon\EC2-Windows\Launch\Config\LaunchConfig.json).replace("`"setComputerName`": false,", "`"setComputerName`": true,") | Out-File $Env:ProgramData\Amazon\EC2-Windows\Launch\Config\LaunchConfig.json
}

function clean() {
  Remove-Item -Recursive -Force C:\Temp\*
}

init $Env:MY_USERNAME $Env:MY_PASSWORD $Env:MY_BUCKET
import_server_manager
install_dot_net_35
install_iis_and_components

$timeout = 600
$count = 0
$increment = 5
$is_git_installed = $false

Write-Host "Installing git and puppet..." -NoNewline
while (($is_git_installed -eq $false) -and ($count -lt $timeout)) {
  $is_git_installed = is_program_installed "git"
  $is_puppet_installed = is_program_installed "puppet-agent"

  if (($is_git_installed -eq $true) -and ($is_puppet_installed -eq $true)) {
    Write-Host
    reload_path
    clone_puppet_repo
    clean
    exit 0
  }
  Write-Host "." -NoNewline
  sleep $increment
  $count+=$increment
}

exit 1

