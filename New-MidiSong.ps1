<#
.SYNOPSIS
    Generates Standard MIDI Files (.mid) from pure PowerShell - no external modules.

.DESCRIPTION
    Contains a small MIDI toolkit (songs, tracks, notes, chords, drums) plus a demo
    composer that writes a multi-track song: melody, chords, bass and drums over a
    chord progression. The melody is generated from the chord tones and scale, so
    every -Seed gives a different tune.

    Works in Windows PowerShell 5.1 and PowerShell 7+ on Windows, macOS and Linux.
    Open the resulting file in any media player, DAW, GarageBand, MuseScore, etc.

.EXAMPLE
    ./New-MidiSong.ps1
    Writes song.mid in the current folder.

.EXAMPLE
    ./New-MidiSong.ps1 -OutputPath tune.mid -Tempo 90 -Seed 42 -Progression 'Am','F','C','G' -Repeats 3

.EXAMPLE
    # Use the toolkit yourself: dot-source it, then build your own song
    . ./New-MidiSong.ps1 -LibraryOnly
    $song  = New-MidiSong -Tempo 100
    $piano = Add-MidiTrack $song -Name 'Piano' -Channel 0 -Instrument 0
    Add-MidiNote  $piano 'C4' -Beat 0 -Length 1
    Add-MidiChord $piano 'C' -Beat 1 -Length 3
    Save-MidiSong $song 'mine.mid'
#>
[CmdletBinding()]
param(
    [string]   $OutputPath  = 'song.mid',
    [ValidateRange(20, 300)]
    [int]      $Tempo       = 110,
    [int]      $Seed        = (Get-Random -Maximum 100000),
    [string[]] $Progression = @('C', 'Am', 'F', 'G'),
    [ValidateRange(1, 16)]
    [int]      $Repeats     = 2,
    [switch]   $NoDrums,
    [switch]   $LibraryOnly
)

# ---------------------------------------------------------------------------
#  Note / chord helpers
# ---------------------------------------------------------------------------

$script:NoteOffsets = @{ C = 0; D = 2; E = 4; F = 5; G = 7; A = 9; B = 11 }

function ConvertTo-MidiNumber {
    <# 'C4' -> 60, 'F#3' -> 54, 'Bb2' -> 46. Integers pass straight through. #>
    param([Parameter(Mandatory)] $Note)
    if ($Note -is [int]) { return $Note }
    if ("$Note" -notmatch '^([A-Ga-g])([#b]?)(-?\d)$') { throw "Bad note name: '$Note'" }
    $n = $script:NoteOffsets[$Matches[1].ToUpper()]
    if ($Matches[2] -eq '#') { $n++ } elseif ($Matches[2] -eq 'b') { $n-- }
    $value = ([int]$Matches[3] + 1) * 12 + $n
    if ($value -lt 0 -or $value -gt 127) { throw "Note out of MIDI range: '$Note'" }
    $value
}

$script:ChordShapes = @{
    ''     = 0, 4, 7          # major
    'm'    = 0, 3, 7          # minor
    '7'    = 0, 4, 7, 10      # dominant 7th
    'maj7' = 0, 4, 7, 11
    'm7'   = 0, 3, 7, 10
    'dim'  = 0, 3, 6
    'aug'  = 0, 4, 8
    'sus2' = 0, 2, 7
    'sus4' = 0, 5, 7
}

function Get-ChordNotes {
    <# 'Am' -> MIDI numbers of A minor with its root in the given octave. #>
    param([Parameter(Mandatory)][string] $Chord, [int] $Octave = 3)
    if ($Chord -notmatch '^([A-G])([#b]?)(.*)$') { throw "Bad chord name: '$Chord'" }
    $quality = $Matches[3]
    if (-not $script:ChordShapes.ContainsKey($quality)) { throw "Unknown chord quality '$quality' in '$Chord'" }
    $root = ConvertTo-MidiNumber "$($Matches[1])$($Matches[2])$Octave"
    foreach ($i in $script:ChordShapes[$quality]) { $root + $i }
}

# ---------------------------------------------------------------------------
#  Song model
# ---------------------------------------------------------------------------

function New-MidiSong {
    param([int] $Tempo = 120, [int] $TicksPerBeat = 480, [int] $BeatsPerBar = 4, [string] $Title = 'PowerShell Song')
    [pscustomobject]@{
        Tempo        = $Tempo
        TicksPerBeat = $TicksPerBeat
        BeatsPerBar  = $BeatsPerBar
        Title        = $Title
        Tracks       = [System.Collections.Generic.List[object]]::new()
    }
}

function Add-MidiTrack {
    <# Channel 0-15 (9 is drums). Instrument is a General MIDI program number 0-127. #>
    param(
        [Parameter(Mandatory)] $Song,
        [string] $Name = 'Track',
        [ValidateRange(0, 15)]  [int] $Channel = 0,
        [ValidateRange(0, 127)] [int] $Instrument = 0,
        [ValidateRange(0, 127)] [int] $Volume = 100
    )
    $track = [pscustomobject]@{
        Song    = $Song
        Name    = $Name
        Channel = $Channel
        Events  = [System.Collections.Generic.List[object]]::new()
    }
    # Order key keeps same-tick events sane: meta < setup < note-off < note-on
    $track.Events.Add([pscustomobject]@{ Tick = 0; Order = 1; Bytes = [byte[]]@((0xC0 -bor $Channel), $Instrument) })
    $track.Events.Add([pscustomobject]@{ Tick = 0; Order = 1; Bytes = [byte[]]@((0xB0 -bor $Channel), 7, $Volume) })
    $Song.Tracks.Add($track)
    $track
}

function Add-MidiNote {
    <# Beat and Length are in beats (quarter notes) and may be fractional. #>
    param(
        [Parameter(Mandatory)] $Track,
        [Parameter(Mandatory)] $Note,
        [Parameter(Mandatory)] [double] $Beat,
        [double] $Length = 1,
        [ValidateRange(1, 127)] [int] $Velocity = 90
    )
    $tpb   = $Track.Song.TicksPerBeat
    $pitch = ConvertTo-MidiNumber $Note
    $on    = [int][math]::Round($Beat * $tpb)
    $off   = [int][math]::Round(($Beat + $Length) * $tpb)
    if ($off -le $on) { $off = $on + 1 }
    $ch = $Track.Channel
    $Track.Events.Add([pscustomobject]@{ Tick = $on;  Order = 3; Bytes = [byte[]]@((0x90 -bor $ch), $pitch, $Velocity) })
    $Track.Events.Add([pscustomobject]@{ Tick = $off; Order = 2; Bytes = [byte[]]@((0x80 -bor $ch), $pitch, 0) })
}

function Add-MidiChord {
    param(
        [Parameter(Mandatory)] $Track,
        [Parameter(Mandatory)] [string] $Chord,
        [Parameter(Mandatory)] [double] $Beat,
        [double] $Length = 1,
        [int] $Octave = 4,
        [int] $Velocity = 70
    )
    foreach ($n in Get-ChordNotes $Chord -Octave $Octave) {
        Add-MidiNote $Track $n -Beat $Beat -Length $Length -Velocity $Velocity
    }
}

# ---------------------------------------------------------------------------
#  Binary writer
# ---------------------------------------------------------------------------

function Add-VarLen {
    <# MIDI variable-length quantity: 7 bits per byte, high bit = "more follows". #>
    param([System.Collections.Generic.List[byte]] $Buffer, [int] $Value)
    $stack = [System.Collections.Generic.Stack[byte]]::new()
    $stack.Push([byte]($Value -band 0x7F))
    $Value = $Value -shr 7
    while ($Value -gt 0) {
        $stack.Push([byte](($Value -band 0x7F) -bor 0x80))
        $Value = $Value -shr 7
    }
    while ($stack.Count) { $Buffer.Add($stack.Pop()) }
}

function Add-BigEndian {
    param([System.Collections.Generic.List[byte]] $Buffer, [long] $Value, [int] $Size)
    for ($i = $Size - 1; $i -ge 0; $i--) { $Buffer.Add([byte](($Value -shr (8 * $i)) -band 0xFF)) }
}

function New-MetaEvent {
    param([int] $Tick, [byte] $Type, [byte[]] $Data)
    $bytes = [System.Collections.Generic.List[byte]]::new()
    $bytes.Add(0xFF); $bytes.Add($Type)
    Add-VarLen $bytes $Data.Length
    $bytes.AddRange($Data)
    [pscustomobject]@{ Tick = $Tick; Order = 0; Bytes = $bytes.ToArray() }
}

function ConvertTo-TrackChunk {
    param($Events, [string] $Name)
    $all = [System.Collections.Generic.List[object]]::new()
    $all.Add((New-MetaEvent 0 0x03 ([Text.Encoding]::ASCII.GetBytes($Name))))
    foreach ($e in $Events) { $all.Add($e) }

    $body = [System.Collections.Generic.List[byte]]::new()
    $last = 0
    foreach ($e in ($all | Sort-Object Tick, Order)) {
        Add-VarLen $body ($e.Tick - $last)
        $body.AddRange([byte[]]$e.Bytes)
        $last = $e.Tick
    }
    $body.AddRange([byte[]]@(0x00, 0xFF, 0x2F, 0x00))   # end of track

    $chunk = [System.Collections.Generic.List[byte]]::new()
    $chunk.AddRange([Text.Encoding]::ASCII.GetBytes('MTrk'))
    Add-BigEndian $chunk $body.Count 4
    $chunk.AddRange($body)
    , $chunk.ToArray()
}

function Save-MidiSong {
    <# Writes a Format 1 MIDI file: a tempo/conductor track followed by one chunk per track. #>
    param([Parameter(Mandatory)] $Song, [Parameter(Mandatory)] [string] $Path)

    $file = [System.Collections.Generic.List[byte]]::new()
    $file.AddRange([Text.Encoding]::ASCII.GetBytes('MThd'))
    Add-BigEndian $file 6 4
    Add-BigEndian $file 1 2                          # format 1
    Add-BigEndian $file ($Song.Tracks.Count + 1) 2   # + conductor track
    Add-BigEndian $file $Song.TicksPerBeat 2

    $usPerBeat = [int](60000000 / $Song.Tempo)
    $denPow    = 2                                    # x/4 time
    $conductor = @(
        New-MetaEvent 0 0x51 ([byte[]]@((($usPerBeat -shr 16) -band 0xFF), (($usPerBeat -shr 8) -band 0xFF), ($usPerBeat -band 0xFF)))
        New-MetaEvent 0 0x58 ([byte[]]@($Song.BeatsPerBar, $denPow, 24, 8))
    )
    $file.AddRange((ConvertTo-TrackChunk $conductor $Song.Title))
    foreach ($t in $Song.Tracks) { $file.AddRange((ConvertTo-TrackChunk $t.Events $t.Name)) }

    $full = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    [IO.File]::WriteAllBytes($full, $file.ToArray())
    Get-Item $full
}

if ($LibraryOnly) { return }

# ---------------------------------------------------------------------------
#  Demo composer
# ---------------------------------------------------------------------------

# Accept 'Am,F,C,G' as one string too (e.g. when called via pwsh -File)
$Progression = @($Progression -split '[,\s]+' | Where-Object { $_ })

$rng   = [Random]::new($Seed)
$song  = New-MidiSong -Tempo $Tempo -Title "PowerShell Song (seed $Seed)"
$bpb   = $song.BeatsPerBar

#  General MIDI programs: 0 piano, 4 e-piano, 33 finger bass, 73 flute, 80 square lead
$lead  = Add-MidiTrack $song -Name 'Melody' -Channel 0 -Instrument 80 -Volume 95
$keys  = Add-MidiTrack $song -Name 'Chords' -Channel 1 -Instrument 4  -Volume 75
$bass  = Add-MidiTrack $song -Name 'Bass'   -Channel 2 -Instrument 33 -Volume 105
if (-not $NoDrums) { $drums = Add-MidiTrack $song -Name 'Drums' -Channel 9 -Instrument 0 -Volume 100 }

# Melody notes come from the key's scale (taken from the first chord's root)
$keyRoot  = (Get-ChordNotes $Progression[0] -Octave 5)[0]
$isMinor  = $Progression[0] -match '^[A-G][#b]?m(?!aj)'
$steps    = if ($isMinor) { 0, 2, 3, 5, 7, 8, 10 } else { 0, 2, 4, 5, 7, 9, 11 }
$scale    = foreach ($o in -1..1) { foreach ($s in $steps) { $keyRoot + 12 * $o + $s } }

# One-bar rhythms (note lengths in beats, each sums to 4)
$rhythms = @(
    @(1, 1, 1, 1), @(1.5, 0.5, 1, 1), @(0.5, 0.5, 1, 2), @(1, 0.5, 0.5, 2),
    @(2, 1, 1), @(0.5, 0.5, 0.5, 0.5, 1, 1), @(1, 1, 2), @(3, 1)
)

function Get-Nearest([int[]] $Pool, [int] $Target) {
    $Pool | Sort-Object { [math]::Abs($_ - $Target) } | Select-Object -First 1
}

$prev  = $keyRoot
$bars  = $Progression.Count * $Repeats
$motif = @{}   # reuse rhythms so repeats sound like a real phrase

for ($bar = 0; $bar -lt $bars; $bar++) {
    $chord  = $Progression[$bar % $Progression.Count]
    $start  = $bar * $bpb
    $tones  = Get-ChordNotes $chord -Octave 5
    $chordPool = $scale | Where-Object { ($_ % 12) -in ($tones | ForEach-Object { $_ % 12 }) }
    $final  = $bar -eq $bars - 1

    # --- Chords: sustained pad plus a soft offbeat stab
    Add-MidiChord $keys $chord -Beat $start -Length ($bpb - 0.1) -Octave 4 -Velocity 60
    if (-not $final) { Add-MidiChord $keys $chord -Beat ($start + 2.5) -Length 0.4 -Octave 4 -Velocity 45 }

    # --- Bass: root / fifth pattern, octave 2
    $root = (Get-ChordNotes $chord -Octave 2)[0]
    if ($final) {
        Add-MidiNote $bass $root -Beat $start -Length $bpb -Velocity 100
    } else {
        Add-MidiNote $bass $root        -Beat $start         -Length 1.4 -Velocity 100
        Add-MidiNote $bass $root        -Beat ($start + 1.5) -Length 0.5 -Velocity 80
        Add-MidiNote $bass ($root + 7)  -Beat ($start + 2)   -Length 1   -Velocity 90
        Add-MidiNote $bass ($root + 12) -Beat ($start + 3)   -Length 0.9 -Velocity 85
    }

    # --- Melody: chord tones on strong beats, stepwise scale motion between
    $slot = $bar % $Progression.Count
    if (-not $motif.ContainsKey($slot)) { $motif[$slot] = $rhythms[$rng.Next($rhythms.Count)] }
    $pattern = if ($final) { @(4) } else { $motif[$slot] }
    $beat = 0.0
    foreach ($len in $pattern) {
        $strong = ($beat % 1) -eq 0 -and ($beat % 2) -eq 0
        if ($final) {
            $pitch = Get-Nearest ($scale | Where-Object { ($_ % 12) -eq ($keyRoot % 12) }) $prev
        } elseif ($strong) {
            $pitch = Get-Nearest $chordPool ($prev + $rng.Next(-4, 5))
        } else {
            $idx   = [array]::IndexOf($scale, (Get-Nearest $scale $prev))
            $idx   = [math]::Max(0, [math]::Min($scale.Count - 1, $idx + $rng.Next(-2, 3)))
            $pitch = $scale[$idx]
        }
        $vel = if ($strong) { 100 } else { 80 }
        Add-MidiNote $lead $pitch -Beat ($start + $beat) -Length ($len * 0.9) -Velocity $vel
        $prev = $pitch
        $beat += $len
    }

    # --- Drums (GM kit: 36 kick, 38 snare, 42 closed hat, 46 open hat, 49 crash)
    if ($drums) {
        if ($bar % 4 -eq 0) { Add-MidiNote $drums 49 -Beat $start -Length 1 -Velocity 100 }
        if ($final) {
            Add-MidiNote $drums 36 -Beat $start -Length 1 -Velocity 110
            continue
        }
        foreach ($h in 0..7) {
            $hat = if ($h -eq 7 -and $bar % 2 -eq 1) { 46 } else { 42 }
            Add-MidiNote $drums $hat -Beat ($start + $h * 0.5) -Length 0.25 -Velocity $(if ($h % 2) { 60 } else { 85 })
        }
        foreach ($k in 0, 1.5, 2.5) { Add-MidiNote $drums 36 -Beat ($start + $k) -Length 0.25 -Velocity 110 }
        foreach ($s in 1, 3)        { Add-MidiNote $drums 38 -Beat ($start + $s) -Length 0.25 -Velocity 105 }
        if ($bar % 4 -eq 3) {       # little fill into the next phrase
            foreach ($f in 3.25, 3.5, 3.75) { Add-MidiNote $drums 38 -Beat ($start + $f) -Length 0.2 -Velocity 90 }
        }
    }
}

$out = Save-MidiSong $song $OutputPath
Write-Host "Wrote $($out.FullName)"
Write-Host ("  {0} bars at {1} BPM, progression {2}, seed {3}" -f $bars, $Tempo, ($Progression -join ' '), $Seed)
