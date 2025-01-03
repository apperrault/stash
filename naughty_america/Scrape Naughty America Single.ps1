$adultbase = "$env:OneDriveConsumer\HOME\docs\media\Adult\"
$network = "La Touraine"
$studio = "naughtyamerica"

#build paths to directories
$scriptbase = Join-Path -Path $adultbase -ChildPath "scripts"
$metabase = Join-Path -Path $adultbase -ChildPath "webscraper.io"
$studiobase = Join-Path -Path $metabase -ChildPath $network -AdditionalChildPath $studio
$functions = $scriptbase + "\Common\Functions Naughty America.psm1"

#needed files
$urlsfile = Join-Path -Path $studiobase -ChildPath "scenes.json"
$scenesfile = Join-Path -Path $studiobase -ChildPath "naughtyamerica_scenes.json"

# Define the path to the Netscape cookie file
$cookieFilePath  = Join-Path -Path $studiobase -ChildPath "cookies.txt"

#import function to read cookie file
. ($scriptbase + "\Session\Load Cookie Into Session.ps1")

# Load the cookies into the WebRequestSession

$scenelist = Get-Content -Path $urlsfile | ConvertFrom-Json -Depth 4 
$scenelist.Count
# Couple of useful scriptblocks
$remainingurl = {
  $urls2 = $urls | ? {$scenes2.scene_id  -notcontains $_.Split("-")[-1] }
  $urls2.count
}
$endtiming = {
    # End timing
    $endTime = Get-Date
    # Calculate elapsed time
    $elapsedTime = $endTime - $startTime
    Write-Output "Elapsed Time: $elapsedTime"
}
Import-Module $functions

$urls = $scenelist.url.replace("www","members")
# Step 2: Fetch the HTML content
  
  $scenesjson = Get-Content -Path  $scenesfile | ConvertFrom-Json -Depth 4 
  $scenes2 = New-Object -TypeName "System.Collections.ArrayList" 
  $scenes2.AddRange($scenesjson)

  $session = Get-Session -FilePath $cookieFilePath

  $startTime = Get-Date
  $scenes1 = New-Object -TypeName "System.Collections.ArrayList" 
  $session = Get-Session -FilePath $cookieFilePath
  $range = 0..0
  $startTime = Get-Date
  
  $urls2 | ForEach-Object {
    $response = Invoke-WebRequest -Uri $_ -WebSession $session
    $htmlContent = $response.Content
    #$htmlContent | Out-File -FilePath "C:\DB\$studio.html"
    $scene = Get-SceneMetaData -htmlpage $htmlContent
    if ($null -eq $scene.scene_id) {
      continue
    } else {
      $scene = Add-SceneMetaData -htmlpage $htmlContent -scene $scene
      $scene | Add-Member -NotePropertyName "url" -NotePropertyValue $_ 
      $scenes1.Add($scene) | Out-Null
    }
    Start-Sleep -Seconds 0.5
} 
$scenes2.AddRange($scenes1)
$endtiming.Invoke()
$remainingurl.Invoke()

$scenes2.Count
$scenes2 | ConvertTo-Json -Depth 4 | Out-File -FilePath $scenesfile
 
$scenes1.Count


  $missinglist = New-Object -TypeName "System.Collections.ArrayList" 
  foreach ($url in $urls) {
    $sceneid = $url.Split("-")[-1]
    if (!($sceneid -contains $sceneids)) {
        Write-Host "Missing URL: $url"
        $missinglist.Add($url) | Out-Null
    }
  }
 
  $missinglist.Count
  ($sceneids |  Select-Object -Unique).count

  Remove-Module "Functions Naughty America"
  
  
  $scenes3 = $scenes2 | Group-Object -Property scene_id | ForEach-Object {
    $_.Group | Select-Object -First 1
}
  $scenes3 | ConvertTo-Json -Depth 4 | Out-File -FilePath $scenesfile
$scenes3.Count

$response = Invoke-WebRequest -Uri $urls2 -WebSession $session
    $htmlContent = $response.Content
    #$htmlContent | Out-File -FilePath "C:\DB\$studio.html"
    $scene = Get-SceneMetaData -htmlpage $htmlContent
    if ($null -eq $scene.scene_id) {
      continue
    } else {
      $scene = Add-SceneMetaData -htmlpage $htmlContent -scene $scene
      $scene | Add-Member -NotePropertyName "url" -NotePropertyValue $_ 
      $scenes1.Add($scene) | Out-Null
    }

$scenes2 | ? {$_.scene_id -eq "846"}