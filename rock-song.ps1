<#
.SYNOPSIS
    A sample rock song built with the New-MidiSong.ps1 toolkit.

.DESCRIPTION
    Writes rock.mid: a ~95 second song in E minor at 140 BPM with
      - rhythm guitar   (distortion guitar, power chords, palm-muted chugs)
      - lead guitar     (overdriven guitar, chorus hook and a solo)
      - bass            (picked bass, driving eighth notes)
      - drums           (rock beat, crashes, tom fills)

    Structure: Intro - Verse - Chorus - Verse - Chorus - Solo - Chorus - Outro

    Keep this file in the same folder as New-MidiSong.ps1.

.EXAMPLE
    ./rock-song.ps1
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\rock-song.ps1 -Tempo 160 -OutputPath fast-rock.mid
#>
param(
    [string] $OutputPath = 'rock.mid',
    [int]    $Tempo      = 140
)

# Dot-sourcing the toolkit runs its param block in this scope, which would overwrite
# variables named $OutputPath and $Tempo, so save ours first.
$songPath = $OutputPath
$bpm      = $Tempo
. "$PSScriptRoot\New-MidiSong.ps1" -LibraryOnly

$rng = [Random]::new(1977)          # fixed seed: the solo and dynamics are the same every run
function Get-Vel([int] $Base) { [math]::Max(1, [math]::Min(127, $Base + $rng.Next(-6, 7))) }

# ---------------------------------------------------------------------------
#  Band setup
# ---------------------------------------------------------------------------

$song   = New-MidiSong -Tempo $bpm -Title 'PowerShell Rock'
$rhythm = Add-MidiTrack $song -Name 'Rhythm Guitar' -Channel 0 -Instrument 30 -Volume 95   # distortion guitar
$lead   = Add-MidiTrack $song -Name 'Lead Guitar'   -Channel 1 -Instrument 29 -Volume 100  # overdriven guitar
$bass   = Add-MidiTrack $song -Name 'Bass'          -Channel 2 -Instrument 34 -Volume 110  # picked bass
$drums  = Add-MidiTrack $song -Name 'Drums'         -Channel 9 -Volume 110

# Lowest note of each power chord on the guitar (E2 = low E string). Bass plays an octave lower.
$roots = @{ E = 40; G = 43; A = 45; C = 48; D = 50 }

# ---------------------------------------------------------------------------
#  The music, written as text
#
#  Guitar bars:  "<chord> <style> <beats>, ..."   (each bar must add up to 4 beats)
#     chug = palm-muted eighth notes    hit = one strummed chord    ring = final chord, let ring
#  Lead bars:    "<note> <beats>, ..."   use r for a rest
# ---------------------------------------------------------------------------

$verseRiff = @(
    'E chug 4'
    'E chug 3, G hit 0.5, A hit 0.5'
    'G hit 2, A hit 2'
    'A chug 3, D hit 1'
)

$chorusChords = @(
    'C hit 2.5, C hit 1.5'
    'D hit 2.5, D hit 1.5'
    'E hit 2.5, E hit 1.5'
    'E hit 4'
    'C hit 2.5, C hit 1.5'
    'D hit 2.5, D hit 1.5'
    'E hit 2.5, E hit 1.5'
    'E hit 2, D hit 1, D chug 1'
)

$hook = @(
    'E5 1, D5 0.5, E5 0.5, G5 2'
    'F#5 1, E5 0.5, D5 0.5, A4 2'
    'B4 1, D5 0.5, E5 0.5, G5 1, F#5 1'
    'E5 3, r 1'
    'E5 1, D5 0.5, E5 0.5, G5 2'
    'F#5 1, E5 0.5, D5 0.5, A5 2'
    'B5 1, A5 0.5, G5 0.5, F#5 1, G5 1'
    'E5 2, B4 1, D5 1'
)

# ---------------------------------------------------------------------------
#  Players: turn the text above into notes
# ---------------------------------------------------------------------------

function Add-PowerChord([double] $Beat, [string] $Chord, [double] $Length, [int] $Velocity, [switch] $Muted) {
    $intervals = if ($Muted) { 0, 7 } else { 0, 7, 12 }   # muted chugs: just root + fifth
    foreach ($i in $intervals) {
        Add-MidiNote $rhythm ($roots[$Chord] + $i) -Beat $Beat -Length $Length -Velocity (Get-Vel $Velocity)
    }
}

function Add-GuitarBar([int] $Bar, [string] $Spec, [switch] $NoBass) {
    $start = $Bar * 4
    $at = 0.0
    foreach ($token in $Spec -split '\s*,\s*') {
        $chord, $style, $len = $token -split '\s+'
        $len = [double]$len
        $b = $start + $at

        switch ($style) {
            'chug' { for ($t = 0; $t -lt $len; $t += 0.5) { Add-PowerChord ($b + $t) $chord 0.3 $(if ($t -eq 0) { 100 } else { 76 }) -Muted } }
            'hit'  { Add-PowerChord $b $chord ($len - 0.05) 112 }
            'ring' { Add-PowerChord $b $chord $len 118 }
            default { throw "Unknown guitar style '$style' in '$Spec'" }
        }

        if (-not $NoBass) {
            $note = $roots[$chord] - 12
            if ($style -eq 'ring') {
                Add-MidiNote $bass $note -Beat $b -Length $len -Velocity 115
            } else {
                for ($t = 0; $t -lt $len; $t += 0.5) {
                    Add-MidiNote $bass $note -Beat ($b + $t) -Length 0.45 -Velocity (Get-Vel $(if ($t % 1 -eq 0) { 105 } else { 88 }))
                }
            }
        }
        $at += $len
    }
    if ($at -ne 4) { throw "Bar $Bar adds up to $at beats, not 4: '$Spec'" }
}

function Add-LeadBar([int] $Bar, [string] $Spec) {
    $at = 0.0
    foreach ($token in $Spec -split '\s*,\s*') {
        $note, $len = $token -split '\s+'
        $len = [double]$len
        if ($note -ne 'r') {
            Add-MidiNote $lead $note -Beat ($Bar * 4 + $at) -Length ($len * 0.95) -Velocity (Get-Vel 100)
        }
        $at += $len
    }
}

# Drum kit: 36 kick, 38 snare, 42 closed hat, 49 crash, 51 ride, 50/48/45/41 toms high to low
function Add-DrumBar([int] $Bar, [string] $Style, [switch] $Crash, [switch] $Fill) {
    $start = $Bar * 4
    $hits = switch ($Style) {
        'count'  { foreach ($q in 0..3) { , @(42, $q, 75) } }
        'verse'  {
            foreach ($e in 0..7) { , @(42, ($e * 0.5), $(if ($e % 2) { 60 } else { 88 })) }
            , @(36, 0, 112); , @(36, 2, 108); , @(36, 2.5, 100)
            , @(38, 1, 110); , @(38, 3, 110)
        }
        'chorus' {
            foreach ($e in 0..7) { , @(51, ($e * 0.5), $(if ($e % 2) { 72 } else { 95 })) }
            , @(36, 0, 115); , @(36, 1.5, 105); , @(36, 2, 112)
            , @(38, 1, 118); , @(38, 3, 118)
        }
        'stabs'  { foreach ($q in 0..3) { , @(36, $q, 120); , @(49, $q, 110) } }
        'roll'   { $toms = 50, 48, 45, 41; foreach ($s in 0..15) { , @($toms[[int][math]::Floor($s / 4)], ($s * 0.25), (70 + $s * 3)) } }
        'end'    { , @(36, 0, 127); , @(49, 0, 127); , @(57, 0, 120) }   # 57 = second crash
    }

    if ($Fill) {
        $hits = @($hits | Where-Object { $_[1] -lt 3 })
        $hits += , @(38, 3, 100); $hits += , @(38, 3.25, 105)
        $hits += , @(45, 3.5, 110); $hits += , @(41, 3.75, 118)
    }
    if ($Crash) { $hits += , @(49, 0, 118) }

    foreach ($h in $hits) {
        Add-MidiNote $drums $h[0] -Beat ($start + $h[1]) -Length 0.25 -Velocity (Get-Vel $h[2])
    }
}

# A guitar solo improvised from the E minor pentatonic scale (same every run thanks to the seed)
$pentatonic = 'E4', 'G4', 'A4', 'B4', 'D5', 'E5', 'G5', 'A5', 'B5', 'D6', 'E6' | ForEach-Object { ConvertTo-MidiNumber $_ }
$rhythmCells = @(@(1), @(0.5, 0.5), @(0.25, 0.25, 0.5), @(0.25, 0.25, 0.25, 0.25), @(0.75, 0.25), @(0.5, 0.25, 0.25))
$soloIdx = 5   # start on E5

function Add-SoloBar([int] $Bar, [switch] $Last) {
    if ($Last) {
        Add-MidiNote $lead 'E6' -Beat ($Bar * 4) -Length 3.8 -Velocity 112
        return
    }
    for ($beat = 0; $beat -lt 4; $beat++) {
        $cell = $rhythmCells[$rng.Next($rhythmCells.Count)]
        $at = 0.0
        foreach ($len in $cell) {
            # climb higher as the solo goes on, moving mostly by step
            $drift = if ($rng.NextDouble() -lt 0.55) { 1 } else { -1 }
            $script:soloIdx = [math]::Max(2, [math]::Min($pentatonic.Count - 1, $script:soloIdx + $drift * $rng.Next(1, 3)))
            Add-MidiNote $lead $pentatonic[$script:soloIdx] -Beat ($Bar * 4 + $beat + $at) -Length ($len * 0.9) -Velocity (Get-Vel $(if ($at -eq 0) { 108 } else { 90 }))
            $at += $len
        }
    }
}

# ---------------------------------------------------------------------------
#  Arrange the song
# ---------------------------------------------------------------------------

$bar = 0

function Add-Section([string[]] $Guitar, [string] $DrumStyle, [string[]] $Melody, [switch] $Solo) {
    for ($i = 0; $i -lt $Guitar.Count; $i++) {
        $last = $i -eq $Guitar.Count - 1
        Add-GuitarBar $script:bar $Guitar[$i]
        Add-DrumBar   $script:bar $DrumStyle -Crash:($i % 4 -eq 0) -Fill:$last
        if ($Melody)   { Add-LeadBar $script:bar $Melody[$i] }
        elseif ($Solo) { Add-SoloBar $script:bar -Last:$last }
        $script:bar++
    }
}

# Intro: guitar riff with hi-hat count, then the band kicks in
Add-GuitarBar 0 $verseRiff[0] -NoBass; Add-DrumBar 0 'count'
Add-GuitarBar 1 $verseRiff[1] -NoBass; Add-DrumBar 1 'count'
Add-GuitarBar 2 $verseRiff[2];         Add-DrumBar 2 'verse' -Crash
Add-GuitarBar 3 $verseRiff[3];         Add-DrumBar 3 'verse' -Fill
$bar = 4

Add-Section -Guitar ($verseRiff + $verseRiff) -DrumStyle 'verse'                 # Verse 1
Add-Section -Guitar $chorusChords             -DrumStyle 'chorus' -Melody $hook    # Chorus 1
Add-Section -Guitar ($verseRiff + $verseRiff) -DrumStyle 'verse'                 # Verse 2
Add-Section -Guitar $chorusChords             -DrumStyle 'chorus' -Melody $hook    # Chorus 2
Add-Section -Guitar $chorusChords             -DrumStyle 'chorus' -Solo          # Guitar solo
Add-Section -Guitar $chorusChords             -DrumStyle 'chorus' -Melody $hook    # Final chorus

# Outro: four big stabs, a tom roll over a held chord, and the last hit
Add-GuitarBar $bar 'E hit 1, E hit 1, E hit 1, E hit 1'; Add-DrumBar $bar 'stabs'; $bar++
Add-GuitarBar $bar 'E ring 4';                          Add-DrumBar $bar 'roll';  $bar++
Add-GuitarBar $bar 'E ring 4';                          Add-DrumBar $bar 'end';   $bar++

$out = Save-MidiSong $song $songPath
Write-Host "Wrote $($out.FullName)"
Write-Host ("  {0} bars at {1} BPM, about {2:N0} seconds" -f $bar, $bpm, ($bar * 4 * 60 / $bpm))
