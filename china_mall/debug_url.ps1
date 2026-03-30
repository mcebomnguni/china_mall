$content = Get-Content '.env' -Raw
$lines = $content -split "`r`n"
foreach ($line in $lines) {
    if ($line.StartsWith("SUPABASE_URL=")) {
        $url = $line.Substring(13)
        Write-Host "URL length: $($url.Length)"
        Write-Host "URL: $url"
        Write-Host "URL bytes: [System.Text.Encoding]::UTF8.GetBytes($url)"
    }
}
