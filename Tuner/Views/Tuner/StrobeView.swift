import SwiftUI

/// The main strobe tuner visualization
/// Rotation indicates pitch deviation: stationary = in tune, 
/// clockwise = sharp, counter-clockwise = flat
struct StrobeView: View {
    let cents: Double
    let isValid: Bool
    let isInTune: Bool
    
    @State private var rotation: Double = 0
    
    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: size * 0.15)
                
                // Strobe bands
                StrobeBandsView(rotation: rotation, isValid: isValid, isInTune: isInTune)
                    .mask(
                        Circle()
                            .strokeBorder(Color.white, lineWidth: size * 0.15)
                    )
                
                // Inner circle with note display area
                Circle()
                    .fill(Color.black)
                    .frame(width: size * 0.55, height: size * 0.55)
                
                // In-tune indicator ring
                Circle()
                    .strokeBorder(
                        isInTune ? Color.green : Color.clear,
                        lineWidth: 4
                    )
                    .frame(width: size * 0.58, height: size * 0.58)
                    .animation(.easeInOut(duration: 0.2), value: isInTune)
            }
            .frame(width: size, height: size)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .onReceive(timer) { _ in
            updateRotation()
        }
    }
    
    private func updateRotation() {
        guard isValid else {
            // Slowly decay rotation when no valid input
            rotation *= 0.95
            return
        }
        
        // Rotation speed proportional to cents deviation
        // Positive cents (sharp) = clockwise rotation
        // Negative cents (flat) = counter-clockwise rotation
        let rotationSpeed = cents * Constants.strobeRotationFactor / Constants.targetFrameRate
        rotation += rotationSpeed
        
        // Keep rotation in reasonable bounds
        if rotation > 360 {
            rotation -= 360
        } else if rotation < -360 {
            rotation += 360
        }
    }
}

/// The rotating strobe bands
struct StrobeBandsView: View {
    let rotation: Double
    let isValid: Bool
    let isInTune: Bool
    
    private let bandCount = 12
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            
            ZStack {
                ForEach(0..<bandCount, id: \.self) { index in
                    StrobeBand(
                        index: index,
                        totalBands: bandCount,
                        size: size,
                        isValid: isValid,
                        isInTune: isInTune
                    )
                }
            }
            .rotationEffect(.degrees(rotation))
            .frame(width: size, height: size)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }
}

/// Individual strobe band segment
struct StrobeBand: View {
    let index: Int
    let totalBands: Int
    let size: CGFloat
    let isValid: Bool
    let isInTune: Bool
    
    var body: some View {
        let angle = Double(index) * (360.0 / Double(totalBands))
        let isEven = index % 2 == 0
        
        Rectangle()
            .fill(bandColor(isEven: isEven))
            .frame(width: size * 0.5, height: size * 0.2)
            .offset(x: size * 0.25)
            .rotationEffect(.degrees(angle))
    }
    
    private func bandColor(isEven: Bool) -> Color {
        if !isValid {
            return isEven ? Color.gray.opacity(0.5) : Color.gray.opacity(0.2)
        }
        
        if isInTune {
            return isEven ? Color.green : Color.green.opacity(0.3)
        }
        
        return isEven ? Color.blue : Color.blue.opacity(0.3)
    }
}

/// Alternative concentric rings strobe style
struct ConcentricStrobeView: View {
    let cents: Double
    let isValid: Bool
    let isInTune: Bool
    
    @State private var phase: Double = 0
    
    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
    private let ringCount = 8
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            
            ZStack {
                ForEach(0..<ringCount, id: \.self) { index in
                    ConcentricRing(
                        index: index,
                        totalRings: ringCount,
                        phase: phase,
                        size: size,
                        isValid: isValid,
                        isInTune: isInTune
                    )
                }
                
                // Center circle
                Circle()
                    .fill(Color.black)
                    .frame(width: size * 0.3, height: size * 0.3)
            }
            .frame(width: size, height: size)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .onReceive(timer) { _ in
            updatePhase()
        }
    }
    
    private func updatePhase() {
        guard isValid else {
            phase *= 0.95
            return
        }
        
        // Phase shift creates the strobe illusion
        let phaseSpeed = cents * 0.02
        phase += phaseSpeed
        
        if phase > 1 {
            phase -= 1
        } else if phase < 0 {
            phase += 1
        }
    }
}

/// Individual concentric ring with pattern
struct ConcentricRing: View {
    let index: Int
    let totalRings: Int
    let phase: Double
    let size: CGFloat
    let isValid: Bool
    let isInTune: Bool
    
    var body: some View {
        let ringSize = size * (0.9 - CGFloat(index) * 0.08)
        let segments = 24
        
        Circle()
            .strokeBorder(
                AngularGradient(
                    gradient: Gradient(colors: patternColors(segments: segments)),
                    center: .center,
                    startAngle: .degrees(phase * 360),
                    endAngle: .degrees(phase * 360 + 360)
                ),
                lineWidth: size * 0.035
            )
            .frame(width: ringSize, height: ringSize)
    }
    
    private func patternColors(segments: Int) -> [Color] {
        var colors: [Color] = []
        let baseColor = isInTune ? Color.green : (isValid ? Color.blue : Color.gray)
        
        for i in 0..<segments {
            let isOn = i % 2 == 0
            colors.append(isOn ? baseColor : baseColor.opacity(0.2))
        }
        
        return colors
    }
}

#Preview {
    VStack(spacing: 40) {
        StrobeView(cents: 0, isValid: true, isInTune: true)
            .frame(width: 250, height: 250)
        
        StrobeView(cents: 15, isValid: true, isInTune: false)
            .frame(width: 250, height: 250)
    }
    .padding()
    .background(Color.black)
}
