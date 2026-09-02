$port = 8088
$root = 'C:\tt-ai-stack\01_projects\active\bov\06_enagement\bbt'

$endpoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Loopback, $port)
$tcpListener = New-Object System.Net.Sockets.TcpListener($endpoint)

try {
    $tcpListener.Start()
    Write-Host "[BBT Web Server] TCP server active on http://localhost:$port/"
} catch {
    Write-Host "Failed to bind TCP port $port"
    exit 1
}

while ($true) {
    try {
        $client = $tcpListener.AcceptTcpClient()
        $stream = $client.GetStream()
        $reader = New-Object System.IO.StreamReader($stream)
        
        $requestLine = $reader.ReadLine()
        if (-not $requestLine) {
            $client.Close()
            continue
        }
        
        $parts = $requestLine.Split(' ')
        $urlPath = if ($parts.Length -ge 2) { $parts[1] } else { '/' }
        
        if ($urlPath -eq '/' -or [string]::IsNullOrWhiteSpace($urlPath)) {
            $urlPath = '/index.html'
        }
        
        # Strip query params
        if ($urlPath.Contains('?')) {
            $urlPath = $urlPath.Substring(0, $urlPath.IndexOf('?'))
        }
        
        $cleanPath = $urlPath.TrimStart('/').Replace('/', '\')
        $filePath = Join-Path $root $cleanPath
        
        if (Test-Path $filePath -PathType Leaf) {
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
            
            $contentType = switch ($ext) {
                '.html' { 'text/html; charset=utf-8' }
                '.js'   { 'application/javascript; charset=utf-8' }
                '.json' { 'application/json; charset=utf-8' }
                '.css'  { 'text/css; charset=utf-8' }
                '.pdf'  { 'application/pdf' }
                '.md'   { 'text/markdown; charset=utf-8' }
                default { 'application/octet-stream' }
            }
            
            $header = "HTTP/1.1 200 OK`r`nContent-Type: $contentType`r`nContent-Length: $($bytes.Length)`r`nConnection: close`r`n`r`n"
            $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($header)
            
            $stream.Write($headerBytes, 0, $headerBytes.Length)
            $stream.Write($bytes, 0, $bytes.Length)
        } else {
            $body = "404 - File Not Found"
            $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)
            $header = "HTTP/1.1 404 Not Found`r`nContent-Type: text/plain`r`nContent-Length: $($bodyBytes.Length)`r`nConnection: close`r`n`r`n"
            $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($header)
            
            $stream.Write($headerBytes, 0, $headerBytes.Length)
            $stream.Write($bodyBytes, 0, $bodyBytes.Length)
        }
        
        $stream.Flush()
        $client.Close()
    } catch {
        # ignore client disconnect errors
    }
}
