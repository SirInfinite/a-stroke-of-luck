"""Original A Stroke of Luck chamber-arcade score, revision 2.

Pitches are concert pitch (C4 = MIDI 60); '-' is a rest. Durations are quarter
notes. Every letter is a four-bar phrase, not a random scale walk. The renderer
orchestrates these written melodies/chords; it never invents melody at runtime.
"""

SCORES = {
    "menu": {
        "title": "House Rules", "bpm": 112, "beats": 4, "form": "ABACABCA",
        "lead": "vibes", "comp": "piano", "bass": "harp", "groove": "swing",
        "identity": "A winking clubhouse shuffle: brushed wood, piano sixths, vibraphone call-and-response.",
        "melody": {
            "A": "-:.5 E5:.5 G5:1 A5:.5 G5:.5 E5:1 | D5:1 -:.5 E5:.5 G5:1 C5:1 | A4:.5 C5:.5 E5:1 D5:.5 C5:.5 A4:1 | B4:1 D5:1 G4:1 -:1",
            "B": "G5:1 E5:.5 D5:.5 C5:1 -:1 | E5:.5 G5:.5 B5:1 A5:1 G5:1 | F5:1 A5:.5 G5:.5 E5:1 D5:1 | B4:.5 D5:.5 F5:.5 A5:.5 G5:1 -:1",
            "C": "A5:1 F5:1 E5:.5 F5:.5 C5:1 | Ab5:1 F5:1 Eb5:1 -:1 | E5:1 G5:.5 E5:.5 D5:1 C5:1 | D5:.5 F5:.5 A5:1 B4:1 -:1",
        },
        "harmony": {"A": ["C3 E3 G3 A3", "C3 E3 G3 B3", "A2 C3 E3 G3", "G2 B2 D3 F3"], "B": ["C3 E3 G3 B3", "E3 G3 B3 D4", "F3 A3 C4 E4", "G2 B2 D3 F3"], "C": ["F3 A3 C4 E4", "F3 Ab3 C4 Eb4", "C3 E3 G3 A3", "G2 B2 D3 F3"]},
    },
    "tutorial": {
        "title": "First Putt", "bpm": 88, "beats": 4, "form": "ABAC",
        "lead": "marimba", "comp": "harp", "bass": "piano", "groove": "practice",
        "identity": "Unhurried four-bar questions, soft marimba and open harp voicings; room for instructions.",
        "melody": {
            "A": "C5:1 E5:1 G5:1 -:1 | E5:2 D5:1 -:1 | C5:1 A4:1 C5:1 -:1 | D5:2 -:2",
            "B": "E5:1 G5:1 A5:1 -:1 | G5:2 E5:1 -:1 | F5:1 E5:1 D5:1 -:1 | C5:2 -:2",
            "C": "A4:1 C5:1 E5:2 | F5:1 E5:1 C5:1 -:1 | D5:1 E5:1 G5:1 D5:1 | C5:2 -:2",
        },
        "harmony": {"A": ["C3 E3 G3", "E3 G3 B3", "A2 C3 E3", "G2 B2 D3"], "B": ["C3 E3 G3", "A2 C3 E3", "F3 A3 C4", "C3 E3 G3"], "C": ["A2 C3 E3", "F3 A3 C4", "G2 B2 D3", "C3 E3 G3"]},
    },
    "meadow": {
        "title": "Clover Club", "bpm": 106, "beats": 4, "form": "ABACBA",
        "lead": "recorder", "comp": "harp", "bass": "piano", "groove": "meadow",
        "identity": "Skipping wooden flute over picked harp and light cajon, with a sunny answering phrase.",
        "melody": {
            "A": "G5:.5 A5:.5 B5:1 D6:.5 B5:.5 A5:1 | G5:1 E5:.5 G5:.5 A5:1 -:1 | B5:.5 A5:.5 G5:1 E5:1 D5:1 | F#5:.5 A5:.5 G5:1 D5:1 -:1",
            "B": "E5:1 G5:.5 A5:.5 B5:1 -:1 | D6:1 B5:1 A5:.5 G5:.5 E5:1 | C6:1 B5:.5 A5:.5 G5:1 E5:1 | F#5:1 A5:1 D5:1 -:1",
            "C": "C6:1 A5:1 G5:.5 A5:.5 E5:1 | B5:1 G5:1 E5:1 -:1 | A5:.5 B5:.5 C6:1 A5:1 G5:1 | F#5:1 D5:1 A5:1 -:1",
        },
        "harmony": {"A": ["G2 B2 D3", "C3 E3 G3", "E3 G3 B3", "D3 F#3 A3"], "B": ["E3 G3 B3", "G2 B2 D3", "C3 E3 G3", "D3 F#3 A3"], "C": ["C3 E3 G3", "E3 G3 B3", "A2 C3 E3", "D3 F#3 A3"]},
    },
    "desert": {
        "title": "Dry Bank", "bpm": 96, "beats": 3.5, "form": "ABACBA",
        "lead": "strum", "comp": "marimba", "bass": "harp", "groove": "caravan",
        "identity": "A dry 3+2+2 pulse, plucked strumstick and low wooden percussion with spacious modal phrases.",
        "melody": {
            "A": "D4:.5 A4:.5 D5:.5 F5:1 E5:1 | D5:1 C5:.5 A4:1 -:1 | Bb4:.5 D5:.5 F5:.5 E5:1 D5:1 | C#5:.5 E5:.5 A4:.5 G4:1 -:1",
            "B": "A4:.5 D5:.5 E5:.5 F5:1 A5:1 | G5:1 F5:.5 E5:1 -:1 | D5:.5 F5:.5 A5:.5 G5:1 F5:1 | E5:1 C#5:.5 A4:1 -:1",
            "C": "Bb4:1 F5:.5 D5:1 -:1 | C5:1 G5:.5 E5:1 -:1 | D5:.5 A4:.5 F4:.5 D4:1 F4:1 | E4:.5 A4:.5 C#5:.5 E5:1 -:1",
        },
        "harmony": {"A": ["D2 A2 D3 F3", "D2 A2 C3 E3", "Bb2 F3 Bb3", "A2 E3 G3 C#4"], "B": ["D2 F3 A3", "C3 E3 G3", "Bb2 D3 F3", "A2 C#3 E3"], "C": ["Bb2 D3 F3", "C3 E3 G3", "D2 F3 A3", "A2 C#3 E3"]},
    },
    "autumn": {
        "title": "Last Light", "bpm": 84, "beats": 3, "form": "ABACBA",
        "lead": "piano", "comp": "vibes", "bass": "harp", "groove": "waltz",
        "identity": "A warm piano waltz with falling phrases, suspended harmony and soft vibraphone answers.",
        "melody": {
            "A": "A4:1 C5:.5 F5:.5 E5:1 | D5:1 C5:1 A4:1 | Bb4:1 D5:.5 F5:.5 E5:1 | C5:2 -:1",
            "B": "F5:1 A5:1 G5:1 | E5:1 F5:.5 E5:.5 C5:1 | D5:1 F5:1 E5:1 | C5:1 Bb4:1 -:1",
            "C": "D5:1 A4:.5 D5:.5 F5:1 | E5:1 C5:1 G4:1 | Bb4:1 D5:1 F5:1 | E5:1 G5:1 C5:1",
        },
        "harmony": {"A": ["F2 A3 C4", "D3 F3 A3", "Bb2 D3 F3", "C3 E3 G3"], "B": ["F2 A3 C4", "A2 C3 E3", "Bb2 D3 F3", "C3 E3 G3"], "C": ["D3 F3 A3", "A2 C3 E3", "Bb2 D3 F3", "C3 E3 G3"]},
    },
    "snow": {
        "title": "Glass Green", "bpm": 76, "beats": 5, "form": "ABCA",
        "lead": "vibes", "comp": "harp", "bass": "piano", "groove": "air",
        "identity": "Spare five-beat bell phrases, open fifths and long acoustic tails; no driving drum loop.",
        "melody": {
            "A": "E5:2 B5:1 F#5:1 -:1 | G5:2 E5:1 -:2 | D5:1 F#5:1 A5:2 -:1 | B5:2 F#5:1 -:2",
            "B": "C6:2 G5:1 E5:1 -:1 | B5:2 A5:1 F#5:1 -:1 | G5:1 B5:1 E6:2 -:1 | D6:1 A5:1 F#5:1 -:2",
            "C": "A5:2 E5:1 C5:1 -:1 | G5:2 D5:1 B4:1 -:1 | F#5:1 A5:1 B5:2 -:1 | F#5:2 E5:1 -:2",
        },
        "harmony": {"A": ["E2 B2 F#3", "C3 G3 B3", "D3 A3 E4", "B2 F#3 A3"], "B": ["C3 G3 E4", "D3 A3 F#4", "E3 B3 G4", "D3 A3 F#4"], "C": ["A2 E3 C4", "G2 D3 B3", "B2 F#3 A3", "E2 B2 F#3"]},
    },
    "swamp": {
        "title": "Crooked Reeds", "bpm": 98, "beats": 4, "form": "ABCABA",
        "lead": "marimba", "comp": "piano", "bass": "strum", "groove": "swamp",
        "identity": "An offbeat wooden groove: low marimba, clipped piano ninths and lopsided little replies.",
        "melody": {
            "A": "-:.5 D4:.5 F4:.5 A4:.5 C5:1 A4:1 | F4:.5 D4:1 -:.5 E4:1 G4:1 | A4:1 C5:.5 D5:.5 F5:1 D5:1 | E5:.5 C5:.5 A4:1 G4:1 -:1",
            "B": "D5:1 -:.5 C5:.5 A4:1 F4:1 | G4:.5 A4:.5 B4:1 D5:1 -:1 | E5:1 C5:.5 A4:.5 G4:1 E4:1 | F4:.5 E4:.5 D4:1 -:2",
            "C": "G4:.5 Bb4:.5 D5:1 F5:1 -:1 | E5:1 C5:.5 A4:.5 G4:1 E4:1 | F4:1 A4:1 C5:.5 A4:.5 F4:1 | E4:.5 G4:.5 C#5:1 A4:1 -:1",
        },
        "harmony": {"A": ["D2 F3 A3 C4", "E2 G3 B3 D4", "D2 F3 A3 C4", "A2 C#3 E3 G3"], "B": ["D2 F3 A3", "G2 B2 D3 F3", "A2 C3 E3 G3", "D2 F3 A3"], "C": ["G2 Bb2 D3 F3", "A2 C3 E3 G3", "D2 F3 A3 C4", "A2 C#3 E3 G3"]},
    },
    "volcanic": {
        "title": "Double or Cinders", "bpm": 132, "beats": 4, "form": "ABACBCAB",
        "lead": "marimba", "comp": "piano", "bass": "piano", "groove": "embers",
        "identity": "Driving low piano and timpani-like drum weight, syncopated mallets, a tense contrasting middle.",
        "melody": {
            "A": "E4:.5 B4:.5 E5:.5 G5:.5 F#5:1 E5:1 | D5:.5 B4:.5 A4:1 B4:.5 D5:.5 E5:1 | C5:.5 G5:.5 F#5:1 E5:.5 D5:.5 C5:1 | B4:.5 F#5:.5 D#5:1 B4:1 -:1",
            "B": "G5:1 B5:.5 A5:.5 G5:1 E5:1 | F#5:.5 A5:.5 D6:1 A5:1 F#5:1 | E5:.5 G5:.5 C6:1 B5:.5 G5:.5 E5:1 | D#5:.5 F#5:.5 B5:1 A5:1 -:1",
            "C": "C5:1 E5:1 G5:.5 E5:.5 C5:1 | A4:1 C5:1 E5:1 -:1 | F#5:.5 G5:.5 A5:1 F#5:1 D5:1 | D#5:1 B4:.5 D#5:.5 F#5:1 -:1",
        },
        "harmony": {"A": ["E2 B2 E3 G3", "D2 A2 D3 F#3", "C2 G2 C3 E3", "B1 F#2 B2 D#3"], "B": ["E2 G3 B3", "D2 F#3 A3", "C2 E3 G3", "B1 D#3 F#3"], "C": ["C2 E3 G3", "A1 E3 A3 C4", "D2 F#3 A3", "B1 D#3 F#3"]},
    },
}
