$content = Get-Content '.env' -Raw
Write-Host "Content length: $($content.Length)"
Write-Host "First 100 chars: $($content.Substring(0, [Math]::Min(100, $content.Length)))"
