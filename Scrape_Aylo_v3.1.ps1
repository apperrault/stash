function Get-HeaderMG (){
    param(
        [ValidateSet("bangbros","realitykings","twistys","milehigh", "biempire", `
        "babes", "erito", "mofos", "fakehub", "sexyhub", "propertysex", "metrohd",`
        "brazzers", "milfed", "gilfed", "dilfed", "men", "whynotbi", `
        "seancody", "iconmale", "realitydudes","spicevids")] 
        [String]$studio
     )
    #these are used to get the API key which controls which studio you can scrape

    $useragent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36"
    [uri]
    $urlsite = "www." + $studio + ".com"
    $webr = Invoke-WebRequest -UseBasicParsing -Uri 
    $urlsite 
    -Method HEAD
    $iname = $webr.Headers.'Set-Cookie'
    $instance = $iname.Split(';')
    $apikey = $instance[0].Split('=')[1]

    $headers = @{
      "UserAgent" = "$useragent";
      "instance"="$apikey"
      }
    return $headers
}

function Set-QueryParameters {
param (
    [string]$groupid = $null,
    [Int]$offset = 0,
    [Parameter(Mandatory)]
    [string]$studio,
    #content types can only be {actor, scene, movie}
    [Parameter(Mandatory)]
    [ValidateSet('actor','movie','scene')]
    [string]$ContentType
)
    #initialize variables
    $page = 0
    $Body = @{
        limit = 100
        offset = $offset
    }
    $header = Get-HeaderMG -studio $studio
    If ($null -eq $groupid) {$body.Add("groupID",$groupid)}
    #api call for actors is different from movies and releases
    If ($ContentType -eq "actor") {
        $urlapi = "https://site-api.project1service.com/v1/actors"
    }  else {
        $urlapi = "https://site-api.project1service.com/v2/releases"
        $body.Add("orderBy","-dateReleased")
        $body.Add('type',$ContentType)
    }
    $params = @{
        "Uri" = $urlapi
        "Body" = $Body
        "Headers" = $header
    }
    #$params.Add("Headers",$headers)
    return $params
}

function Get-MaxPages ($meta){
    $limit = $meta.count
    $maxpage = $meta.total/$limit
    $maxpage = [Math]::Ceiling($maxpage)
    return $maxpage
}

function Get-StudioJson ($groupID = $null, $studio, $ContentType ){
    $scenelist = New-Object -TypeName System.Collections.ArrayList
    $params = Set-QueryParameters -studio $studio -ContentType $ContentType
    $scenes0 = Invoke-RestMethod
    $limit = $scenes0.meta.count
    $maxpage = Get-MaxPages -meta $scenes0.meta

    for ($p=1;$p -le $maxpage;$p++) {
        $page = $p-1
        Write-Host "Downloading: $page of $maxpage" 
        $offset = $page*$limit
        $params = Set-QueryParameters -studio $studio -ContentType $ContentType -offset $offset
        $scenes = Invoke-RestMethod @params 
        $scenelist.AddRange($scenes.result)
    }
    return $scenelist
}

# there are only 3 supported content types.
# not all studios support movies

#this is a simple check to make sure Brazzers is working
# make sure you have create a directory called "C:\DB\Mindgeek\json\Brazzers"
# this will create a file called 
$studios = ("brazzers")
$ContentTypes = @("gallery")
foreach ($ContentType in $ContentTypes ) {
    foreach ($studio in $studios) {
        $filedir = "C:\DB\Mindgeek\json\$ContentType"
        $filepath = Join-Path -Path $filedir -ChildPath "$studio.json"
        if (!(Test-Path $filedir)) {New-Item -ItemType "directory" -Path $filedir}
        Write-Host "Downloading: $studio" 
        $json = Get-StudioJson -studio $studio -ContentType $ContentType
        $json | ConvertTo-Json -Depth 16 | Out-File -FilePath $filepath
    }
}
$json.Count
#this part below is a loop do not run this unless you want all data from all studios.
#it may not work for studios which to not support movies
$studios = ("bangbros","realitykings","twistys","milehigh", "biempire", `
 "babes", "erito", "mofos", "fakehub", "sexyhub", "propertysex", "metrohd",`
 "brazzers", "milfed", "gilfed", "dilfed", "men", "whynotbi", `
 "seancody", "iconmale", "realitydudes", "spicevids" )

$ContentTypes = @("actor", "scene", "movie")
$ContentTypes = @("gallery")
foreach ($ContentType in $ContentTypes ) {
    foreach ($studio in $studios[1]) {
        $filedir = "C:\DB\Mindgeek\json\$ContentType"
        $filepath = Join-Path -Path $filedir -ChildPath "$studio.json"
        if (!(Test-Path $filedir)) {New-Item -ItemType "directory" -Path $filedir}
        Write-Host "Downloading: $studio" 
        $json = Get-StudioJson -studio $studio -ContentType $ContentType
        $json | ConvertTo-Json -Depth 32 | Out-File -FilePath $filepath
    }
}
