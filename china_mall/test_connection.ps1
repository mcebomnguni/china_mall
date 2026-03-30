# PowerShell script to test Supabase connection
$envFile = ".env"
$env = @{}

if (Test-Path $envFile) {
    $lines = Get-Content $envFile
    foreach ($line in $lines) {
        $line = $line.Trim()
        if ($line -eq "" -or $line.StartsWith("#")) {
            continue
        }
        $parts = $line -split "=", 2
        if ($parts.Length -ge 2) {
            $key = $parts[0].Trim()
            $value = $parts[1].Trim()
            if ($value.StartsWith('"') -and $value.EndsWith('"')) {
                $value = $value.Substring(1, $value.Length - 2)
            } elseif ($value.StartsWith("'") -and $value.EndsWith("'")) {
                $value = $value.Substring(1, $value.Length - 2)
            }
            $env[$key] = $value
        }
    }
}

$supabaseUrl = $env["SUPABASE_URL"]
$supabaseAnonKey = $env["SUPABASE_ANON_KEY"]

Write-Host "Supabase URL length: $($supabaseUrl.Length)"
Write-Host "Supabase URL: $supabaseUrl"
Write-Host "Anon Key length: $($supabaseAnonKey.Length)"

# Test HTTP request
try {
    $uri = "$supabaseUrl/auth/v1/user"
    $response = Invoke-RestMethod -Uri $uri -Method GET -Headers @{
        "apikey" = $supabaseAnonKey
        "Authorization" = "Bearer $supabaseAnonKey"
    } -ErrorAction Stop
    
    Write-Host "✅ Supabase is reachable"
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        Write-Host "Status code: $($_.Exception.Response.StatusCode)"
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $body = $reader.ReadToEnd()
        Write-Host "Response: $body"
    }
}
