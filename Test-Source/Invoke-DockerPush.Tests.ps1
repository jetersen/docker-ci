Import-Module -Force (Get-ChildItem -Path $PSScriptRoot/../Source -Recurse -Include *.psm1 -File).FullName
Import-Module -Global -Force $PSScriptRoot/Docker-CI.Tests.psm1

Describe 'docker push' {

    Context 'Push an image' {

        BeforeEach {
            Initialize-MockReg
            Mock -CommandName 'Invoke-Command' $Global:CodeThatReturnsExitCodeZero -Verifiable -ModuleName $Global:ModuleName
        }

        AfterEach {
            Assert-MockCalled -CommandName 'Invoke-Command' -ModuleName $Global:ModuleName
        }

        It 'produces the correct command to invoke with only image name provided' {
            Invoke-DockerPush -ImageName 'cool-image'

            $mockCommandResult = GetMockValue -Key $Global:InvokeCommandReturnValueKeyName
            $mockArgsResult = GetMockValue -Key $Global:InvokeCommandArgsReturnValueKeyName

            $mockCommandResult | Should -Be "docker"
            $mockArgsResult | Should -Be 'push cool-image:latest'
        }

        It 'produces the correct command to invoke with image name and registry provided' {
            Invoke-DockerPush -ImageName 'cool-image' -Registry 'hub.docker.com:1337/thebestdockerimages'

            $mockArgsResult = GetMockValue -Key $Global:InvokeCommandArgsReturnValueKeyName
            $mockArgsResult | Should -Be "push hub.docker.com:1337/thebestdockerimages/cool-image:latest"
        }

        It 'produces the correct command to invoke with image name and $null registry value provided' {
            Invoke-DockerPush -ImageName 'cool-image' -Registry $null

            $mockArgsResult = GetMockValue -Key $Global:InvokeCommandArgsReturnValueKeyName
            $mockArgsResult | Should -Be "push cool-image:latest"
        }

        It 'produces the correct command to invoke with image name, registry and tag provided' {
            Invoke-DockerPush -ImageName 'cool-image' -Registry 'hub.docker.com:1337/thebestdockerimages' -Tag 'v1.0.3'

            $mockArgsResult = GetMockValue -Key $Global:InvokeCommandArgsReturnValueKeyName
            $mockArgsResult | Should -Be "push hub.docker.com:1337/thebestdockerimages/cool-image:v1.0.3"
        }

        It 'throws an exception if the execution of docker push did not succeed' {
            Mock -CommandName 'Invoke-Command' $Global:CodeThatReturnsExitCodeOne -Verifiable -ModuleName $Global:ModuleName

            $theCode = {
                Invoke-DockerPush -ImageName 'cool-image' -Registry 'hub.docker.com:1337/thebestdockerimages' -Tag 'v1.0.3'
            }

            $theCode | Should -Throw -ExceptionType ([System.Exception]) -PassThru
        }
    }

    Context 'Pipeline execution' {
        $pipedInput = {
            $input = [PSCustomObject]@{
                "ImageName" = "myimage";
                "Registry"  = "localhost";
                "Tag"       = "v1.0.2"
            }
            return $input
        }

        BeforeEach {
            Initialize-MockReg
            Mock -CommandName 'Invoke-Command' $Global:CodeThatReturnsExitCodeZero -Verifiable -ModuleName $Global:ModuleName
        }

        AfterEach {
            Assert-MockCalled -CommandName 'Invoke-Command' -ModuleName $Global:ModuleName
        }

        It 'can consume arguments from pipeline' {
            & $pipedInput | Invoke-DockerPush
        }

        It 'returns the expected pscustomobject' {
            $result = & $pipedInput | Invoke-DockerPush
            $result.ImageName | Should -Be 'myimage'
            $result.Registry | Should -Be 'localhost/'
            $result.Tag | Should -Be 'v1.0.2'
            $result.CommandResult | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Verbosity of execution' {

        BeforeEach {
            Initialize-MockReg
            Mock -CommandName 'Invoke-Command' $Global:CodeThatReturnsExitCodeZero -Verifiable -ModuleName $Global:ModuleName
        }

        It 'outputs result if Quiet is disabled' {
            $tempFile = New-TemporaryFile
            Mock -CommandName 'Invoke-Command' $Global:CodeThatReturnsExitCodeZero -Verifiable -ModuleName $Global:ModuleName

            Invoke-DockerPush -ImageName 'cool-image' -Quiet:$false 6> $tempFile

            $result = Get-Content $tempFile
            $result | Should -Be @('Hello', 'World')
        }

        It 'suppresses output if Quiet is enabled' {
            $tempFile = New-TemporaryFile
            Mock -CommandName 'Invoke-Command' $Global:CodeThatReturnsExitCodeZero -Verifiable -ModuleName $Global:ModuleName

            Invoke-DockerPush -ImageName 'cool-image' -Quiet:$true 6> $tempFile

            $result = Get-Content $tempFile
            $result | Should -BeNullOrEmpty
        }
    }
}
