$reader = [System.IO.StreamReader]::new("C:\DB\Gamma\json\ragingstallion\ragingstallion_movies.json")
$jsonContent = $reader.ReadToEnd()
$reader.Close()

$jsonData = $jsonContent | ConvertFrom-Json
# $jsonData
$selectedData = $jsonData | Select-Object -Property 'movie_id', 'title', 'date_created', 'nb_of_scenes', 'cover_path', 'url_title'|Export-Csv results.csv -NoTypeInformation
# $selectedData