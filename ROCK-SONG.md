# rock-song.ps1

A sample rock song written with the [New-MidiSong.ps1](README.md) toolkit. Running it writes **`rock.mid`**: about 94 seconds of rock in E minor at 140 BPM, with rhythm guitar, lead guitar, bass and drums.

It's meant to be read and changed. The music is written as plain text near the top of the script, so you can rewrite the riff, chords, melody or arrangement without touching the code that turns text into notes.

---

## Running it

Keep `rock-song.ps1` in the **same folder** as `New-MidiSong.ps1`, which it loads automatically.

```powershell
./rock-song.ps1
```

If Windows says *"running scripts is disabled on this system"*, use the bypass form instead (see the [README](README.md#windows-running-scripts-is-disabled-on-this-system) for other options):

```powershell
powershell -ExecutionPolicy Bypass -File .\rock-song.ps1
```

| Parameter     | Default    | What it does |
|---------------|------------|--------------|
| `-OutputPath` | `rock.mid` | Where to write the file. |
| `-Tempo`      | `140`      | Speed in beats per minute. Try 120 for heavier, 170 for punk. |

```powershell
powershell -ExecutionPolicy Bypass -File .\rock-song.ps1 -Tempo 170 -OutputPath punk.mid
```

The song is the same every time you run it, because the solo and the small velocity variations use a fixed random seed.

---

## What's in the song

### The band

| Track         | Instrument (GM #)        | Channel | Plays |
|---------------|--------------------------|---------|-------|
| Rhythm Guitar | Distortion guitar (30)   | 0       | Power chords and palm-muted chugs |
| Lead Guitar   | Overdriven guitar (29)   | 1       | The chorus hook and the solo |
| Bass          | Picked bass (34)         | 2       | Eighth notes on each chord's root, an octave below the guitar |
| Drums         | Standard kit             | 9       | Rock beat, crashes and fills |

### The arrangement

| Section      | Bars  | Starts at* | What happens |
|--------------|-------|-----------|--------------|
| Intro        | 1–4   | 0:00      | Guitar riff alone with a hi-hat count, then bass and drums kick in |
| Verse 1      | 5–12  | 0:07      | Verse riff twice, hi-hat beat |
| Chorus 1     | 13–20 | 0:21      | Big open chords, ride cymbal, lead guitar hook |
| Verse 2      | 21–28 | 0:34      | |
| Chorus 2     | 29–36 | 0:48      | |
| Guitar solo  | 37–44 | 1:02      | Chorus chords with an improvised pentatonic solo |
| Final chorus | 45–52 | 1:15      | |
| Outro        | 53–55 | 1:29      | Four big hits, a tom roll over a held chord, final crash |

\* At the default 140 BPM.

In every section a crash cymbal marks bar 1 and bar 5, and the last bar ends with a drum fill leading into the next section.

### The chords

The song is in **E minor**. The verse riff moves between **E5, G5, A5 and D5**. The chorus climbs **C5 → D5 → E5**, the "bVI–bVII–i" move behind many rock anthems. (The `5` means a *power chord*: just the root and fifth, with no major or minor third, which is why it sounds so solid through distortion.)

---

## How the music is written

Open `rock-song.ps1` and look for the section headed **"The music, written as text"**. Everything you'd want to change lives there.

### Guitar bars

Each bar is one line of text: a list of `chord style beats` entries, separated by commas.

```powershell
$verseRiff = @(
    'E chug 4'                          # bar 1: chug on E for the whole bar
    'E chug 3, G hit 0.5, A hit 0.5'    # bar 2: chug, then two quick chord stabs
    'G hit 2, A hit 2'                  # bar 3: two big strummed chords
    'A chug 3, D hit 1'                 # bar 4
)
```

| Style  | Sound |
|--------|-------|
| `chug` | Palm-muted eighth notes, tight and percussive. The first one is accented. |
| `hit`  | One full strummed power chord, held for its length. |
| `ring` | A big final chord left ringing, with the bass holding one long note under it. |

**Each bar must add up to exactly 4 beats.** If it doesn't, the script stops and tells you which bar is wrong:

```
Bar 6 adds up to 4.5 beats, not 4: 'E chug 3, G hit 1.5'
```

The **bass follows the guitar automatically**: wherever the guitar plays a chord, the bass plays that chord's root in eighth notes. You never write bass parts by hand.

### Chords the guitar knows

Power chords are looked up in the `$roots` table:

```powershell
$roots = @{ E = 40; G = 43; A = 45; C = 48; D = 50 }
```

The number is the lowest note of the chord (40 = the guitar's low E string). To use another chord, add it here. For example, `B = 47`, `F = 41`, `F# = 42`, or `Bb = 46`.

### Melody bars

The lead guitar uses note names and lengths in beats, with `r` for a rest:

```powershell
$hook = @(
    'E5 1, D5 0.5, E5 0.5, G5 2'
    'F#5 1, E5 0.5, D5 0.5, A4 2'
    'B4 1, D5 0.5, E5 0.5, G5 1, F#5 1'
    'E5 3, r 1'
    # ...
)
```

A melody needs **one line for each guitar bar** in the section it's played over. The chorus has 8 bars, so `$hook` has 8 lines. Notes from the E minor scale (E, F#, G, A, B, C, D) always fit. Notes between `E4` and `E6` sound best on the lead guitar.

### Drum patterns

Each section uses one drum pattern, chosen by name:

| Pattern  | Used in | Sound |
|----------|---------|-------|
| `count`  | Intro   | Quarter-note hi-hat clicks only |
| `verse`  | Verses  | Eighth-note hi-hats, kick on 1 and 3, snare on 2 and 4 |
| `chorus` | Chorus and solo | Ride cymbal, busier kick, heavier snare |
| `stabs`  | Outro   | Kick and crash together on every beat |
| `roll`   | Outro   | Sixteenth-note tom roll from high to low, getting louder |
| `end`    | Outro   | One last kick and double crash |

Crashes and fills are added for you by `Add-Section`.

### The arrangement

The bottom of the script, under **"Arrange the song"**, lists the sections in order:

```powershell
Add-Section -Guitar ($verseRiff + $verseRiff) -DrumStyle 'verse'                   # Verse 1
Add-Section -Guitar $chorusChords             -DrumStyle 'chorus' -Melody $hook    # Chorus 1
Add-Section -Guitar ($verseRiff + $verseRiff) -DrumStyle 'verse'                   # Verse 2
...
```

| Parameter    | Meaning |
|--------------|---------|
| `-Guitar`    | The guitar bars to play. `($verseRiff + $verseRiff)` plays the riff twice. |
| `-DrumStyle` | Which drum pattern to use. |
| `-Melody`    | Optional lead guitar part, one line per guitar bar. |
| `-Solo`      | Have the lead guitar improvise a solo instead. |

Each `Add-Section` starts where the last one ended, so you can reorder, repeat or delete lines freely.

---

## Making it your own

### Rewrite the riff

Replace the `$verseRiff` lines. Some ideas:

```powershell
# Gallop rhythm, metal-style
$verseRiff = @(
    'E chug 0.5, E chug 0.5, E hit 1, E chug 0.5, E chug 0.5, E hit 1'
    'E chug 2, G hit 1, A hit 1'
    'E chug 0.5, E chug 0.5, E hit 1, E chug 0.5, E chug 0.5, E hit 1'
    'C hit 2, D hit 2'
)

# Slow and heavy
$verseRiff = @(
    'E hit 4'
    'G hit 2, A hit 2'
    'E hit 4'
    'D hit 2, C hit 2'
)
```

### Change the sound

Edit the `Add-MidiTrack` lines under **"Band setup"**. Swap in other General MIDI instruments:

```powershell
$rhythm = Add-MidiTrack $song -Name 'Rhythm Guitar' -Channel 0 -Instrument 29 -Volume 95   # 29 = overdriven, less fuzzy
$lead   = Add-MidiTrack $song -Name 'Lead Guitar'   -Channel 1 -Instrument 81 -Volume 100  # 81 = sawtooth synth lead
$bass   = Add-MidiTrack $song -Name 'Bass'          -Channel 2 -Instrument 38 -Volume 110  # 38 = synth bass
```

Other good choices are 27 (clean electric guitar), 33 (finger bass), 19 (rock organ) and 62 (synth brass). The README has a longer [instrument list](README.md#instruments).

### Get a different solo

The solo is improvised from a fixed random seed. Change the number on this line to hear a different one (velocities change slightly too):

```powershell
$rng = [Random]::new(1977)
```

For a longer solo, give it more bars:

```powershell
Add-Section -Guitar ($chorusChords + $chorusChords) -DrumStyle 'chorus' -Solo   # 16-bar solo
```

### Add a bridge

A bridge is a new section that contrasts with the rest, often right before the final chorus. This one uses a B chord, so first add `B` to the chord table:

```powershell
$roots = @{ E = 40; G = 43; A = 45; C = 48; D = 50; B = 47 }
```

Then define the bridge next to the other music:

```powershell
$bridge = @(
    'C hit 4'
    'D hit 4'
    'B hit 2, B chug 2'
    'B hit 4'
)
$bridgeMelody = @(
    'G5 2, A5 2'
    'B5 4'
    'A5 2, G5 1, F#5 1'
    'F#5 4'
)
```

And place it in the arrangement, between the solo and the final chorus:

```powershell
Add-Section -Guitar $chorusChords -DrumStyle 'chorus' -Solo                    # Guitar solo
Add-Section -Guitar $bridge       -DrumStyle 'verse'  -Melody $bridgeMelody    # Bridge
Add-Section -Guitar $chorusChords -DrumStyle 'chorus' -Melody $hook            # Final chorus
```

Ending the bridge on B, the "five" chord of E minor, builds tension that the final chorus releases.

### Add a drum pattern

Drum patterns live in the `switch` inside `Add-DrumBar`. Each hit is `, @(drum, beat, velocity)`, where *beat* is the position within the bar (0 to 3.75). For example, this half-time feel puts the snare on beat 3 only, so the song feels half as fast. It suits a breakdown or a bridge:

```powershell
'half'   {
    foreach ($q in 0..3) { , @(42, $q, 80) }   # hi-hat on every beat
    , @(36, 0, 115); , @(36, 2.5, 100)          # kicks
    , @(38, 2, 120)                             # snare on beat 3
}
```

Add it next to the other patterns, then use `-DrumStyle 'half'` in a section. Drum numbers are listed in the README's [drum map](README.md#drum-map).

### Rearrange

Delete, copy or reorder the `Add-Section` lines. For example, add a double chorus at the end by repeating the last line, or leave out Verse 2 for a shorter radio edit.

---

## Troubleshooting

- **"The term 'New-MidiSong.ps1' is not recognized" / "cannot find path".** `rock-song.ps1` must be in the same folder as `New-MidiSong.ps1`.
- **"Bar N adds up to X beats, not 4".** A guitar bar's lengths don't add up to 4. Fix the bar the message shows.
- **"Unknown chord 'B' in bar N".** Add that chord to the `$roots` table (see [Chords the guitar knows](#chords-the-guitar-knows)). Chord names here are just the letter (`E`, `G`, `C`). Don't add `m` or `5`.
- **Lead melody sounds out of sync.** A melody must have the same number of lines as the section's guitar bars, and each line should add up to 4 beats.
- **"Unknown guitar style".** Only `chug`, `hit` and `ring` are recognized.
- **Scripts are blocked.** Run with `powershell -ExecutionPolicy Bypass -File .\rock-song.ps1`.
