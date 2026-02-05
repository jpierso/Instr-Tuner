# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Run

This is an Xcode project (no SPM/CocoaPods). Build and run:
1. Open `Tuner.xcodeproj` in Xcode
2. Configure signing team in Signing & Capabilities
3. Build and run on a physical iOS device (microphone required for pitch detection)

There are no unit tests in this project.

## Architecture

**MVVM with Combine** - SwiftUI app using `@ObservableObject` ViewModels with `@Published` properties for reactive state management.

### Data Flow
```
Microphone → AudioEngine (AVAudioEngine tap) → PitchDetector (YIN algorithm)
    → TunerViewModel (state management) → SwiftUI Views
```

### Key Layers

**Audio Layer** (`Audio/`)
- `AudioEngine`: Captures microphone input via AVAudioEngine, processes 4096-sample buffers at 44.1kHz
- `PitchDetector`: Implements YIN pitch detection algorithm, returns frequency + confidence (0-1)
- `AudioSessionManager`: Handles AVAudioSession configuration and permissions

**ViewModels** (`ViewModels/`)
- `TunerViewModel`: Central orchestrator - binds to AudioEngine, calculates tuning state (cents deviation, in-tune status), manages settings
- `SettingsViewModel`: Handles user preferences persistence

**Data Persistence** - SwiftData with `@Model` classes:
- `TunerSettings`: Reference pitch, note offsets (JSON-encoded), sensitivity, selected instrument
- `CustomInstrument`: User-created tunings

### Important Constants (`Utilities/Constants.swift`)
- `inTuneThreshold`: ±2 cents for "in tune" status
- `closeThreshold`: ±5 cents for "close" status
- Sensitivity maps 0.0-1.0 to input thresholds via quadratic curve

### Strobe Visualization
- Rotation direction: clockwise = sharp, counter-clockwise = flat
- Rotation speed proportional to cents deviation
- Green highlight when in tune
