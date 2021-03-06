Import-Module AU

$releases = 'https://github.com/int128/kubelogin/releases/latest'

function global:au_BeforeUpdate {
  Get-RemoteFiles -Purge -NoSuffix
}

function global:au_SearchReplace {
  @{
    ".\legal\VERIFICATION.txt" = @{
      "(?i)(^\s*location on\:?\s*)\<.*\>"   = "`${1}<$($Latest.ReleaseURL)>"
      "(?i)(^\s*64\-bit software.*)\<.*\>"  = "`${1}<$($Latest.URL64)>"
      "(?i)(^\s*checksum64\:).*"            = "`${1} $($Latest.Checksum64)"
    }

    "$($Latest.PackageName).nuspec" = @{
      "(\<releaseNotes\>).*?(\</releaseNotes\>)" = "`${1}$($Latest.ReleaseNotes)`${2}"
    }
  }
}

function global:au_GetLatest {
  $url = Get-RedirectedUrl $releases

  $version = $url -split '\/v' | Select-Object -Last 1

  return @{
    Version     = $version
    URL64       = "https://github.com/int128/kubelogin/releases/download/v${version}/kubelogin_windows_amd64.zip"
    ReleaseNotes= "https://github.com/int128/kubelogin/releases/tag/v${version}"
    ReleaseURL  = "$releases"
  }
}

update -ChecksumFor none
