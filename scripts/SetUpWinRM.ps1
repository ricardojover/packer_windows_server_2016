<powershell>
write-host "Setting up WinRM"

Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force -ErrorAction Ignore

$hostname=(curl http://169.254.169.254/latest/meta-data/public-hostname).Content
$cert=New-SelfSignedCertificate -DnsName $hostname -CertStoreLocation 'Cert:\LocalMachine\My'
winrm create winrm/config/Listener?Address=*+Transport=HTTPS "@{Hostname=`"$hostname`"; CertificateThumbprint=`"$($cert.Thumbprint)`"}"

winrm quickconfig -q -transport:https
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/service '@{AllowUnencrypted="false"}'
winrm set winrm/config/client/auth '@{Basic="true"}'
winrm set winrm/config/client '@{AllowUnencrypted="false"}'

New-NetFirewallRule -Name winrmhttps -DisplayName 'WinRM HTTPS' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 5986
Stop-Service winrm
Set-Service winrm -StartupType Automatic
Start-Service winrm

</powershell>
