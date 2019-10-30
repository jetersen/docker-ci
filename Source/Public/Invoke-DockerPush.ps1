. "$PSScriptRoot\..\Private\Utilities.ps1"

function Invoke-DockerPush {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [String]
        $Registry = '',

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [String]
        $ImageName,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Tag = 'latest'
    )
    $postfixedRegistry = Add-PostFix $Registry
    $command = "docker push ${postfixedRegistry}${ImageName}:${Tag}"
    $commandResult = Invoke-Command $command
    Assert-ExitCodeOk $commandResult
    $result = [PSCustomObject]@{
        'Result'    = $commandResult;
        'ImageName' = $ImageName;
        'Registry'  = $postfixedRegistry;
        'Tag'       = $Tag;
    }
    return $result
}