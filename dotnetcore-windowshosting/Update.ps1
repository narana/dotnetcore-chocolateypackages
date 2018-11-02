. $PSScriptRoot\..\aspnetcore-runtimepackagestore\update.ps1

Rename-Item -Path Function:\au_GetLatest -NewName Get-RuntimePackageStoreLatest

$releases = "https://raw.githubusercontent.com/dotnet/core/master/release-notes/releases.json"
function global:au_SearchReplace {
    $replacements = @{
        "$PSScriptRoot\tools\data.ps1" = @{
            "(^\s*Url\s*=\s*)('.*')"      = "`$1'$($Latest.URL32)'"           #1
            "(^\s*Checksum\s*=\s*)('.*')" = "`$1'$($Latest.Checksum32)'"      #2
            "(^\s*Url64\s*=\s*)('.*')"      = "`$1'$($Latest.URL64)'"           #1
            "(^\s*Checksum64\s*=\s*)('.*')" = "`$1'$($Latest.Checksum64)'"      #2

        }
         "$PSScriptRoot\$($Latest.PackageName).nuspec" = @{
             "(\<dependency .+?""aspnetcore-runtimepackagestore"" version=)""([^""]+)""" = "`$1""[$($Latest.RpsVersion)]"""
         }
    }
    if ($Latest.RpsVersion -ne $null)
    {
        $replacements["$PSScriptRoot\$($Latest.PackageName).nuspec"] = @{
             "(\<dependency .+?""aspnetcore-runtimepackagestore"" version=)""([^""]+)""" = "`$1""[$($Latest.RpsVersion)]"""
        }
    }
    else
    {
        $replacements["$PSScriptRoot\$($Latest.PackageName).nuspec"] = @{
             "<dependency .+?""aspnetcore-runtimepackagestore""[^>]+>" = ''
        }
    }
    return $replacements
}

function EntryToData($channel, $rpsVersion) {
    $url = "https://raw.githubusercontent.com/dotnet/core/master/release-notes/$channel/releases.json"
    $result = (Invoke-WebRequest -Uri $url -UseBasicParsing | ConvertFrom-Json)

    $version = $result."latest-release"
    $latest = $result.releases | ?{ $_.'release-version' -eq $version } | select -First 1

    $exe32 = $exe64 = $latest.'aspnetcore-runtime'.files | ?{ $_.name -like '*hosting*.exe' }
    if (-Not($exe32)) {
        return
    }

    @{ 
        Version = $version;
        URL32 = $exe32.url;
        URL64 = $exe64.url;
        ChecksumType32 = 'sha512';
        ChecksumType64 = 'sha512'; 
        Checksum32 = $exe32.hash;
        Checksum64 = $exe64.hash;
        RpsVersion = $rpsVersion
    }
}

function global:au_GetLatest {
    $rpsLatest = Get-RuntimePackageStoreLatest
    $rpsLatest | Format-List -Property * | Out-String | Write-Debug

    @{
        Streams = [ordered] @{
            '2.2' = EntryToData('2.2') $rpsLatest.Streams['2.2'].Version
            '2.1' = EntryToData('2.1') $rpsLatest.Streams['2.1'].Version
            '2.0' = EntryToData('2.0') $rpsLatest.Streams['2.0'].Version
            '1.1' = EntryToData('1.1') $null
            '1.0' = EntryToData('1.0') $null
        }
    }
}

update -ChecksumFor none
