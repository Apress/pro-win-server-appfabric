$MSBuildPath = "$($(gp -Path HKLM:\Software\Microsoft\'NET Framework Setup'\NDP\v4\Full).InstallPath)MSBuild.exe" 


$VSSolutionFullName = "C:\Users\Administrator\Documents\AppFabricBook\Contoso\Solution\Chapter7\Solution\Contoso.Workflows\ProcessClaimService\ProcessClaimService.csproj"
$SiteName = "ProcessClaimService"
$PhysicalPath = "C:\Users\Administrator\Documents\AppFabricBook\Contoso\Solution\Chapter7\Solution\Contoso.Workflows\ProcessClaimService\bin\"
$AppPoolName = "ProcessClaimServiceAppPool"
$PackageName = "C:\Users\Administrator\Documents\AppFabricBook\Contoso\Solution\Chapter7\Solution\Contoso.Workflows\ProcessClaimService\bin\ProcessClaimServiceDeployPackage.zip"
$MonitoringDatabaseName = "ProcessClaimService"
$PersistanceDatabaseName = "ProcessClaimService_PS"
$DatabaseServerName = ".\SQLEXPRESS"  #DUBLIN100\SQLEXPRESS


#Create the web deployment package for your project
#Write-Output "Building project as a package"
#MSBuild "YourProject.csproj" /T:Package


#Create the web deployment package for your project
Write-Output "Creating the Web Deployment Package"
.$MSBuildPath "$VSSolutionFullName" /T:Package /P:PackageLocation="$PackageName"

 
#We will be using the appcmd.exe 
$env:SYSTEMROOT


#Create the AppPool
Write-Output "Creating the AppPool"
.$env:SystemRoot\System32\inetsrv\appcmd.exe add apppool /Name:$AppPoolName -managedRuntimeVersion:v4.0

#Create the new web site
Write-Output "Creating the Web Site"
.$env:SystemRoot\System32\inetsrv\appcmd.exe add site /name:$SiteName /bindings:http/*:8089: /physicalPath:$PhysicalPath

#Assign the AppPool to the site
Write-Output "Assigning the AppPool to the Web Site"
##.$env:SystemRoot\System32\inetsrv\appcmd.exe set site $SiteName /applicationDefaults.applicationPool:$AppPoolName

#Take the package and deploy it
Write-Output "Deploying the package...."
$MSDeployPath = "$env:ProgramFiles\IIS\Microsoft Web Deploy\msdeploy.exe"

#.\msdeploy.exe -verb=sync -source=metakey=/lm/w3svc/1 -dest=metakey=/lm/w3svc/2 -verbose 

.$MSDeployPath -verb:sync -source:package=$PackageName -dest:auto #-setParam:Name="IIS Web Application Name",value="$SiteName"      #"OrderApplication/OrderApplication" 


#Configure the deployed application
Import-Module applicationserver
#Create/Initialize the montoring database
Write-Output "Creating/Initializing the Montoring Database"
#Initialize-ASMonitoringDatabase -Database "OrderApplication" -Admins "$($env:COMPUTERNAME)\AS_Administrators","NT AUTHORITY\LOCAL SERVICE" -Readers "AS_Observers" -Writers "BUILTIN\IIS_IUSRS" | fl * 
Initialize-ASMonitoringDatabase -ConnectionString "Data Source=$DatabaseServerName;Initial Catalog=$MonitoringDatabaseName;Integrated Security=True" -Admins "$($env:COMPUTERNAME)\AS_Administrators","NT AUTHORITY\LOCAL SERVICE" -Readers "AS_Observers" -Writers "BUILTIN\IIS_IUSRS" | fl * 



#Create/Initialize the persistence database
$env:COMPUTERNAME

Write-Output "Creating /Initializing the Persistence Database"
Initialize-ASPersistenceDatabase -ConnectionString "Data Source=$DatabaseServerName;Initial Catalog=$PersistanceDatabaseName;Integrated Security=True" -Admins "$($env:COMPUTERNAME)\AS_Administrators" -Readers "$($env:COMPUTERNAME)\AS_Observers" -Users "BUILTIN\IIS_IUSRS" -Confirm:$false | fl *


import-module  .\Utilities.ps1


#SQL Express
Write-Output "Updating ConnectionString".
##UpdateConnectionString $MonitoringDatabaseName "Data Source=$DatabaseServerName;Initial Catalog=$MonitoringDatabaseName;Integrated Security=True"

#SQL Server
#UpdateConnectionString "$DatabaseName" "Data Source=(local);Initial Catalog=$DatabaseName;Integrated Security=True"

#Reconfigure the web site to utilize the databases
Write-Output "Configuring the site to utilize the databases"

Set-ASAppMonitoring -Root -MonitoringLevel HealthMonitoring -ConnectionStringName $MonitoringDatabaseName
Set-ASAppServicePersistence -Root -ConnectionStringName $MonitoringDatabaseName
#Set-ASAppMonitoring -SiteName $SiteName -MonitoringLevel HealthMonitoring -ConnectionStringName $MonitoringDatabaseName
#Set-ASAppServicePersistence -SiteName $SiteName -ConnectionStringName $MonitoringDatabaseName

#The SiteName format must be in the format of ProcessClaimService/ClaimService or just ProcessClaimService/
.$env:SystemRoot\System32\inetsrv\appcmd.exe set app "$SiteName/" /enabledProtocols:"http,net.pipe"

Write-Output "".
Write-Output "Installation Complete".
