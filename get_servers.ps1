# Search variable
$server = "*server*"

$results = Get-AdComputer -filter {OperatingSystem -like $server} -Properties * | select -ExpandProperty Name | Out-File servers.txt



#notepad servers.txt