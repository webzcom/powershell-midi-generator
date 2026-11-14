# New-MidiSong.ps1

A PowerShell script that writes Standard MIDI Files (`.mid`) from scratch. It doesn't need any modules, downloads or audio hardware: it builds the bytes of the file itself.

You can use it in two ways:

1. **As a song generator.** Run it, and it writes a four-track song (melody, chords, bass and drums) over a chord progression you choose.
2. **As a toolkit.** Load its functions and write your own music note by note.

Works in Windows PowerShell 5.1 and PowerShell 7+ on Windows, macOS and Linux. Open the resulting `.mid` files in Windows Media Player, GarageBand, MuseScore, Logic, FL Studio, Ableton, or any other program that plays MIDI.

---

## Quick start

```powershell
./New-MidiSong.ps1
```

This writes `song.mid` to the current folder and prints a line like:

```
Wrote C:\Music\song.mid
  8 bars at 110 BPM, progression C Am F G, seed 48213
```

Note the **seed**. Running again with the same seed gives you the same song.

### Windows: "running scripts is disabled on this system"

Windows blocks PowerShell scripts by default, so you may see this the first time:

```
./New-MidiSong.ps1 : File C:\scripts\midi\New-MidiSong.ps1 cannot be loaded because
running scripts is disabled on this system.
```

That's PowerShell's **execution policy**, not a problem with the script. Use whichever of these three options suits you. None of them needs administrator rights.

**Option 1: Bypass for a single run.** Put `powershell -ExecutionPolicy Bypass -File` in front of the usual command. Nothing changes on your system:

```powershell
powershell -ExecutionPolicy Bypass -File .\New-MidiSong.ps1
powershell -ExecutionPolicy Bypass -File .\New-MidiSong.ps1 -Progression Dm7,G7,Cmaj7,Cmaj7 -Tempo 120 -OutputPath jazz.mid
```

If you use PowerShell 7, start with `pwsh` instead of `powershell`. When you leave out `-OutputPath`, the `.mid` file is saved in the folder you're in.

**Option 2: Bypass for the current window.** Run this once, and then the plain `./New-MidiSong.ps1` commands work until you close the window:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
./New-MidiSong.ps1 -Progression Dm7,G7,Cmaj7,Cmaj7 -Tempo 120 -OutputPath jazz.mid
```

**Option 3: Allow your own scripts permanently.** This is the setting most people use:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
Unblock-File .\New-MidiSong.ps1
```

`RemoteSigned` runs scripts on your own computer but blocks downloaded ones unless they're signed. `Unblock-File` marks this downloaded script as trusted. Afterwards, `./New-MidiSong.ps1` works in every window.

If Option 3 says the setting is *"overridden by a policy defined at a more specific scope"*, your computer's policy is managed by Group Policy (common on work PCs). Options 1 and 2 still work.

To check your current settings, run `Get-ExecutionPolicy -List`.

---

## Generating songs

| Parameter      | Default           | What it does |
|----------------|-------------------|--------------|
| `-OutputPath`  | `song.mid`        | Where to write the file. |
| `-Tempo`       | `110`             | Speed in beats per minute (20–300). |
| `-Seed`        | random            | Picks the melody. Same seed + same settings = same song. |
| `-Progression` | `C, Am, F, G`     | The chords, one per bar. |
| `-Repeats`     | `2`               | How many times the progression plays (1–16). |
| `-NoDrums`     | off               | Leave out the drum track. |
| `-LibraryOnly` | off               | Load the functions without generating a song (see below). |

### Examples

```powershell
# A slower, sadder song in A minor, played three times through
./New-MidiSong.ps1 -Progression Am,F,C,G -Tempo 90 -Repeats 3 -OutputPath sad.mid

# A jazzy progression with seventh chords
./New-MidiSong.ps1 -Progression Dm7,G7,Cmaj7,Cmaj7 -Tempo 120 -OutputPath jazz.mid

# The classic 12-bar blues, no drums
./New-MidiSong.ps1 -Progression C7,C7,C7,C7,F7,F7,C7,C7,G7,F7,C7,G7 -Repeats 1 -NoDrums

# Keep a tune you liked, but slow it down
./New-MidiSong.ps1 -Seed 48213 -Tempo 80
```

The same examples with the execution policy bypassed, for when scripts are blocked (see [above](#windows-running-scripts-is-disabled-on-this-system)):

```powershell
powershell -ExecutionPolicy Bypass -File .\New-MidiSong.ps1 -Progression Am,F,C,G -Tempo 90 -Repeats 3 -OutputPath sad.mid
powershell -ExecutionPolicy Bypass -File .\New-MidiSong.ps1 -Progression Dm7,G7,Cmaj7,Cmaj7 -Tempo 120 -OutputPath jazz.mid
powershell -ExecutionPolicy Bypass -File .\New-MidiSong.ps1 -Progression C7,C7,C7,C7,F7,F7,C7,C7,G7,F7,C7,G7 -Repeats 1 -NoDrums
powershell -ExecutionPolicy Bypass -File .\New-MidiSong.ps1 -Seed 48213 -Tempo 80
```

### How the generator writes music

- **Key.** The first chord sets the key. If it's a minor chord (`Am`, `Em7`…), the melody uses the minor scale; otherwise major.
- **Melody.** On strong beats it picks a note from the current chord; between them it steps up or down the scale. Each bar's rhythm is reused when that chord comes around again, so repeats sound like a phrase rather than random notes. The last bar holds the key's home note.
- **Chords.** Electric piano, held for the bar, plus a soft stab on the "and" of beat 3.
- **Bass.** Root, root, fifth, octave: a simple pattern that follows the chords.
- **Drums.** Kick, snare on beats 2 and 4, eighth-note hi-hats, a crash every four bars, and a short snare fill leading into each new phrase.

---

## Composing your own song

Load the functions into your session with `-LibraryOnly`. Note the dot and space at the start; that's what keeps the functions around after the script finishes:

```powershell
. ./New-MidiSong.ps1 -LibraryOnly
```

> **If scripts are blocked:** run `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` first, then the line above. The single-run `powershell -ExecutionPolicy Bypass -File` form doesn't work here: it runs in a separate PowerShell that closes when it finishes, so the functions disappear with it.
>
> To bypass the policy and also run your own song script in one step, save your song code in a file such as `mysong.ps1` next to `New-MidiSong.ps1`. Start that file with `. "$PSScriptRoot\New-MidiSong.ps1" -LibraryOnly`, which finds the toolkit no matter which folder you run from. Then run:
>
> ```powershell
> powershell -ExecutionPolicy Bypass -File .\mysong.ps1
> ```

Every song is built the same way:

1. **Create a song** with `New-MidiSong`.
2. **Add tracks** with `Add-MidiTrack`, one per instrument.
3. **Add notes and chords** to the tracks with `Add-MidiNote` and `Add-MidiChord`.
4. **Save** with `Save-MidiSong`.

### Your first song: "Twinkle, Twinkle, Little Star"

```powershell
. ./New-MidiSong.ps1 -LibraryOnly

$song  = New-MidiSong -Tempo 100 -Title 'Twinkle Twinkle'
$piano = Add-MidiTrack $song -Name 'Piano' -Channel 0 -Instrument 0

# Each entry is: note, length in beats
$melody = @(
    @('C4',1), @('C4',1), @('G4',1), @('G4',1), @('A4',1), @('A4',1), @('G4',2),
    @('F4',1), @('F4',1), @('E4',1), @('E4',1), @('D4',1), @('D4',1), @('C4',2)
)

$beat = 0
foreach ($n in $melody) {
    Add-MidiNote $piano $n[0] -Beat $beat -Length $n[1]
    $beat += $n[1]
}

Save-MidiSong $song 'twinkle.mid'
```

The trick is the `$beat` counter: each note starts where the last one ended.

### Adding chords and bass

Add more tracks to the same song. Each one needs its own **channel** so it can have its own instrument. This continues the example above:

```powershell
$strings = Add-MidiTrack $song -Name 'Strings' -Channel 1 -Instrument 48 -Volume 70
$bass    = Add-MidiTrack $song -Name 'Bass'    -Channel 2 -Instrument 32

# One chord every 2 beats under the melody
$chords = 'C','F','C','C','F','C','G','C'
for ($i = 0; $i -lt $chords.Count; $i++) {
    Add-MidiChord $strings $chords[$i] -Beat ($i * 2) -Length 2 -Octave 3

    $root = (Get-ChordNotes $chords[$i] -Octave 2)[0]   # lowest note of the chord
    Add-MidiNote $bass $root -Beat ($i * 2) -Length 2
}

Save-MidiSong $song 'twinkle.mid'
```

### Adding drums

Drums always go on **channel 9**. On that channel the "note" picks which drum plays, not a pitch (see the [drum map](#drum-map)):

```powershell
$drums = Add-MidiTrack $song -Name 'Drums' -Channel 9

for ($bar = 0; $bar -lt 4; $bar++) {
    $start = $bar * 4
    Add-MidiNote $drums 36 -Beat $start       -Length 0.25 -Velocity 110   # kick
    Add-MidiNote $drums 38 -Beat ($start + 1) -Length 0.25                 # snare
    Add-MidiNote $drums 36 -Beat ($start + 2) -Length 0.25 -Velocity 110   # kick
    Add-MidiNote $drums 38 -Beat ($start + 3) -Length 0.25                 # snare
    foreach ($h in 0..7) {
        Add-MidiNote $drums 42 -Beat ($start + $h * 0.5) -Length 0.25 -Velocity 60   # hi-hat
    }
}

Save-MidiSong $song 'twinkle.mid'
```

### Tips for composing

- **Time is measured in beats**, counted from the start of the song. In 4/4 time, bar 1 starts at beat 0, bar 2 at beat 4, bar 3 at beat 8, and so on, so a bar starts at beat `$bar * 4`.
- **Fractions are fine.** `0.5` is an eighth note, `0.25` a sixteenth, `1.5` a dotted quarter, `0.333` an eighth-note triplet.
- **Leave a little gap** for detached notes: `-Length 0.9` instead of `1` sounds less smeared.
- **Velocity is loudness and attack** (1–127). Accent the strong beats (100–110) and play the rest softer (60–80); it makes a big difference.
- **Notes can overlap.** Add several notes at the same beat to build your own chord voicings.
- **Use loops for repeats** rather than typing a section twice: wrap a section in `foreach ($rep in 0..3) { ... }` and offset each `-Beat` by `$rep * 16`.
- **Rests** are just gaps: move `$beat` forward without adding a note.
- **Reload after editing** the script by dot-sourcing it again.

---

## Function reference

### `New-MidiSong`
Creates an empty song.

| Parameter       | Default             | Notes |
|-----------------|---------------------|-------|
| `-Tempo`        | `120`               | Beats per minute. |
| `-BeatsPerBar`  | `4`                 | Sets the time signature (`3` = 3/4 waltz). The bottom number is always 4. |
| `-Title`        | `'PowerShell Song'` | Stored in the file; many programs display it. |
| `-TicksPerBeat` | `480`               | Timing resolution. Rarely needs changing. |

### `Add-MidiTrack`
Adds an instrument track to a song and returns it.

| Parameter     | Default   | Notes |
|---------------|-----------|-------|
| `-Song`       | required  | The song from `New-MidiSong` (first positional argument). |
| `-Name`       | `'Track'` | Shown in music programs. |
| `-Channel`    | `0`       | 0–15. Give each instrument its own channel. **9 is drums.** |
| `-Instrument` | `0`       | General MIDI program 0–127 (see [instruments](#instruments)). Ignored on channel 9. |
| `-Volume`     | `100`     | Track volume 0–127. |

### `Add-MidiNote`
Adds one note to a track.

| Parameter   | Default  | Notes |
|-------------|----------|-------|
| `-Track`    | required | First positional argument. |
| `-Note`     | required | A name like `'C4'`, `'F#3'`, `'Bb2'`, or a MIDI number (60 = middle C). Second positional argument. |
| `-Beat`     | required | When it starts, in beats from the start of the song. |
| `-Length`   | `1`      | How long it lasts, in beats. |
| `-Velocity` | `90`     | How hard it's played, 1–127. |

### `Add-MidiChord`
Adds every note of a chord at once.

| Parameter   | Default  | Notes |
|-------------|----------|-------|
| `-Track`    | required | |
| `-Chord`    | required | A chord name such as `'Am'` or `'G7'` (see [chords](#chord-names)). |
| `-Beat`     | required | |
| `-Length`   | `1`      | |
| `-Octave`   | `4`      | Octave of the chord's root note. |
| `-Velocity` | `70`     | |

### `Save-MidiSong`
Writes the song to disk and returns the file. Usage: `Save-MidiSong $song 'name.mid'`. Overwrites any existing file.

### Helpers
- `ConvertTo-MidiNumber 'A4'` → `69`. Converts a note name to its MIDI number.
- `Get-ChordNotes 'Am' -Octave 3` → `57, 60, 64`. Lists a chord's notes, handy for bass lines and arpeggios:

  ```powershell
  # Arpeggiate a C major 7 chord in eighth notes
  $b = 0
  foreach ($n in Get-ChordNotes 'Cmaj7' -Octave 4) {
      Add-MidiNote $piano $n -Beat $b -Length 0.5
      $b += 0.5
  }
  ```

---

## Music reference

### Note names

A note name is a letter, an optional sharp (`#`) or flat (`b`), and an octave number. `C4` is middle C (MIDI 60); each octave runs C to B, so `B3` is just below middle C and `C5` is an octave above.

| Name | C4 | D4 | E4 | F4 | G4 | A4 | B4 | C5 |
|------|----|----|----|----|----|----|----|----|
| MIDI | 60 | 62 | 64 | 65 | 67 | 69 | 71 | 72 |

Sharps and flats: `C#4` = `Db4` = 61, `F#4` = `Gb4` = 66, `Bb3` = 58.

Useful ranges: bass lines around octave 2, chords around octave 3–4, melodies around octave 4–5.

### Chord names

A root note (uppercase, with optional `#` or `b`) followed by a quality:

| Suffix  | Chord          | Example  |
|---------|----------------|----------|
| *(none)*| Major          | `C`, `F#`, `Bb` |
| `m`     | Minor          | `Am`, `C#m` |
| `7`     | Dominant 7th   | `G7` |
| `maj7`  | Major 7th      | `Cmaj7` |
| `m7`    | Minor 7th      | `Dm7` |
| `dim`   | Diminished     | `Bdim` |
| `aug`   | Augmented      | `Caug` |
| `sus2`  | Suspended 2nd  | `Dsus2` |
| `sus4`  | Suspended 4th  | `Gsus4` |

To add more, edit the `$script:ChordShapes` table in the script. Each entry lists the chord's notes as semitones above the root (for example, `'6' = 0, 4, 7, 9`).

### Progressions worth trying

| Feel              | Progression |
|-------------------|-------------|
| Pop / anthem      | `C, G, Am, F` |
| 50s doo-wop       | `C, Am, F, G` |
| Melancholy        | `Am, F, C, G` |
| Jazz ii–V–I       | `Dm7, G7, Cmaj7, Cmaj7` |
| Dreamy            | `Fmaj7, Em7, Dm7, Cmaj7` |
| Epic minor        | `Am, G, F, E` |
| Blues (12 bars)   | `C7, C7, C7, C7, F7, F7, C7, C7, G7, F7, C7, G7` |

### Instruments

General MIDI program numbers for `-Instrument`. A few favorites:

| #  | Instrument        | #  | Instrument          | #  | Instrument      |
|----|-------------------|----|---------------------|----|-----------------|
| 0  | Acoustic piano    | 32 | Acoustic bass       | 56 | Trumpet         |
| 4  | Electric piano    | 33 | Finger bass         | 61 | Brass section   |
| 11 | Vibraphone        | 38 | Synth bass          | 65 | Alto sax        |
| 19 | Church organ      | 40 | Violin              | 71 | Clarinet        |
| 24 | Nylon guitar      | 42 | Cello               | 73 | Flute           |
| 25 | Steel guitar      | 46 | Harp                | 80 | Square lead     |
| 29 | Overdriven guitar | 48 | String ensemble     | 81 | Sawtooth lead   |
| 30 | Distortion guitar | 52 | Choir "aahs"        | 88 | Fantasia pad    |

The full list of 128 is easy to find by searching "General MIDI instrument list". Note that it's usually printed numbered 1–128, so subtract 1.

### Drum map

On channel 9, use these note numbers:

| #  | Drum            | #  | Drum            | #  | Drum           |
|----|-----------------|----|-----------------|----|----------------|
| 35 | Acoustic kick   | 42 | Closed hi-hat   | 49 | Crash cymbal   |
| 36 | Kick            | 44 | Pedal hi-hat    | 51 | Ride cymbal    |
| 37 | Side stick      | 45 | Low tom         | 54 | Tambourine     |
| 38 | Snare           | 46 | Open hi-hat     | 56 | Cowbell        |
| 39 | Hand clap       | 48 | High-mid tom    | 70 | Maracas        |
| 41 | Low floor tom   | 50 | High tom        | 75 | Claves         |

---

## Troubleshooting

- **"Running scripts is disabled on this system".** The execution policy is blocking scripts. Run with `powershell -ExecutionPolicy Bypass -File .\New-MidiSong.ps1`, or see [the options above](#windows-running-scripts-is-disabled-on-this-system).
- **No sound when opening the file.** MIDI files contain notes, not audio, so the player provides the instrument sounds. Windows and macOS have built-in synths; on Linux, install a synth such as `timidity` or open the file in MuseScore.
- **"Bad note name" / "Bad chord name".** Check the spelling: notes need an octave (`C4`, not `C`), and chord roots must be uppercase (`Am`, not `am`).
- **"Unknown chord quality".** The suffix isn't in the chord table; see [Chord names](#chord-names).
- **Two instruments sound the same.** They're probably on the same channel. Give each track its own channel.
- **Drums sound like a piano.** The drum track must use channel 9.
- **Functions not found after `-LibraryOnly`.** Start the line with a dot and a space: `. ./New-MidiSong.ps1 -LibraryOnly`.
