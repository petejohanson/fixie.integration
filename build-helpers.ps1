﻿function run-tests($project, $configuration, $bitness=64) {
    if ($bitness -eq 64) {
        $fixie = find-dependency Fixie.Console.exe
    } elseif ($bitness -eq 32) {
        $fixie = find-dependency Fixie.Console.x86.exe
    }

    $output = "====== $([IO.Path]::GetFileName($fixie)) $project.dll ======"
    write-host $output -ForegroundColor Green
    $output | Out-File -FilePath actual.log -Append -Encoding utf8

    & $fixie src\$project\bin\$configuration\$project.dll | Tee-Object -Variable output
    $output | Out-File -FilePath actual.log -Append -Encoding utf8
}

function find-dependency($exe_name) {
    $exes = @(gci src\packages -rec -filter $exe_name)

    if ($exes.Length -ne 1)
    {
        throw "Expected to find 1 $exe_name, but found $($exes.Length)."
    }

    return $exes[0].FullName
}

function copyright($startYear, $authors) {
    $date = Get-Date
    $currentYear = $date.Year
    $copyrightSpan = if ($currentYear -eq $startYear) { $currentYear } else { "$startYear-$currentYear" }
    return "Copyright © $copyrightSpan $authors"
}

function generate($path, $content) {
    $oldContent = [IO.File]::ReadAllText($path)

    if ($content -ne $oldContent) {
        $relativePath = Resolve-Path -Relative $path
        write-host "Generating $relativePath"
        [IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    }
}

function mit-license($copyright) {
    generate "LICENSE.txt" @"
The MIT License (MIT)
$copyright

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
"@
}

function exec($cmd) {
    $global:lastexitcode = 0
    & $cmd
    if ($lastexitcode -ne 0) {
        throw "Error executing command:$cmd"
    }
}

function step($block) {
    $command = $block.ToString().Trim()
    heading $command
    &$block
}

function heading($title) {
    write-host
    write-host $title.Replace("-", " ") -fore CYAN
}

function run-build($mainBlock) {
    try {
        &$mainBlock
        write-host
        write-host "Build Succeeded" -fore GREEN
        exit 0
    } catch [Exception] {
        write-host
        write-host $_.Exception.Message -fore DARKRED
        write-host
        write-host "Build Failed" -fore DARKRED
        exit 1
    }
}

function get-msbuild-path {
    # Find the highest installed version of msbuild.exe.

    $regLocalKey = $null

    $regLocalKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,[Microsoft.Win32.RegistryView]::Registry32)

    $versionKeyName = $regLocalKey.OpenSubKey('SOFTWARE\Microsoft\MSBuild\ToolsVersions\').GetSubKeyNames() | Sort-Object {[double]$_} -Descending

    $keyToReturn = ('SOFTWARE\Microsoft\MSBuild\ToolsVersions\{0}' -f $versionKeyName)

    $path = ( '{0}msbuild.exe' -f $regLocalKey.OpenSubKey($keyToReturn).GetValue('MSBuildToolsPath'))

    return $path
}

new-alias msbuild (get-msbuild-path)
new-alias nuget tools\NuGet.exe