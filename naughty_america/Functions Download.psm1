
class DownloadItem {
    [string]$URL
    [string]$Out
    [string]$Dir

    # Constructor
    DownloadItem([string]$url, [string]$out, [string]$dir) {
        $this.URL = $url
        $this.Out = $out
        $this.Dir = $dir
    }
}
class Aria2cDownloadItem : DownloadItem {
    [string]$JsonRPC = "2.0"
    [string]$ID = "1"
    [string]$Method = "aria2.addUri"
    [array]$Params
    [string]$Token

    # Constructor
    Aria2cDownloadItem([string]$url, [string]$out, [string]$dir, [string]$id, [string]$token) : base($url, $out, $dir) {
        $this.ID = $id
        $this.token = $token
        $this.Params = @(
            "token:$($this.Token)",       # RPC authentication token
            @($this.URL),              # URL array for aria2c
            @{
                out = $this.Out        # Output filename
                dir = $this.Dir        # Output directory
            }
        )
    }

    # JSON payload method (replacing property)
    [string] GetJsonPayload() {
        # Construct the JSON payload dynamically
        return [pscustomobject]@{
            jsonrpc = $this.JsonRPC
            id      = $this.ID
            method  = $this.Method
            params  = $this.Params
        } | ConvertTo-Json -Depth 10 -Compress
    }
}

function Get-FileFromURL {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Url,
        [string]$Path,
        [string]$Filename,
        [Microsoft.PowerShell.Commands.WebRequestSession]$Session,
        [ValidateSet("IDM","aria2c" ,ErrorMessage="Error: Downloader is not supported" )]
        [String]$ExternalDownloader,
        [string]$ipaddress ,
        [string]$port
    )
    #The default location of IDM ... should be the same for default installation.
    $idman = "C:\Program Files (x86)\Internet Download Manager\IDMan.exe"
    # RPC server configuration
    $rpcServer = "http://" + $ipaddress + ":"+ $port + "/jsonrpc"
    $rpcSecret = "surfinusa" # Set the secret token for authentication read a yaml
    
    $file_target = Join-Path -Path $Path -ChildPath $Filename
    if (!(Test-Path $file_target)) {
        try {
            $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -Method Head -WebSession $Session -ErrorAction Stop
            Write-Host  "Download: " $Filename " -to- " $Path    
            If ($ExternalDownloader -eq "IDM") {
                &$idman /d $Url /p $Path /f $Filename /a /n
                Start-Sleep -Seconds 0.50
            } elseif ($ExternalDownloader -eq "aria2c") {
                $item = [Aria2cDownloadItem]::new(
                        $Url,  # URL
                        $Filename,             # Output filename
                        $Path,                 # Output directory
                        "1",                   # Request ID
                        $rpcSecret             # RPC token
                )
                # Send the JSON payload to aria2c
                try {
                    $response = Invoke-RestMethod -Uri $rpcServer -Method POST -Body $item.GetJsonPayload()
                    Write-Output "Response from aria2c RPC:"
                    Write-Output $response.Content
                } catch {
                    Write-Output "Failed to send the request to aria2c RPC server"
                    Write-Output $_.Exception.Message
                }
            }
            
            #Write-Output "URL is accessible. Status code: $($response.StatusCode)"
        }
        catch {
            Write-Output "URL is not accessible. Error: $($_.Exception.Message)"
            Write-Output $url
        }
        
    } else {
        Write-Host  "Already Exists: " $Filename
    }
    
}