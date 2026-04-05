Remove-Item -Path "Anthem\index.md", "Blaster\index.md", "Blue\index.md", "Ice\index.md", "Library\index.md", "Retro\index.md", "Revelant\index.md", "tech-support\index.md" -ErrorAction SilentlyContinue

git checkout 6868483 -- Anthem/ Blaster/ Blue/ Ice/ Library/ Retro/ Revelant/ tech-support/

$dirs = ("Anthem", "Blaster", "Blue", "Ice", "Library", "Retro", "Revelant", "tech-support")
foreach ($d in $dirs) {
    if (Test-Path ".\$d") {
        $files = Get-ChildItem -Path ".\$d" -Filter "*.md"
        foreach ($f in $files) {
            if ($f.Name -ne "index.md") {
                $content = Get-Content $f.FullName -Encoding UTF8 -Raw
                if ($null -ne $content -and -not $content.StartsWith("---")) {
                    $content = "---`nlayout: default`n---`n`n" + $content
                }
                $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
                [System.IO.File]::WriteAllText("$PWD\$d\index.md", $content, $Utf8NoBomEncoding)
                Remove-Item $f.FullName
            }
        }
    }
}
