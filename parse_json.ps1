$reader = [System.IO.StreamReader]::new("C:\DB\Gamma\json\ragingstallion\ragingstallion_movies.json")
$jsonContent = $reader.ReadToEnd()
$reader.Close()

$jsonData = $jsonContent | ConvertFrom-Json -AsHashtable
$selectedData = $jsonData | Select-Object -Property 'movie_id', 'title', 'date_created', 'nb_of_scenes', 'cover_path', 'url_title'|Export-Csv movies.csv -NoTypeInformation

$scenereader = [System.IO.StreamReader]::new("C:\DB\Gamma\json\ragingstallion\ragingstallion_scenes.json")
$jsonContent2 = $scenereader.ReadToEnd()
$reader.Close()

$jsonData2 = $jsonContent2 | ConvertFrom-Json -AsHashtable
$selectedData2 = $jsonData2 | Select-Object -Property 'clip_id', 'title', 'release_date', 'sitename', 'sitename_pretty', 'url_title'|Export-Csv scenes.csv -NoTypeInformation