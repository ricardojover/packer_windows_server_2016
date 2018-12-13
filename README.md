# Packer
Packer is an Open Source tool created by HashiCorp that makes possible to build identical machine images for multiple platforms from a single source configuration.

You can read more in the official web site [Packer](https://www.packer.io)
 
## Creating a Windows Server 2016 AMI on AWS
Here I'm using packer to create an AMI in AWS with Windows Server 2016 with some software pre-installed.

## Software
I will use [Chocolatey](https://chocolatey.org/) to install GIT, Notepad++ and the Puppet agent.
This image will also have installed IIS, Filebeat, Metricbeat and an AWS ElasticSearch Proxy.

Since the final configuration, which will depend on the environment, will be done using Puppet, I leave the repository downloaded.

## Beats
Filebeat and Metricbeat will point to the locally installed [AWS ES Proxy](https://github.com/abutaha/aws-es-proxy) which has been installed as a service using [JFLarvoire's PowerShell PSService.ps1](https://github.com/JFLarvoire/SysToolsLib/tree/master/PowerShell) as template.

## Deployment
You must have an AWS account.
You will have to replace the VPC and Subnet to your own.
Download the [Packer tool](https://www.packer.io/downloads.html)
You can validate the template before build your image
```
packer validate win2016.json
```
If you see the message "Template validated successfully.", then it's ready to deploy
```
packer build win2016.json
```

## Tips
* I have used an AWS role to be able to access a bucket where I store the ssh keys and some other sensitive information.
* If you want to use a bucket, but do not want to use a role, just pass your AWS credentials as environment variables in the packer file and use them in the PS file.
* You can skip all that and upload the SSH keys and config directly with packer if you wish.
* I'm downloading the beats and the AWS ES Proxy from my bucket, but you can actually download them directly from the official web sites.
