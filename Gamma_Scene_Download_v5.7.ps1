Connect-AzAccount
Set-AzContext -SubscriptionName "Azure subscription 1"

$resourceGroupName = "AdultCloud"
$accountName = "meta4all"
$databaseName = "scrapes"
$collection = "gamma2"
$network = "Gamma"
$suffix = ".jpg"
$segment = "adulttime"
$studiofiles = 'E:\ORIGINAL\$network\$segment'

#The default location of IDM ... should be the same for default installation.
$idman = "C:\Program Files (x86)\Internet Download Manager\IDMan.exe"

#edit the next line to the root folder where you want the files placed
$path_base = "E:\STAGING"

# you can leave the next line the same but it will create a subfolder called Gamma
# Gamma is the parent company for many studios and this script only works with Gamma studios.
$network = "Gamma"
$sep_name = "_"

$cosmosDbContext = New-CosmosDbContext -Account $accountName -Database $databaseName -ResourceGroup $resourceGroupName

#$scenefiles = Get-ChildItem -Path $studiofiles -Include "*.mp4", "*.mkv" -Recurse
$scenefiles = Get-ChildItem -Path $studiofiles -Filter "*.mp4" -Recurse 

#$scenefiles.Count
$scenes = New-Object System.Collections.ArrayList

$downloadsize = 0

$query = "SELECT c.clip_id, c.title, c.sitename, c.sitename_pretty, c.segment, c.studio_name, c.serie_name,`
          c.url_movie_title, c.url_title,`
          c.download_sizes, c.download_file_sizes`
FROM c`
WHERE isdefined(c.clip_id) and not isdefined(c.set_id) AND  c.serie_name = 'Wet Food' `
"
$doc = Get-CosmosDbDocument -Context $cosmosDbContext -CollectionId $collection -Query $query -QueryEnableCrossPartition $true -ReturnJson
$scenesquery = ($doc | ConvertFrom-Json).Documents

$sceneids = New-Object System.Collections.ArrayList
$scenefiles | % {$sceneids.Add($_.Name.Split('_')[0])}

# $scenes | % {$downloadsize += $_.download_file_sizes.PSObject.Properties.Value[-1]}

foreach ($scene in $scenesquery) {
 
    if (!$sceneids.Contains($scene.clip_id.ToString() ) ) {
        Write-Host "Download: " $scene.clip_id,"_",$scene.Title
        $Scenes.Add($scene)
        $downloadsize += $scene.download_file_sizes.PSObject.Properties.Value[-1]
        } else {
            Write-Host "Already Have: " $scene.clip_id,"_",$scene.Title
        }
    if ($downloadsize -gt 270000000000) {break}

}

$scenes.Count
$links = $scenes
$domain = $links[0].segment
$download_domain = $segment

$url_base = -join("https://members.",$download_domain,".com/movieaction/download/")
$url_tail = "/mp4"

Foreach ($scene in $scenes) {
    
    $resolutionmax = $scene.download_sizes[-1]
    $studio = $scene.studio_name
    $substudio = $scene.sitename_pretty
    $series = $scene.serie_name
    $movie = $scene.url_movie_title.Replace('-',' ')
    $title = $scene.url_title.Replace('-',' ')
    $clip = $scene.clip_id
    $segment = $scene.segment

    $resolution = $resolutionmax # change this line to pick MIN($resolution,$resolutionmax)
    #$dl_path = -join($path_base, "\", $network, "\", $segment, "\", $studio, "\", $substudio)
    $dl_path = -join($path_base, "\", $network, "\", $studio, "\", $series, "\", $movie)
    #if ($null -ne $movie) {$dl_path = -join($dl_path, "\", $movie)}
    if (!(Test-Path $dl_path)) {New-Item -ItemType "directory" -Path $dl_path}
    $dl_file = -join($clip , $($sep_name) , $title , ".mp4")
    $dl_link = -join($url_base, $clip , "/", $resolution, $url_tail)
    #Write-Host  $dl_link
    #Write-Host  $dl_path
    Write-Host  $dl_file $dl_path
    #&$idman /d $dl_link /p $dl_path /f $dl_file /a /n
    #it may make sense to adjust the delay, IDM does not handle too many requests at once.
    Start-Sleep -Seconds 0.60
}


