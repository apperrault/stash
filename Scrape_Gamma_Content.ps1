function Get-HeaderGamma ($domain ){
    $useragent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:79.0) Gecko/20100101 Firefox/79.0"
    # freetour does not work on some sites this needs to become site specific
    [uri]$url = "https://www.$domain.com/"
    [hashtable]$headers = @{
        "User-Agent" = $useragent;
        "Origin" = $url.Host;
        "Referer" = $url.Host;
        "Content-type" = "application/json"
        }
    $groups = Invoke-WebRequest -Uri $url -Headers $headers | Select-String -Pattern "window.env\s+=\s(.+);"
    $keys = $groups.Matches.groups[1].Value | ConvertFrom-Json
    
    $headers.Add("x-algolia-application-id",$keys.api.algolia.applicationID)
    $headers.Add("x-algolia-api-key",$keys.api.algolia.apiKey)

    # some sites like blowpass need you to login
    # in that case the next piece of code looks for an html file save after logging in
    If ($null -eq $headers.'x-algolia-api-key' ) {
        $headers = Get-HeaderSubscriber -domain $domain
    }
    return $headers
}

function Get-HeaderSubscriber ($domain){
    $useragent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:79.0) Gecko/20100101 Firefox/79.0"
    # freetour does not work on some sites this needs to become site specific
    [uri]$url = "https://members.$domain.com/en"
    [hashtable]$headers = @{
        "User-Agent" = $useragent;
        "Origin" = "https://" + $url.Host;
        "Referer" = "https://" + $url.Host;
        "Content-type" = "application/json"
        }
    $domainfile = "C:\DB\Gamma\session\$domain.html"
    $groups = Get-Content -Path $domainfile | Select-String -Pattern "window.env\s+=\s(.+);"
    $keys = $groups.Matches.groups[1].Value | ConvertFrom-Json
    
    $headers.Add("x-algolia-application-id",$keys.api.algolia.applicationID)
    $headers.Add("x-algolia-api-key",$keys.api.algolia.apiKey)
    return $headers
}

function Write-Json2File ($domain, $ContentType) {
    $header = Get-HeaderGamma -domain $domain
    $pagenum = 0
    $nbpages = 1
    $contents = New-Object -TypeName System.Collections.ArrayList
    [uri]$url = "https://tsmkfa364q-dsn.algolia.net/1/indexes/*/queries"
    
    $content_type = @{
        scenes = 'all_scenes_latest_desc'
        movies = 'all_movies_latest_desc'
        actors   = 'all_actors'
        channels  = 'all_channels'
        photos = 'all_photosets_latest_desc'
    }
    $indexName = $content_type[$ContentType]
    $jsonbase = "C:\DB\Gamma\json\" + $domain + "\"
    if (!(Test-Path $jsonbase)) {New-Item -ItemType "directory" -Path $jsonbase}
    #$network = "Devil's Film"
    do {
        $page = $pagenum.ToString()
        $body = "{""requests"": [{""indexName"": ""$indexName"",""params"": ""&hitsPerPage=1000&page=$page""}]}"
        $response = Invoke-WebRequest -Uri $url -Headers $header -Method POST -Body $body 
        $rjson = $response.content | ConvertFrom-Json -Depth 48 -AsHashtable
        $content = $rjson.results.hits

        # the next 2 statements are not needed
        # the purpose is to create an id for use with Azure CosmosDB and remove redundant data
        $content|foreach-object{$_|add-member -membertype noteproperty -name id -value $_.objectID}
        $content| % {$_.PSObject.Properties.Remove('_highlightResult')}
   
        if ($pagenum -eq 0) { 
            $rjson = $response.content | ConvertFrom-Json -Depth 48
            $hits = $rjson.results.nbHits
            $nbpages = $rjson.results.nbPages
        }
    
        if ($hits -eq 0){continue}
        $filejson = -join($jsonbase,$domain,"_",$ContentType,"_",$page,".json")
        #$content | ConvertTo-Json -Depth 48 | Out-File -FilePath $filejson
        $contents.AddRange($content)
        $pagenum++

    } until ($pagenum -eq $nbpages)
    $filejson = -join($jsonbase,$domain,"_",$ContentType,".json")
    $contents | ConvertTo-Json -Depth 48 | Out-File -FilePath $filejson
}

$contentlist = @('scenes','movies','actors','photos','channels')
$domains =@('addicted2girls','zerotolerancefilms','adulttime','activeduty')
$domain = $domains[3] #set to Adult Time for someone
Foreach ($content in $contentlist){
    Write-Json2File -domain $domain -ContentType $content
}

# this is for manual operation
# just change the domain and content type to suit.

$domain = $domains[1]
Foreach ($content in $contentlist){
    Write-Json2File -domain $domain -ContentType $content
}

$domain = "dfxtra"
$ContentType = "channels"
Write-Json2File -domain $domain -ContentType $ContentType

$domain = "addicted2girls"
$ContentType = "actors"
Write-Json2File -domain $domain -ContentType $ContentType


$domain = "addicted2girls"
$ContentType = "movies"
Write-Json2File -domain $domain -ContentType $ContentType

$header = Get-HeaderSubscriber -domain "blowpass"

$domain =  "xempire"
$ContentType = "actors"
Write-Json2File -domain $domain -ContentType $ContentType

Get-HeaderGamma -domain "dfxtra"

$contentlist = @('scenes','movies','actors','photos','channels')
$domains =@('addicted2girls','zerotolerancefilms','adulttime','activeduty','evilangel',"dfxtra")
$domain = $domains[5] #set to dogfart for someone
Foreach ($content in $contentlist){
    Write-Json2File -domain $domain -ContentType $content
}
