Import-Module -Force $PSScriptRoot/../Source/Docker.Build.psm1
Import-Module -Global -Force $PSScriptRoot/Docker.Build.Tests.psm1
Import-Module -Global -Force $PSScriptRoot/MockReg.psm1

. "$PSScriptRoot\..\Source\Private\LintRemark.ps1"

Describe 'Execute linting on a given docker image' {

    Context 'When full path to a docker image is specified' {

        It 'can find 0 rule violations' {
            $dockerFile = Join-Path $Global:DockerImagesDir 'Windows.Dockerfile'
            $lintedDockerFile = Get-Content -Path (Join-Path $Global:DockerImagesDir 'Windows.Dockerfile.Linted')
            $result = Invoke-DockerLint -DockerFile $dockerFile
            $lintedDockerFile | Should -Be $result.LintOutput
        }

        It 'can find 0 rule violations, on folder with space' {
            $folderWithSpace = Join-Path $Global:DockerImagesDir 'Folder with space'
            $dockerFile = Join-Path $folderWithSpace 'Windows.Dockerfile'
            $lintedDockerFile = Get-Content -Path (Join-Path $Global:DockerImagesDir 'Windows.Dockerfile.Linted')
            $result = Invoke-DockerLint -DockerFile $dockerFile
            $lintedDockerFile | Should -Be $result.LintOutput
        }

        It 'can find 1 rule violation' {
            $dockerFile = Join-Path $Global:DockerImagesDir 'Linux.Dockerfile'
            $lintedDockerFile = Get-Content -Path (Join-Path $Global:DockerImagesDir 'Linux.Dockerfile.Linted')
            $result = Invoke-DockerLint -DockerFile $dockerFile
            $lintedDockerFile | Should -Be $result.LintOutput
        }

        It 'can find multiple rule violations' {
            $dockerFile = Join-Path $Global:DockerImagesDir 'Poorly.Written.Dockerfile'
            [string[]] $lintedDockerFile = Get-Content -Path (Join-Path $Global:DockerImagesDir 'Poorly.Written.Dockerfile.Linted')

            try {
                [string[]] $result = (Invoke-DockerLint -DockerFile $dockerFile).LintOutput
                for ($i = 0; $i -lt $lintedDockerFile.Length; $i++) {
                    $lintedDockerFile[$i] | Should -Be $result[$i]
                }
            }
            catch {
            }
        }

        It 'throws exception if docker image does not exist' {
            $code = {
                Invoke-DockerLint -DockerFile "not/here"
            }
            $code | Should -Throw -ExceptionType ([System.IO.FileNotFoundException]) -PassThru
        }

        It 'throws correct exception message if docker image does not exist' {
            try {
                Invoke-DockerLint -DockerFile "not.here"
            }
            catch {
                $exception = $_.Exception

            }
            $exception.Message | Should -BeLike "*not.here*"
        }

        It 'throws exception if lint remarks are found if required' {
            $dockerFile = Join-Path $Global:DockerImagesDir 'Linux.Dockerfile'

            $code = {
                Invoke-DockerLint -DockerFile $dockerFile -TreatLintRemarksFoundAsException
            }

            $code | Should -Throw -ExceptionType ([System.Exception]) -PassThru
        }
    }

    Context 'When no path to docker image is specified' {

        BeforeEach {
            Initialize-MockReg
            $script:currentLocation = Get-Location
        }

        AfterEach {
            Set-Location $script:currentLocation
        }

        It "Defaults to `'Dockerfile`'" {
            $code = {
                StoreMockValue -Key "Invoke-Command" -Value "$Command"
            }
            Mock -CommandName "Invoke-Command" $code -Verifiable -ModuleName $Global:ModuleName
            Set-Location -Path $Global:DockerImagesDir

            Invoke-DockerLint

            Assert-MockCalled -CommandName "Invoke-Command" -ModuleName $Global:ModuleName
            $result = GetMockValue -Key 'Invoke-Command'
            $result | Should -BeLike "*Dockerfile*"
        }
    }

    Context 'Pipeline execution' {
        It 'returns the expected pscustomobject' {
            $dockerFile = Join-Path $Global:DockerImagesDir 'Windows.Dockerfile'

            $result = Invoke-DockerLint -DockerFile $dockerFile
            $result.LintOutput | Should -Not -BeNullOrEmpty
            $result.Result.ExitCode | Should -Be 0
        }
    }
}