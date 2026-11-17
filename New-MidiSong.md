# New-MidiSong.ps1: usage and examples

`New-MidiSong.ps1` writes Standard MIDI Files (`.mid`) using nothing but PowerShell. You can call it in two ways:

- **As a song generator:** run it with options, and it composes a four-track song (melody, chords, bass, drums) over a chord progression you choose.
- **As a toolkit:** load its functions with `-LibraryOnly` and write music note by note.

This page is a collection of ready-to-run examples for both. For the full reference (every function, note names, chord types, instruments and drums), see the [README](README.md).

> **Scripts blocked on Windows?** Every `./New-MidiSong.ps1 ...` example below also works as
> `powershell -ExecutionPolicy Bypass -File .\New-MidiSong.ps1 ...`.
> See [Calling it from anywhere](#calling-it-from-anywhere) and the README's [execution policy section](README.md#windows-running-scripts-is-disabled-on-this-system).

---

## Parameters at a glance

```powershell
./New-MidiSong.ps1 [-OutputPath <file>] [-Tempo <20-300>] [-Seed <number>]
                   [-Progression <chords>] [-Repeats <1-16>] [-NoDrums] [-LibraryOnly]
```

| Parameter      | Default        | Description |
|----------------|----------------|-------------|
| `-OutputPath`  | `song.mid`     | File to write. Relative paths are relative to your current folder. |
| `-Tempo`       | `110`          | Beats per minute. |
| `-Seed`        | random         | Picks the melody. Same seed + same options = same song. |
| `-Progression` | `C,Am,F,G`     | Chords, one per bar. Separate them with commas or spaces. |
| `-Repeats`     | `2`            | Times through the progression. |
| `-NoDrums`     | off            | Leave out the drum track. |
| `-LibraryOnly` | off            | Load the toolkit functions without writing a song. |

Each run prints what it made:

```
Wrote C:\scripts\midi\song.mid
  8 bars at 110 BPM, progression C Am F G, seed 48213
```

---

## Generator examples

### The basics

```powershell
# 1. Default song: C-Am-F-G at 110 BPM, random melody, saved as song.mid
./New-MidiSong.ps1

# 2. Choose the file name
./New-MidiSong.ps1 -OutputPath my-first-song.mid

# 3. Faster and longer: 4 times through the progression at 140 BPM
./New-MidiSong.ps1 -Tempo 140 -Repeats 4 -OutputPath longer.mid
```

### Styles and moods

```powershell
# 4. Pop anthem (the I-V-vi-IV progression behind countless hits)
./New-MidiSong.ps1 -Progression C,G,Am,F -Tempo 118 -Repeats 4 -OutputPath pop.mid

# 5. Slow minor ballad, no drums
./New-MidiSong.ps1 -Progression Am,F,C,G -Tempo 72 -NoDrums -OutputPath ballad.mid

# 6. Jazz ii-V-I turnaround with seventh chords
./New-MidiSong.ps1 -Progression Dm7,G7,Cmaj7,A7 -Tempo 132 -Repeats 3 -OutputPath jazz.mid

# 7. 12-bar blues, twice through
./New-MidiSong.ps1 -Progression C7,C7,C7,C7,F7,F7,C7,C7,G7,F7,C7,G7 -Tempo 100 -OutputPath blues.mid

# 8. Dreamy, floating major-seventh chords
./New-MidiSong.ps1 -Progression Fmaj7,Em7,Dm7,Cmaj7 -Tempo 84 -OutputPath dreamy.mid

# 9. Dark and dramatic, ending on a major chord for tension
./New-MidiSong.ps1 -Progression Em,C,D,B7 -Tempo 96 -OutputPath dramatic.mid

# 10. Folk / campfire in G with a suspended chord
./New-MidiSong.ps1 -Progression G,Dsus4,Em,C -Tempo 104 -OutputPath folk.mid
```

### Other keys: sharps and flats

```powershell
# 11. Flat key (B-flat major)
./New-MidiSong.ps1 -Progression Bb,F,Gm,Eb -OutputPath b-flat.mid

# 12. Sharp key (F-sharp minor)
./New-MidiSong.ps1 -Progression F#m,D,A,E -Tempo 124 -OutputPath f-sharp-minor.mid
```

The first chord sets the key: start with a minor chord for a minor-key melody.

### Writing the progression

```powershell
# 13. Commas or spaces both work. Quote the progression if you use spaces.
./New-MidiSong.ps1 -Progression Em,C,G,D
./New-MidiSong.ps1 -Progression "Em C G D"

# 14. Keep progressions in variables
$sad   = 'Am','F','C','G'
$happy = 'C','G','Am','F'
./New-MidiSong.ps1 -Progression $sad -OutputPath sad.mid
./New-MidiSong.ps1 -Progression $happy -OutputPath happy.mid

# 15. Hold a chord for two bars by listing it twice
./New-MidiSong.ps1 -Progression C,C,F,F,G,G,C,C -Repeats 1 -OutputPath held-chords.mid
```

### Seeds: keeping a tune you like

Every run prints its seed. Pass the seed back in to get the same melody again:

```powershell
# 16. Recreate a song exactly
./New-MidiSong.ps1 -Seed 1234 -OutputPath keeper.mid

# 17. Same melody, different tempo
./New-MidiSong.ps1 -Seed 1234 -Tempo 160 -OutputPath keeper-fast.mid

# 18. Same melody, no drums
./New-MidiSong.ps1 -Seed 1234 -NoDrums -OutputPath keeper-quiet.mid
```

Changing `-Progression` or `-Repeats` changes the melody even with the same seed, because the melody follows the chords.

### Making lots of songs at once

```powershell
# 19. Five versions of the same progression, then pick your favorite
1..5 | ForEach-Object { ./New-MidiSong.ps1 -Seed $_ -OutputPath "take-$_.mid" }

# 20. Same song at three tempos
foreach ($bpm in 80, 110, 140) {
    ./New-MidiSong.ps1 -Seed 77 -Tempo $bpm -OutputPath "tempo-$bpm.mid"
}

# 21. One song per style, saved in a "songs" folder (the folder must exist)
New-Item -ItemType Directory -Force songs | Out-Null
$styles = @{
    pop    = 'C,G,Am,F'
    ballad = 'Am,F,C,G'
    jazz   = 'Dm7,G7,Cmaj7,Cmaj7'
    dreamy = 'Fmaj7,Em7,Dm7,Cmaj7'
}
foreach ($name in $styles.Keys) {
    ./New-MidiSong.ps1 -Progression $styles[$name] -OutputPath "songs/$name.mid"
}

# 22. A random progression from a pool of chords that sound good together in C
$pool  = 'C','Dm','Em','F','G','Am'
$chords = @('C') + @(1..3 | ForEach-Object { $pool | Get-Random })   # always start on C
./New-MidiSong.ps1 -Progression $chords -OutputPath random-chords.mid
```

---

## Calling it from anywhere

```powershell
# 23. Bypass the execution policy for one run (Windows PowerShell)
powershell -ExecutionPolicy Bypass -File .\New-MidiSong.ps1 -Progression Am,F,C,G -Tempo 90

# 24. Same thing in PowerShell 7
pwsh -ExecutionPolicy Bypass -File .\New-MidiSong.ps1 -Progression Am,F,C,G -Tempo 90

# 25. From another folder: give the full path to the script; the song lands in the current folder
& 'C:\scripts\midi\New-MidiSong.ps1' -OutputPath tune.mid

# 26. Built-in help (the examples written into the script)
Get-Help .\New-MidiSong.ps1 -Examples
Get-Help .\New-MidiSong.ps1 -Full
```

Example 23 also works from **Command Prompt (cmd.exe)**, a batch file, or Task Scheduler, since it starts PowerShell itself:

```bat
powershell -ExecutionPolicy Bypass -File C:\scripts\midi\New-MidiSong.ps1 -Progression Am,F,C,G -OutputPath C:\Music\song.mid
```

---

## Toolkit examples (`-LibraryOnly`)

Load the functions once per PowerShell window. The leading dot and space matter:

```powershell
. ./New-MidiSong.ps1 -LibraryOnly
```

If scripts are blocked, run `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` first.

Every toolkit song follows the same four steps: `New-MidiSong` → `Add-MidiTrack` → `Add-MidiNote` / `Add-MidiChord` → `Save-MidiSong`. **Beats** count from 0 at the start of the song; in 4/4, bar *n* starts at beat `(n - 1) * 4`.

### 27. Look things up at the prompt

```powershell
ConvertTo-MidiNumber 'C4'        # 60  (middle C)
ConvertTo-MidiNumber 'F#3'       # 54
Get-ChordNotes 'Am' -Octave 3    # 57, 60, 64
Get-ChordNotes 'G7' -Octave 3    # 55, 59, 62, 65
```

### 28. A C major scale

```powershell
$song  = New-MidiSong -Tempo 120
$piano = Add-MidiTrack $song -Name 'Piano'

$beat = 0
foreach ($n in 'C4','D4','E4','F4','G4','A4','B4','C5') {
    Add-MidiNote $piano $n -Beat $beat -Length 0.9
    $beat++
}
Save-MidiSong $song 'scale.mid'
```

### 29. A melody: "Ode to Joy"

Notes are written as `name:length` pairs to keep the tune readable:

```powershell
$song  = New-MidiSong -Tempo 108 -Title 'Ode to Joy'
$flute = Add-MidiTrack $song -Name 'Flute' -Instrument 73

$tune = 'E4:1 E4:1 F4:1 G4:1 G4:1 F4:1 E4:1 D4:1 C4:1 C4:1 D4:1 E4:1 E4:1.5 D4:0.5 D4:2'
$beat = 0
foreach ($pair in $tune -split ' ') {
    $note, $len = $pair -split ':'
    Add-MidiNote $flute $note -Beat $beat -Length ([double]$len * 0.95)
    $beat += [double]$len
}
Save-MidiSong $song 'ode-to-joy.mid'
```

### 30. Block chords

```powershell
$song  = New-MidiSong -Tempo 90
$organ = Add-MidiTrack $song -Name 'Organ' -Instrument 19

$bar = 0
foreach ($chord in 'C','Am','Dm7','G7') {
    Add-MidiChord $organ $chord -Beat ($bar * 4) -Length 4 -Octave 4
    $bar++
}
Save-MidiSong $song 'chords.mid'
```

### 31. Arpeggios (chord notes played one at a time)

```powershell
$song = New-MidiSong -Tempo 100
$harp = Add-MidiTrack $song -Name 'Harp' -Instrument 46

$beat = 0
foreach ($chord in 'Am','F','C','G') {
    $notes = Get-ChordNotes $chord -Octave 4
    $notes += $notes[0] + 12                 # add the octave on top
    foreach ($rep in 1..2) {                 # up the chord twice per bar
        foreach ($n in $notes) {
            Add-MidiNote $harp $n -Beat $beat -Length 0.5 -Velocity 80
            $beat += 0.5
        }
    }
}
Save-MidiSong $song 'arpeggios.mid'
```

### 32. A drum beat

Drums always use channel 9. The "note" picks the drum: 36 kick, 38 snare, 42 hi-hat, 49 crash.

```powershell
$song  = New-MidiSong -Tempo 96
$drums = Add-MidiTrack $song -Name 'Drums' -Channel 9

foreach ($bar in 0..7) {
    $s = $bar * 4
    if ($bar % 4 -eq 0) { Add-MidiNote $drums 49 -Beat $s -Length 1 }       # crash every 4 bars
    foreach ($k in 0, 2.5)  { Add-MidiNote $drums 36 -Beat ($s + $k) -Length 0.25 -Velocity 110 }
    foreach ($sn in 1, 3)   { Add-MidiNote $drums 38 -Beat ($s + $sn) -Length 0.25 -Velocity 105 }
    foreach ($h in 0..7)    { Add-MidiNote $drums 42 -Beat ($s + $h / 2) -Length 0.25 -Velocity 70 }
}
Save-MidiSong $song 'beat.mid'
```

### 33. A waltz in 3/4

Set `-BeatsPerBar 3`, and bars become 3 beats long: bar *n* starts at beat `(n - 1) * 3`.

```powershell
$song    = New-MidiSong -Tempo 150 -BeatsPerBar 3 -Title 'Little Waltz'
$piano   = Add-MidiTrack $song -Name 'Piano'
$strings = Add-MidiTrack $song -Name 'Strings' -Channel 1 -Instrument 48 -Volume 80

$bar = 0
foreach ($chord in 'C','G7','G7','C','F','C','G7','C') {
    $s    = $bar * 3
    $root = (Get-ChordNotes $chord -Octave 2)[0]
    Add-MidiNote  $piano $root -Beat $s -Length 1 -Velocity 95             # "oom"
    Add-MidiChord $piano $chord -Beat ($s + 1) -Length 0.8 -Octave 4       # "pah"
    Add-MidiChord $piano $chord -Beat ($s + 2) -Length 0.8 -Octave 4       # "pah"
    Add-MidiChord $strings $chord -Beat $s -Length 3 -Octave 3 -Velocity 55
    $bar++
}
Save-MidiSong $song 'waltz.mid'
```

### 34. A random pentatonic melody

The pentatonic scale has no "wrong" notes, so random choices still sound musical:

```powershell
$song = New-MidiSong -Tempo 90
$lead = Add-MidiTrack $song -Name 'Vibes' -Instrument 11
$pad  = Add-MidiTrack $song -Name 'Pad'   -Channel 1 -Instrument 88 -Volume 70

$scale = 'C4','D4','E4','G4','A4','C5','D5','E5' | ForEach-Object { ConvertTo-MidiNumber $_ }
$beat = 0
while ($beat -lt 16) {
    $len = 0.5, 0.5, 1, 1.5 | Get-Random
    Add-MidiNote $lead ($scale | Get-Random) -Beat $beat -Length $len -Velocity (Get-Random -Minimum 70 -Maximum 110)
    $beat += $len
}
Add-MidiChord $pad 'C' -Beat 0 -Length 8 -Octave 3
Add-MidiChord $pad 'Am' -Beat 8 -Length 8 -Octave 3
Save-MidiSong $song 'pentatonic.mid'
```

Run it again for a different tune. Put `Get-Random -SetSeed 42 | Out-Null` before the loop to make it repeatable.

### 35. A full song in its own script file

For anything bigger, put the song in its own `.ps1` file next to `New-MidiSong.ps1`. The [rock song](ROCK-SONG.md) is built this way. Start the file with:

```powershell
. "$PSScriptRoot\New-MidiSong.ps1" -LibraryOnly
```

Then run it with `powershell -ExecutionPolicy Bypass -File .\mysong.ps1`.

> **Watch out for variable names.** Loading the toolkit sets the variables `$OutputPath`, `$Tempo`, `$Seed`, `$Progression`, `$Repeats`, `$NoDrums` and `$LibraryOnly` to the script's defaults. Create your own variables with those names *after* the dot-sourcing line, or use different names (such as `$bpm`).

---

## See also

- [README.md](README.md): full reference for every function, plus note names, chord types, the instrument list and the drum map.
- [ROCK-SONG.md](ROCK-SONG.md): a complete multi-section rock song built with the toolkit.
- To turn any `.mid` into an `.mp3`, open it in MuseScore and export, or render it with FluidSynth and FFmpeg.
