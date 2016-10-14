
#===========================================================================#
#===                                                                     ===#
#=== Adds or updates the specified connection string setting             ===#
#=== in the specified .NET configuration file.                           ===#
#=== This utility is from the scriptedConfigurationOfAppFabric.ps1       ===#
#===========================================================================#

function UpdateConnectionString([string]$name, [string]$connectionString)
{
    $providerName = "System.Data.SqlClient"

    $NETFramework4Path = gp -Path HKLM:\Software\Microsoft\'NET Framework
       Setup'\NDP\v4\Full
    $ConfigPath = "$($NETFramework4Path.InstallPath)Config\Web.config"

    Write-Output ("ConfigPath : " + $ConfigPath)
   
    $xml = [xml](Get-Content $ConfigPath)
    $root = $xml.get_DocumentElement()

               
    $connectionStrings = $root.SelectSingleNode("connectionStrings")
    if ($connectionStrings -eq $null)
    {
        $locations = $root.SelectNodes("location")

        foreach ($locationNode in $locations)
        {
            $locStrings = $locationNode.SelectSingleNode("connectionStrings")
            
            if ($locStrings -ne $null)
            {
                $connectionStrings = $locStrings
            }
        }

        if ($connectionStrings -eq $null)
        {
            $connectionStrings = $xml.CreateElement("connectionStrings")
            $root.AppendChild($connectionStrings) | Out-Null
        }
    }

    $xpath = "add[@name='" + $name + "']"
    $add = $connectionStrings.SelectSingleNode($xpath)
    if ($add -eq $null)
    {
        Write-Output "Adding new connection string setting..."
        $add = $xml.CreateElement("add")
        $connectionStrings.AppendChild($add) | Out-Null
    }
    else
    {
        Write-Output "Updating existing connection string setting..."
    }

    $add.SetAttribute("name", $name)
    $add.SetAttribute("connectionString", $connectionString)
    $add.SetAttribute("providerName", $providerName)
    Write-Output $add | Format-List
   
    $xml.Save($ConfigPath)
}
