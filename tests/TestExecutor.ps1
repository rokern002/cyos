
class Process
{
    [string] $SolutionName
    [string] $BasePath
    [string] $Framework
    [string] $Language
    [string] $ProjectsFolder
    [string] $TestsProjectFolder
    [object[]] $Files
    [object[]] $Projects
}

try{
    $definitions = Get-ChildItem -r TestCases/*.json 

    foreach($item in $definitions){
        $definition = [Process](Get-Content $item | ConvertFrom-Json)
        & ..\src\init.ps1 -DefinitionFile $item

        Remove-Item -Path $definition.BasePath -Recurse
    }
}
catch{
    Write-Output $_
}