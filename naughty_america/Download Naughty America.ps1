$adultbase = "$env:OneDriveConsumer\HOME\docs\media\Adult\"
$pathbase = "/downloads/ORIGINAL"
$filebase = "E:\ORIGINAL"
$network = "La Touraine"
$studiometa = "naughtyamerica"
$studio = "Naughty America"

#build paths to directories
$scriptbase = Join-Path -Path $adultbase -ChildPath "scripts"
$metabase = Join-Path -Path $adultbase -ChildPath "webscraper.io"
$studiobase = Join-Path -Path $metabase -ChildPath $network -AdditionalChildPath $studiometa
$downloadbase = Join-Path -Path $pathbase -ChildPath $network -AdditionalChildPath $studio
$filespath = Join-Path -Path $filebase -ChildPath $network -AdditionalChildPath $studio

$functions = $scriptbase + "\Common\Functions Naughty America.psm1"
$fn_download = $scriptbase + "\Common\Functions Download.psm1"

#needed files
$urlsfile = Join-Path -Path $studiobase -ChildPath "scenes.json"
$scenesfile = Join-Path -Path $studiobase -ChildPath "naughtyamerica_scenes.json"

# Define the path to the Netscape cookie file
$cookieFilePath  = Join-Path -Path $studiobase -ChildPath "cookies.txt"

#import function to read cookie file
. ($scriptbase + "\Session\Load Cookie Into Session.ps1")
Remove-Module 'Functions Naughty America'
Get-Module
Import-Module $functions
Import-Module $fn_download

#local classes
class Downloadlink {
    [string]$url
    [string]$resolution = "Unknown"

    #method to get resolution
    [string] GetResolution() {
        $regexResolution = "_(.*?)\.mp4"
        if ($this.url -match $regexResolution) {
            return $matches[1]  # Extract the resolution using regex
        } else {
            return "Unknown"  # Default value if regex doesn't match
        }
    }
    
    # Constructor
    Downloadlink ($url) {
        $this.url = $url
        $this.resolution = $this.GetResolution()         
    }
}


class DownloadlinkArrayList {
    [System.Collections.ArrayList] $Links = [System.Collections.ArrayList]::new()
    static [string[]] $ResolutionOrder = @("4k", "1080hq", "1080", "720hq", "720", "480","qt")

    # Constructor
    DownloadlinkArrayList() {
        $this.Links = [System.Collections.ArrayList]::new()
    }

    # Add a download link to the ArrayList
    [void] Add([PSCustomObject]$link) {
        $this.Links.Add($link) | Out-Null
    }
# Sort the ArrayList based on resolution
[void] SortByResolution() {
    # Convert to an array, sort it, and repopulate the ArrayList
    $sorted = $this.Links | Sort-Object {
        # Get the index of the resolution, or use a default value for unknown resolutions
        $index = [DownloadlinkArrayList]::ResolutionOrder.IndexOf($_.resolution)
        if ($index -eq -1) { 999 } else { $index }
    }
    $this.Links.Clear()
    foreach ($item in $sorted) {
        $this.Links.Add($item) | Out-Null
    }
}

}

# imports scenes metadata
  $scenesjson = Get-Content -Path  $scenesfile | ConvertFrom-Json -Depth 4 
  $scenes2 = New-Object -TypeName "System.Collections.ArrayList" 
  $scenes2.AddRange($scenesjson)

  #check existing files
  $scenefiles = Get-ChildItem -Path $filespath -Filter "*.mp4" -Recurse -File
  $sceneids = $scenefiles.BaseName | % {$_.Split("_")[0]}

  #filter scenes to exclude existing scenes
  $ScenesRemain = New-Object System.Collections.ArrayList
  $ScenesRemain = $scenes2 | ? {!($sceneids.Contains( $_.scene_id)) -and ($_.type -eq "2D")}
  $ScenesRemain.count

  $substudio = "My Friend's Hot Mom"
  $scenes = $ScenesRemain | ? {$_.sub_site -eq $substudio}
  $scenes.Count
  #$scene = $scenes[4]
  
  $session = Get-Session -FilePath $cookieFilePath

  foreach ($scene in $scenes) {
    $response = Invoke-WebRequest -Uri $scene.url -WebSession $session
    $htmlcontent = $response.Content
    #$htmlContent | Out-File -FilePath "C:\DB\$studio.html"
    $linkurls = Get-DownloadLinks -htmlpage $htmlcontent
    if ($linkurls.count -gt 0) {
        $downloadLinks = [DownloadlinkArrayList]::new()
        foreach ($linkurl in $linkurls)  {
          $linkobj = [Downloadlink]::new($linkurl)
          $downloadLinks.Add($linkobj) 
        }
        $downloadLinks.SortByResolution()
        #$dl_link = $downloadLinks.Links[0].url
        $dl_link = [System.Net.WebUtility]::HtmlDecode($downloadLinks.Links[0].url) 
    } else {
        continue
    }
    $studiodir = $scene.sub_site
    $dl_dir = Join-Path -Path $downloadbase -ChildPath $studiodir
    $dl_path = $dl_dir.Replace("\","/") #check if unix container
  
    #$filedir = Join-Path -Path $filespath -ChildPath $studiodir
    #if (!(Test-Path $filedir)) {New-Item -ItemType "directory" -Path $filedir}
  
    $dl_file = $scene.scene_id + "_" + $scene.slug + ".mp4"
  
    Get-FileFromURL -Url $dl_link -path $dl_path -Filename $dl_file -Session $session `
                  -ExternalDownloader "aria2c" -ipaddress "192.168.1.22" -port 6800 
  }

  