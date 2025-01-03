
#function to extract json from script variable
function Get-SceneMetaData {
    param (
        [Parameter(Mandatory = $true)]
        [string]$htmlpage
    )
    # Step 3: Define the regex pattern to extract 'scene_properties'
    $regexPattern = 'var\s+scene_properties\s*=\s*(\{.*?\})'
    # Step 4: Use [regex]::Match to search for the pattern in the content
    $match = [regex]::Match($htmlpage, $regexPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)

    # Step 5: Check if a match was found and extract the value
    if ($match.Success) {
        $scenetext = ($match.Groups[1].Value).Replace("'", '"')
        $quotetoremove = "&quot;"
        $scenetext = $scenetext.Replace($quotetoremove, "")
        $sceneProperties = [System.Net.WebUtility]::HtmlDecode($scenetext) 
        #Write-Output "Extracted scene_properties:"
        try {
            $scene = $sceneProperties | ConvertFrom-Json -Depth 4 
        }
        catch {
            Write-Host $sceneProperties
            return $null
        }
        
        return $scene
    } else {
        Write-Output "scene_properties not found in the file."
    }
}

function Get-DownloadLinks {
    param (
        [Parameter(Mandatory = $true)]
        [string]$htmlpage
    )
    $xpath  = '//td/a[@class="download-title"]/@href'
    
    $html = $htmlpage | ConvertFrom-Html
    $nodes = $html.SelectNodes($xpath)
    $link_attributes = $nodes.Attributes | ? {$_.Name -eq "href"} | ? {$_.Value -like "*mp4*" } | ? {$_.Value -notlike "*5min*" } 
    $links = $link_attributes.Value 
    return $links
    
}
function Add-SceneMetaData {
    param (
        [Parameter(Mandatory = $true)]
        [string]$htmlpage,
        [PSCustomObject] $scene
    )
    $xpath_scenepage = @{
        "Poster"      = '//*[@id="anchor-player"]/img[1]/@src'
        "Download"    = '//td/a[@class="download-title"]/@href'
      }
    $regexResolution = "_(.*?)\.mp4"
    $html = $htmlpage | ConvertFrom-Html
    $poster = ($html.SelectNodes($xpath_scenepage["Poster"]).Attributes | ? {$_.Name -eq "src"}).Value
    $scene | Add-Member -NotePropertyName "poster" -NotePropertyValue $poster
    
    $links = Get-DownloadLinks -htmlpage $
    $resolutions = @("nomp4")
    $links | % {$_ -match $regexResolution | Out-Null;$resolutions+=$matches[1] }
    $resolutions = $resolutions | Select-Object -Unique
    $scene | Add-Member -NotePropertyName "Resolutions" -NotePropertyValue $resolutions

    $parsed_path = $poster.split("/")
    $filestub = $parsed_path[-5] + $parsed_path[-4]
    $scene | Add-Member -NotePropertyName "FileStub" -NotePropertyValue $filestub 
    return $scene

}
