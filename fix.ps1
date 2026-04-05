$dirs = "Anthem", "Blaster", "Blue", "Ice", "Library", "Retro", "Revelant", "tech-support"
foreach ($d in $dirs) {
    if (Test-Path ".\$d") {
        $files = Get-ChildItem -Path ".\$d" -Filter "*.md"
        foreach ($f in $files) {
            if ($f.Name -ne "index.md") {
                $content = Get-Content $f.FullName -Raw
                if ($null -ne $content -and -not $content.StartsWith("---")) {
                    $content = "---`r`nlayout: default`r`n---`r`n`r`n" + $content
                }
                Set-Content -Path ".\$d\index.md" -Value $content -Encoding UTF8
                Remove-Item $f.FullName
            }
        }
    }
}
