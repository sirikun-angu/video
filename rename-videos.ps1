# rename-videos.ps1
# Run this INSIDE your cloned "video" repo folder (the one on branch main).
# Make sure vocabulary.csv is copied into this same folder before running.
#
# What it does:
#   - Reads vocabulary.csv (columns: vcid, unid, en, th, pos, videos, ...)
#   - For each row, looks for a file named "<th>.mp4" in the current folder
#   - If found, renames it (git mv) to the English name in the "videos" column
#   - If NOT found, prints a warning so you can rename that one manually
#
# After running, review the output, then commit + push.

$csvPath = ".\vocabulary.csv"

if (-not (Test-Path $csvPath)) {
    Write-Host "ERROR: vocabulary.csv not found in this folder. Copy it here first." -ForegroundColor Red
    exit
}

# The CSV has no header row, so we assign column names manually
$columns = "vcid","unid","en","th","pos","videos","emoji","sign_video","word_desc","image"
$rows = Import-Csv -Path $csvPath -Header $columns

$notFound = @()
$renamed = @()

foreach ($row in $rows) {
    $thName = $row.th.Trim()
    $engName = $row.videos.Trim()

    if ([string]::IsNullOrWhiteSpace($thName) -or [string]::IsNullOrWhiteSpace($engName)) {
        continue
    }

    $oldFile = "$thName.mp4"

    if (Test-Path -LiteralPath $oldFile) {
        if ($oldFile -eq $engName) {
            Write-Host "SKIP (already correct): $engName" -ForegroundColor Gray
            continue
        }
        git mv -- "$oldFile" "$engName"
        $renamed += "$oldFile  ->  $engName"
        Write-Host "RENAMED: $oldFile  ->  $engName" -ForegroundColor Green
    }
    else {
        $notFound += "th='$thName'  (expected file: $oldFile)  -->  should become: $engName"
    }
}

Write-Host ""
Write-Host "===================================================="
Write-Host "DONE. $($renamed.Count) files renamed."
Write-Host "===================================================="

if ($notFound.Count -gt 0) {
    Write-Host ""
    Write-Host "The following rows had NO exact filename match (probably the file name in the repo differs slightly from the 'th' column, e.g. has extra words in parentheses). Rename these manually with 'git mv':" -ForegroundColor Yellow
    Write-Host ""
    $notFound | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
}

Write-Host ""
Write-Host "Next steps if everything looks right:"
Write-Host '  git add -A'
Write-Host '  git commit -m "Rename video files to English names matching vocabulary table"'
Write-Host '  git push origin main'