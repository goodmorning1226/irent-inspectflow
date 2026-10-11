param(
    [string]$OutputPath = "$PSScriptRoot\..\assets\videos\full_vehicle_scan.mp4"
)

$ErrorActionPreference = 'Stop'

$ffmpeg = (Get-Command ffmpeg -ErrorAction Stop).Source
$frames = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\assets\frames'))
$resolvedOutput = [System.IO.Path]::GetFullPath($OutputPath)

# Each boundary is an intentional hard cut. The short hold before every cut is
# where the Flutter timeline hides the scan guide and shows the movement prompt.
$segments = @(
    @{ File = 'vehicle_right_side.png'; Duration = 3.333333 },
    @{ File = 'vehicle_front.png'; Duration = 3.10 },
    @{ File = 'exterior_damage_wide.png'; Duration = 2.55 },
    @{ File = 'exterior_damage_detail_center.png'; Duration = 1.10 },
    @{ File = 'exterior_damage_detail_left.png'; Duration = 1.10 },
    @{ File = 'exterior_damage_detail_right.png'; Duration = 1.10 },
    @{ File = 'exterior_damage_wide.png'; Duration = 0.60 },
    @{ File = 'vehicle_rear.png'; Duration = 3.133333 },
    @{ File = 'vehicle_front_seat.png'; Duration = 3.00 },
    @{ File = 'interior_dirty_best.png'; Duration = 4.766667 }
)

$arguments = @('-hide_banner', '-loglevel', 'warning', '-y')
foreach ($segment in $segments) {
    $inputPath = Join-Path $frames $segment.File
    if (-not (Test-Path -LiteralPath $inputPath)) {
        throw "Missing scan frame: $inputPath"
    }

    $arguments += @(
        '-loop', '1',
        '-t', $segment.Duration.ToString([Globalization.CultureInfo]::InvariantCulture),
        '-i', $inputPath
    )
}

$filterParts = @()
for ($index = 0; $index -lt $segments.Count; $index++) {
    $duration = $segments[$index].Duration.ToString([Globalization.CultureInfo]::InvariantCulture)
    $filterParts += "[$index`:v]scale=960:540:force_original_aspect_ratio=increase,crop=960:540,setsar=1,fps=30,trim=duration=$duration,setpts=PTS-STARTPTS[v$index]"
}

$inputs = (0..($segments.Count - 1) | ForEach-Object { "[v$_]" }) -join ''
$filterParts += "$inputs concat=n=$($segments.Count):v=1:a=0[outv]"
$arguments += @(
    '-filter_complex', ($filterParts -join ';'),
    '-map', '[outv]',
    '-r', '30',
    '-c:v', 'libx264',
    '-preset', 'medium',
    '-crf', '18',
    '-pix_fmt', 'yuv420p',
    '-movflags', '+faststart',
    '-an',
    $resolvedOutput
)

New-Item -ItemType Directory -Path (Split-Path $resolvedOutput) -Force | Out-Null
& $ffmpeg @arguments
if ($LASTEXITCODE -ne 0) {
    throw "FFmpeg exited with code $LASTEXITCODE"
}

$duration = & ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $resolvedOutput
Write-Output "Rendered hard-cut scan video: $resolvedOutput ($duration seconds)"
