# Test Supabase login directly
Add-Type -AssemblyName System.Net.Http

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

# Test login with test user
$email = "customer.test.001@chinamall.local"
$password = "Test1234!"

$loginData = @{
    email = $email
    password = $password
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$supabaseUrl/auth/v1/token?grant_type=password" -Method POST -Headers @{
        "apikey" = $supabaseAnonKey
        "Content-Type" = "application/json"
    } -Body $loginData -ErrorAction Stop
    
    Write-Host "✅ Login successful!"
    Write-Host "Access token: $($response.access_token.Substring(0, 50))..."
} catch {
    Write-Host "❌ Login failed: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $body = $reader.ReadToEnd()
        Write-Host "Response: $body"
    }
}
