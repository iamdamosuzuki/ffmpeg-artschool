<#
.DESCRIPTION
    creates a tile of a video file
.PARAMETER h
    display this help
.PARAMETER p
    previews in FFplay
.PARAMETER s
    saves to file with FFmpeg
.PARAMETER video
    path to the video
.PARAMETER columns
    number of columns [default: 4] Must be even.
.PARAMETER rows
    number of rows [default: 4] Must be even.
.PARAMETER outputResolution
    the resolution of the output file, formated as WxH (ex: 640x480)
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
    [System.IO.FileInfo]$video,

    [Parameter(Position=1, ParameterSetName="Run")]
    [ValidateScript({
        if(-Not ($_/2 -eq 0) ){
            throw "Columns must be an even number"
        }
        return $true
    })]
    [Int]
    $columns = 4,

    [Parameter(Position=2, ParameterSetName="Run")]
    [ValidateScript({
        if(-Not ($_/2 -eq 0) ){
            throw "Rows must be an even number"
        }
        return $true
    })]
    [Int]
    $rows = 4,
    
    [Parameter(Position=3, ParameterSetName="Run")]
    [ValidateScript({
        if(-Not ($_ -match "\d{2,4}x\d{2,4}") ){
            throw "Frame Size must be formated as WIDTHxHEIGHT\n"
        }
        return $true
    })]
    [String]$outputResolution = ""
)


# Display help

if (($h) -or ($PSBoundParameters.Values.Count -eq 0 -and $args.count -eq 0)){
    Get-Help $MyInvocation.MyCommand.Definition -detailed
    if (!$video) {
        exit
    }
}


# Create filter string
$filter = "scale=iw/$($columns):ih/$($rows):force_original_aspect_ratio=decrease,tile=$($columns)x$($rows):overlap=$($columns)*$($rows)-1:init_padding=$($columns)*$($rows)-1"

if ($outputResolution -ne "") {
    $filter = "$filter,scale=$($outputResolution -Split 'x' -Join ':')"
}

# Run command

if ($p) {
    $tempFile = New-TemporaryFile
    ffmpeg.exe -hide_banner -stats -y -i $video -c:v prores -profile:v 3 -vf $filter -f matroska $tempFile
    ffplay.exe $tempFile
    Remove-Item $tempFile
    
    Write-Host @"


*******START FFPLAY COMMANDS*******

ffmpeg.exe -hide_banner -stats -y -i $video -c:v prores -profile:v 3 -vf $filter -f matroska $tempFile
ffplay $tempFile.FullName
Remove-Item $tempFile

********END FFPLAY COMMANDS********


"@
}
else {
    ffmpeg.exe -hide_banner -i $video -c:v prores -profile:v 3 -vf $filter "$(Join-path (Get-Item $video).DirectoryName -ChildPath (Get-Item $video).BaseName)_tile$rows.mov"

    Write-Host @"


*******START FFMPEG COMMANDS*******

ffmpeg.exe -hide_banner -i $video -c:v prores -profile:v 3 -vf $filter "$(Join-path (Get-Item $video).DirectoryName -ChildPath (Get-Item $video).BaseName)_tile$rows.mov"

********END FFMPEG COMMANDS********


"@
}

