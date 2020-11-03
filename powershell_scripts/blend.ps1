<#
.DESCRIPTION
    Blends two files together with an arbitrary blend mode
.PARAMETER h
    display this help
.PARAMETER p
    previews in FFplay
.PARAMETER s
    saves to file with FFmpeg
.PARAMETER input1
    path to the first video
.PARAMETER input2
    path to the second video
.PARAMETER blendMode
    type of blend mode to use. Options include: addition, addition128, 
    grainmerge, and, average, burn, darken, difference, difference128, grainextract,
    divide, dodge, freeze, exclusion, extremity, glow, hardlight, hardmix, heat,
    lighten, linearlight, multiply, multiply128, negation, normal, or, overlay,
    phoenix, pinlight, reflect, screen, softlight, subtract, vividlight, xor   
#>

# Parse arguments
Param(
    [Parameter(ParameterSetName="Help")]
    [Parameter(ParameterSetName="Run")]
    [Switch]
    $h,

    [Parameter(ParameterSetName="Run")]
    [Switch]
    $p,

    [Parameter(ParameterSetName="Run")]
    [Switch]
    $s = $true,

    [Parameter(Position=0, Mandatory, ParameterSetName="Run")]
    [ValidateScript({
        if(-Not ($_ | Test-Path) ){
            throw "File or folder does not exist" 
        }
        if(-Not ($_ | Test-Path -PathType Leaf) ){
            throw "The Path argument must be a file. Folder paths are not allowed."
        }
        return $true
    })]
    [System.IO.FileInfo]$input1,

    [Parameter(Position=1, Mandatory, ParameterSetName="Run")]
    [ValidateScript({
        if(-Not ($_ | Test-Path) ){
            throw "File or folder does not exist" 
        }
        if(-Not ($_ | Test-Path -PathType Leaf) ){
            throw "The Path argument must be a file. Folder paths are not allowed."
        }
        return $true
    })]
    [System.IO.FileInfo]$input2,

    [Parameter(Position=2, ParameterSetName="Run")]
    [ValidateSet("addition", "addition128", "grainmerge", "and", "average", "burn", "darken", "difference", "difference128", "grainextract",
    "divide", "dodge", "freeze", "exclusion", "extremity", "glow", "hardlight", "hardmix", "heat",
    "lighten", "linearlight", "multiply", "multiply128", "negation", "normal", "or", "overlay",
    "phoenix", "pinlight", "reflect", "screen", "softlight", "subtract", "vividlight", "xor")]
    [string]$blendMode = "addition128"
)


# Display help

if (($h) -or ($PSBoundParameters.Values.Count -eq 0 -and $args.count -eq 0)){
    Get-Help $MyInvocation.MyCommand.Definition -detailed
    if (!$input1) {
        exit
    }
}


# Create filter string

$filter = "[1:v]format=gbrp10le[v1];[0:v]format=gbrp10le[v0];[v1][v0]scale2ref[v1][v0];[v0][v1]blend=all_mode=$($blendMode),format=yuv422p10le [v]"


# Run command

if ($p) {
    $tempFile = New-TemporaryFile
    ffmpeg.exe -hide_banner -stats -y -i $input1 -i $input2 -c:v prores -profile:v 3 -filter_complex $filter -map "[v]" -f matroska $tempFile
    ffplay.exe $tempFile
    
    Write-Host "`n`n*******START FFPLAY COMMANDS*******`n"
    Write-Host "ffmpeg.exe -hide_banner -stats -y -i $input1 -i $input2 -c:v prores -profile:v 3 -filter_complex `'$($filter)`'' -map '[v]' -f matroska $tempFile`n"
    Write-Host "ffplay $tempFile.FullName`n"
    Write-Host "`n********END FFPLAY COMMANDS********`n`n"
}
else {
    ffmpeg.exe -hide_banner -i $input1 -i $input2 -c:v prores -profile:v 3 -filter_complex $filter -map "[v]" "$((Get-Item $input1).Basename)_blend_$($blendMode).mov"

    Write-Host "`n`n*******START FFMPEG COMMANDS*******`n"
    Write-Host "ffmpeg.exe -hide_banner -i $input1 -i $input2 -c:v prores -profile:v 3 -filter_complex `"$($filter)`" -map `"[v]`" `"$((Get-Item $input1).Basename)_blend_$($blendMode).mov`"`n"
    Write-Host "`n********END FFMPEG COMMANDS********`n`n"
}

