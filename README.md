# Strobe Chromatic Tuner

A professional-grade strobe chromatic tuner for iOS, built with Swift and SwiftUI.

## Features

### Core Tuning
- **Strobe Visualization**: Classic strobe tuner display with smooth animations
- **Real-time Pitch Detection**: YIN algorithm for accurate monophonic pitch detection
- **Chromatic Mode**: Detects any note across the full musical range
- **Low Latency**: Optimized audio pipeline for responsive tuning feedback

### Reference Pitch
- Default A4 = 440 Hz (ISO standard)
- Adjustable range: 415 Hz - 466 Hz
- Presets for common standards:
  - 415 Hz (Baroque)
  - 432 Hz (Verdi/Scientific)
  - 440 Hz (Standard)
  - 442 Hz (European Orchestra)
  - 444 Hz (Bright Orchestra)

### Instrument Support
Built-in presets for:
- **Acoustic Guitar** (E2-A2-D3-G3-B3-E4)
- **Electric Guitar** (E2-A2-D3-G3-B3-E4)
- **Electric Bass** (E1-A1-D2-G2)
- **Banjo** 5-string (G4-D3-G3-B3-D4)
- **Mandolin** (G3-D4-A4-E5)
- **Violin** (G3-D4-A4-E5)
- **Pedal Steel** E9 standard (B3-D4-E4-F#4-G#4-B4-E5-G#5-D#5-F#5)

### Customization
- **Per-Note Cent Offsets**: Adjust each of the 12 notes individually (-50 to +50 cents)
- **Custom Tunings**: Create and save your own tuning configurations
- **Dark Mode**: Optimized dark interface for stage use

## Requirements

- iOS 17.0+
- iPhone or iPad
- Xcode 15.0+

## Project Structure

```
Tuner/
├── App/
│   ├── TunerApp.swift          # App entry point
│   └── ContentView.swift        # Main navigation
├── Audio/
│   ├── AudioEngine.swift        # AVAudioEngine wrapper
│   ├── PitchDetector.swift      # YIN pitch detection
│   └── AudioSessionManager.swift # Audio session configuration
├── Models/
│   ├── Note.swift               # Note and Pitch types
│   ├── Instrument.swift         # Instrument definitions
│   ├── TunerSettings.swift      # Settings persistence
│   └── TuningPresets.swift      # Built-in tunings
├── ViewModels/
│   ├── TunerViewModel.swift     # Main tuner logic
│   └── SettingsViewModel.swift  # Settings management
├── Views/
│   ├── Tuner/
│   │   ├── TunerView.swift      # Main tuner screen
│   │   ├── StrobeView.swift     # Strobe visualization
│   │   ├── NoteDisplayView.swift # Note/cents display
│   │   └── InputLevelView.swift  # Audio level meter
│   ├── Settings/
│   │   ├── SettingsView.swift   # Settings screen
│   │   ├── ReferencePitchView.swift
│   │   └── CentOffsetsView.swift
│   └── Instruments/
│       ├── InstrumentPickerView.swift
│       └── CustomTuningView.swift
└── Utilities/
    ├── TuningMath.swift         # Frequency calculations
    └── Constants.swift          # App constants
```

## Technical Details

### Pitch Detection
The app uses the YIN algorithm for pitch detection, which provides:
- High accuracy for monophonic signals
- Good performance at low frequencies (bass guitar range)
- Confidence values for noise rejection

### Audio Configuration
- Sample Rate: 44.1 kHz
- Buffer Size: 4096 samples
- Latency: ~5ms target

### Strobe Visualization
- 60 FPS target animation
- Rotation direction indicates sharp/flat
- Speed proportional to cents deviation
- Green highlight when in tune (±2 cents)

## Building

1. Open `Tuner.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Build and run on a physical device (microphone required)

## Permissions

The app requires microphone access to detect instrument pitch. The permission request explains this to users on first launch.

## License

MIT License - See LICENSE file for details.
