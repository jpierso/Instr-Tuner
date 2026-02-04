import SwiftUI

/// Displays the detected note name and octave
struct NoteDisplayView: View {
    let pitch: Pitch
    let isValid: Bool
    let isInTune: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            // Note name
            Text(pitch.note.displayName)
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundColor(noteColor)
            
            // Octave number
            Text("\(pitch.octave)")
                .font(.system(size: 28, weight: .medium, design: .rounded))
                .foregroundColor(noteColor.opacity(0.7))
        }
        .animation(.easeInOut(duration: 0.15), value: pitch.note)
        .animation(.easeInOut(duration: 0.15), value: isInTune)
    }
    
    private var noteColor: Color {
        if !isValid {
            return .gray
        }
        if isInTune {
            return .green
        }
        return .white
    }
}

/// Displays the cents deviation
struct CentsDisplayView: View {
    let cents: Double
    let isValid: Bool
    let isInTune: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            // Direction indicator
            if isValid && !isInTune {
                Image(systemName: cents > 0 ? "chevron.up" : "chevron.down")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(directionColor)
            }
            
            // Cents value
            Text(formattedCents)
                .font(.system(size: 32, weight: .semibold, design: .monospaced))
                .foregroundColor(textColor)
            
            Text("cents")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(textColor.opacity(0.6))
        }
    }
    
    private var formattedCents: String {
        guard isValid else { return "--" }
        let rounded = Int(round(cents))
        if rounded > 0 {
            return "+\(rounded)"
        }
        return "\(rounded)"
    }
    
    private var textColor: Color {
        if !isValid {
            return .gray
        }
        if isInTune {
            return .green
        }
        return .white
    }
    
    private var directionColor: Color {
        if cents > 0 {
            return .orange // Sharp
        }
        return .cyan // Flat
    }
}

/// Displays the detected frequency
struct FrequencyDisplayView: View {
    let frequency: Double
    let isValid: Bool
    
    var body: some View {
        Text(formattedFrequency)
            .font(.system(size: 18, weight: .medium, design: .monospaced))
            .foregroundColor(isValid ? .white.opacity(0.7) : .gray.opacity(0.5))
    }
    
    private var formattedFrequency: String {
        guard isValid && frequency > 0 else { return "--- Hz" }
        return String(format: "%.1f Hz", frequency)
    }
}

/// Visual tuning indicator with flat/sharp markers
struct TuningIndicatorView: View {
    let cents: Double
    let isValid: Bool
    let isInTune: Bool
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let centerX = width / 2
            
            ZStack {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 8)
                
                // Center marker
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 2, height: 16)
                    .position(x: centerX, y: geometry.size.height / 2)
                
                // Flat/Sharp labels
                HStack {
                    Text("♭")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.cyan)
                    
                    Spacer()
                    
                    Text("♯")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 8)
                
                // Indicator needle
                if isValid {
                    let clampedCents = max(-50, min(50, cents))
                    let offset = (clampedCents / 50.0) * (width / 2 - 20.0)
                    
                    Circle()
                        .fill(indicatorColor)
                        .frame(width: 16, height: 16)
                        .shadow(color: indicatorColor.opacity(0.5), radius: 4)
                        .position(x: centerX + offset, y: geometry.size.height / 2)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: cents)
                }
            }
        }
        .frame(height: 32)
    }
    
    private var indicatorColor: Color {
        if !isValid {
            return .gray
        }
        if isInTune {
            return .green
        }
        if cents > 0 {
            return .orange
        }
        return .cyan
    }
}

#Preview {
    VStack(spacing: 20) {
        NoteDisplayView(
            pitch: Pitch(note: .A, octave: 4),
            isValid: true,
            isInTune: true
        )
        
        CentsDisplayView(cents: -5, isValid: true, isInTune: false)
        
        FrequencyDisplayView(frequency: 440.0, isValid: true)
        
        TuningIndicatorView(cents: 15, isValid: true, isInTune: false)
            .padding(.horizontal, 40)
    }
    .padding()
    .background(Color.black)
}
