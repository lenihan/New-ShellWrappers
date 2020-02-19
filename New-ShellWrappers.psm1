
<#
.SYNOPSIS

Creates shell (PowerShell, Bash, CMD) scripts to launch the given Python/PowerShell file without typing an extension.

.DESCRIPTION

For Python files, creates:
    .ps1, used in: 
        Windows PowerShell 5 (built-in to Windows 10)
        Windows PowerShell 7
        Linux Bash
        Linux PowerShell 7        

For Python and PowerShell files, creates:
    .bat, used in:
        Windows Command Shell (CMD)
        Windows PowerShell 5 (built-in to Windows 10)
        Windows PowerShell 7
    no extension, used in:
        Linux Bash
        Linux PowerShell 7


.PARAMETER FileToWrap

The PowerShell (.ps1) or Python (.py) file that will be run by the created shell wrappers.

.INPUTS

None. You cannot pipe objects to New-ShellWrappers

.OUTPUTS

Creates .ps1 (if FileToWrap is .py), .bat, extension-less shell wrappers in the same location as given FileToWrap.

.LINK
https://www.powershellgallery.com/packages/New-ShellWrappers

.LINK
https://github.com/lenihan/New-ShellWrappers
#>
function New-ShellWrappers {
    Param([Parameter(Mandatory=$true)][ValidateScript({Test-Path $PSItem})]$FileToWrap)

    $version    = "1.0.0"                       # wrapper generater version
    $FileToWrap = Convert-Path $FileToWrap      # convert to full path
    $gi         = Get-Item $FileToWrap
    $dir        = $gi.DirectoryName
    $base       = $gi.BaseName
    $ext        = $gi.Extension
    $crlf       = "`r`n"                        # Windows line ending
    $lf         = "`n"                          # Linux line ending

    $pwshContents =  '#!/bin/pwsh-preview'                         + $crlf
    $pwshContents += '# DO NOT EDIT'                               + $crlf
    $pwshContents += '# Autogenerated by $PSCommandPath'           + $crlf
    $pwshContents += '# Version: $version'                         + $crlf
    $pwshContents += '`$gi     = Get-Item `$PSCommandPath'         + $crlf
    $pwshContents += '`$dir    = `$gi.DirectoryName'               + $crlf
    $pwshContents += '`$base   = `$gi.BaseName'                    + $crlf    
    $pwshContents += '`$script = Join-Path `$dir "`$base$ext"'     + $crlf    
    $pwshContents += '$app `$script `$args'                             

    $cmdContents  =  '@REM DO NOT EDIT'                            + $crlf
    $cmdContents  += '@REM Autogenerated by $PSCommandPath'        + $crlf
    $cmdContents  += '@REM Version: $version'                      + $crlf
    $cmdContents  += '@$app %~dpn0$ext %*'                               

    $bashContents =  '#!/usr/bin/env bash'                         + $lf
    $bashContents += '# DO NOT EDIT'                               + $lf
    $bashContents += '# Autogenerated by $PSCommandPath'           + $lf
    $bashContents += '# Version: $version'                         + $lf
    $bashContents += 'filename=`$(basename -- "`$0")'              + $lf
    $bashContents += 'base=`${filename%.*}'                        + $lf
    $bashContents += 'dir="`$( cd "`$(dirname "`$0")" ; pwd -P )"' + $lf
    $bashContents += '$app "`$dir/`$base$ext" $@'                       

    $wrappers = @{
        '.py' = @{
            pwsh = @{ext = '.ps1'; contents = $pwshContents; app = 'python'}
            cmd  = @{ext = '.bat'; contents = $cmdContents;  app = 'python'}
            bash = @{ext = '';     contents = $bashContents; app = 'python'}
        }
        '.ps1' = @{
            cmd  = @{ext = '.bat'; contents = $cmdContents;  app = 'pwsh-preview'}
            bash = @{ext = '';     contents = $bashContents; app = 'pwsh-preview'}
        }
    }

    if (!$wrappers[$ext]) {
        Write-Host "Do not know how to create wrapper for given file extension '$ext'" -ForegroundColor Yellow
    }
    else {
        foreach ($shell in $wrappers[$ext].keys) {
            $wrapperContents = $wrappers[$ext][$shell].contents
            $wrapperExt      = $wrappers[$ext][$shell].ext
            $app             = $wrappers[$ext][$shell].app
            $value           = $ExecutionContext.InvokeCommand.ExpandString($wrapperContents)
            $path            = Join-Path $dir "$base$wrapperExt"
            Write-Host "# Creating $shell wrapper $version to run '$app $base$ext' - $path"
            Set-Content -Path $path -Value $value
        }
    }
    Write-Host "# Done" -ForegroundColor Green

    <#
    # Copy/paste the following into PowerShell to generate test files.
    #
    # Use test files to validate wrappers work. Things to check...
    #   Verify arguments are passed correctly (testPython.ps1 a b c)
    #   Verify generated .ps1 works on...
    #       Windows PowerShell 5
    #       Windows PowerShell 7
    #       Linux Bash
    #       Linux PowerShell 7
    #   Verify generated .bat works on...
    #       Windows CMD
    #       Windows PowerShell 5
    #       Windows PowerShell 7
    #   Verify generated extension-less file works on...
    #       Linux Bash
    #       Linux PowerShell 7
    #   For Linux, verify CentOS7 and Ubuntu

    $testPwshContents = @'
    #!/usr/bin/env pwsh-preview
    "Greetings from PowerShell"
    "Args..."
    foreach ($a in $args) {$a}
    '@
    Set-Content -Path testPwsh.ps1 -Value $testPwshContents

    $testPythonContents = @'
    import sys
    print("Greetings from Python")
    print("Args...")
    for a in sys.argv: 
        print(a)
    '@
    Set-Content -Path testPython.py -Value $testPythonContents
    #>

}
Export-ModuleMember -Function New-ShellWrappers