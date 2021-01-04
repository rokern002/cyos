param(
    [Parameter]
    [string]
    $TestFile
)

try{
    $executeDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent    
    Set-Location -Path $executeDir

    $searchPattern = "TestCases/*.json"
    if($null -ne $TestFile){
        $searchPattern = "TestCases/" + $TestFile
    }


    $definitions = Get-ChildItem -r $searchPattern
    Set-Location -Path (Split-Path -Path $executeDir -Parent)

    foreach($item in $definitions){
        $definition = Get-Content $item | ConvertFrom-Json -ErrorAction SilentlyContinue
        & src\init.ps1 -DefinitionFile $item.FullName

        Remove-Item -Path $definition.BasePath -Recurse
    }
}
catch{
    Write-Error $_
}