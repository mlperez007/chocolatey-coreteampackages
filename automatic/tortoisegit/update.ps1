import-module au
import-module "$PSScriptRoot/../../extensions/extensions.psm1"

$releases = 'https://tortoisegit.org/download/'

function global:au_BeforeUpdate {
  $Latest.ChecksumType = "sha256"
  Get-RemoteFiles -Purge -FileNameBase $Latest.FileName32
  Get-RemoteFiles -Purge -FileNameBase $Latest.FileName64
}

function global:au_SearchReplace {
    @{
        ".\tortoisegit.nuspec" = @{
            "(<releaseNotes>https:\/\/tortoisegit.org\/docs\/releasenotes\/#Release_)(.*)(<\/releaseNotes>)" = "`${1}$($Latest.Version.ToString())`$3"
        }
        ".\tools\chocolateyInstall.ps1" = @{
            "(^[$]filePath32\s*=\s*`"[$]toolsPath\\)(.*)`"" = "`$1$($Latest.FileName32)`""
            "(^[$]filePath64\s*=\s*`"[$]toolsPath\\)(.*)`"" = "`$1$($Latest.FileName64)`""
        }
        ".\legal\verification.txt" = @{
            "(?i)(32-Bit.+)\<.*\>" = "`${1}<$($Latest.URL32)>"
            "(?i)(64-Bit.+)\<.*\>" = "`${1}<$($Latest.URL64)>"
            "(?i)(checksum type:\s+).*" = "`${1}$($Latest.ChecksumType)"
            "(?i)(checksum32:\s+).*" = "`${1}$($Latest.Checksum32)"
            "(?i)(checksum64:\s+).*" = "`${1}$($Latest.Checksum64)"
        }        
     }
}

function global:au_GetLatest {
    $download_page = Invoke-WebRequest -UseBasicParsing -Uri $releases

    #https://download.tortoisegit.org/tgit/2.3.0.0/TortoiseGit-2.3.0.0-32bit.msi
    $re32  = "TortoiseGit-(.*)-32bit.msi"
    $url32 = $download_page.links | Where-Object href -match $re32 | Select-Object -First 1 -expand href

    #https://download.tortoisegit.org/tgit/2.3.0.0/TortoiseGit-2.3.0.0-64bit.msi
    $re64  = "TortoiseGit-(.*)-64bit.msi"
    $url64 = $download_page.links | Where-Object href -match $re64 | Select-Object -First 1 -expand href

    $filename32 = [IO.Path]::GetFileName($url32)
    $filename64 = [IO.Path]::GetFileName($url64)

    $version32 = $filename32 -split '-' | Select-Object -Skip 1 -First 1
    $version64 = $filename64 -split '-' | Select-Object -Skip 1 -First 1

    if ($version32 -ne $version64) {
        throw "Different versions for 32-Bit and 64-Bit detected."
    }

    return @{
        URL32 = "https:" + $url32 
        URL64 = "https:" + $url64 
        FileName32 = $filename32
        FileName64 = $filename64
        Version = $version32 
    }
}

update -ChecksumFor none