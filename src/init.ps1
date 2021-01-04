param(
    [Parameter(Mandatory)]
    [string]
    $DefinitionFile
)

if(!(Test-Path $DefinitionFile -PathType Leaf)){
    Throw "json defintion file do not exists"
}

function Get-Project-Extension {
    param (
        [string] $language
    )
    switch -Exact ($language) {
        "C#" { return ".csproj" }
        "F#" { return ".fsproj" }
        Default { Throw "Language (" + $language + ") is not supported" }
    }
}

class ActiveDirectory
{
    [string] $Instance
    [string] $ClientId
    [string] $Domain
}

class AzureADB2C : ActiveDirectory
{
    [string] $SignUpSignInPolicyId
}

class AzureAD : ActiveDirectory
{
    [string] $TenantId
}

class Project
{
    [string] $Name
    [string] $Type
    [string] $Framework
    [string] $Language
    [string] $TestProjectType
    [string[]] $Files
    [string[]] $NugetPackages
    [AzureADB2C] $AzureAdB2C
    [AzureAD] $AzureAD
}

class Process
{
    [string] $SolutionName
    [string] $BasePath
    [string] $Framework
    [string] $Language
    [string] $ProjectsFolder
    [string] $TestsProjectFolder
    [string[]] $Files
    [Project[]] $Projects
}
try {
    
    $definition = (Get-Content $DefinitionFile | ConvertFrom-Json)
    $definition = [Process]$definition

    $globalJson =
    ("{`r" +
    "`t""sdk"": {`r" +
    "`t`t""version"": """ + $definition.Framework + """,`r" +
    "`t`t""rollForward"": ""latestMinor""`r" +
    "`t}`r"+
    "}")

    if([string]::IsNullOrEmpty($definition.BasePath)){
        Throw "BasePath not exists or empty... it is required to run script"
    }

    if([string]::IsNullOrEmpty($definition.SolutionName)){
        Throw "Solution name not defined... it is required to run script"
    }

    if(!(Test-Path $definition.BasePath)){
        New-Item $definition.BasePath -ItemType Directory -Force
    }
    Push-Location
    Set-Location -Path $definition.BasePath

    $globalJson | Set-Content "global.json"

    Foreach ($i in $definition.Projects){
        Write-Output $i

        $language = $definition.Language
        if($null -ne $i.Language){
            $language = $i.Language
        }

        $projectExtension = Get-Project-Extension $language

        $projectPath = Join-Path -Path $definition.ProjectsFolder -ChildPath $i.Name

        if($null -ne $i.AzureAD){
            $ad = [AzureAD]$i.AzureAD
            dotnet new $i.Type -lang $language -o $projectPath -f $i.Framework -au SingleOrg --aad-instance $ad.Instance --client-id $ad.ClientId --domain $ad.Domain --tenant-id $ad.TenantId --force
        } 
        elseif($null -ne $i.AzureAdB2C){    
            $ad = [AzureADB2C]$i.AzureAdB2C
            dotnet new $i.Type -lang $language -o $projectPath -f $i.Framework -au IndividualB2C --aad-b2c-instance $ad.Instance --client-id $ad.ClientId --domain $ad.Domain -ssp $ad.SignUpSignInPolicyId --force
        }
        else {
            dotnet new $i.Type -lang $language -o $projectPath -f $i.Framework --force
        }
        
        if(![string]::IsNullOrEmpty($i.TestProjectType)){
            $testPath = Join-Path -Path $definition.TestsProjectFolder -ChildPath ($i.Name + "Tests")
            dotnet new $i.TestProjectType -lang $language -o $testPath -f $i.Framework --force
            dotnet add ($testPath + "\" + $i.Name + "Tests" + $projectExtension) reference ($projectPath + "\" + $i.Name + $projectExtension)
        }
    }

    dotnet new sln -n ($definition.SolutionName) --force
    $projectFiles = Get-ChildItem -r **/*.*proj
    if($projectFiles.Length -gt 0){
        dotnet sln ($definition.SolutionName + ".sln") add $projectFiles
    }

    if($null -ne $definition.Files){
        foreach($path in $definition.Files){
            New-Item $path -ItemType File -Force
        }
    }
}
catch {
    Write-Error $_
}
finally
{
    Pop-Location
}