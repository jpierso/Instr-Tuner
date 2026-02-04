import SwiftUI

/// Displays the audio input level meter
struct InputLevelView: View {
    let level: Float
    let isRunning: Bool
    
    // Number of segments in the meter
    private let segmentCount = 20
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(0..<segmentCount, id: \.self) { index in
                    LevelSegment(
                        index: index,
                        totalSegments: segmentCount,
                        level: level,
                        isRunning: isRunning
                    )
                }
            }
        }
        .frame(height: 12)
    }
}

/// Individual segment of the level meter
struct LevelSegment: View {
    let index: Int
    let totalSegments: Int
    let level: Float
    let isRunning: Bool
    
    var body: some View {
        let threshold = Float(index) / Float(totalSegments)
        let isActive = isRunning && level > threshold
        
        RoundedRectangle(cornerRadius: 1)
            .fill(segmentColor(isActive: isActive))
            .animation(.easeOut(duration: 0.05), value: isActive)
    }
    
    private func segmentColor(isActive: Bool) -> Color {
        let position = Float(index) / Float(totalSegments)
        
        if !isActive {
            return Color.gray.opacity(0.2)
        }
        
        // Green for low levels, yellow for medium, red for high
        if position < 0.6 {
            return .green
        } else if position < 0.8 {
            return .yellow
        } else {
            return .red
        }
    }
}

/// Vertical input level meter (alternative style)
struct VerticalInputLevelView: View {
    let level: Float
    let isRunning: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                
                // Level fill
                if isRunning {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.green, .yellow, .red],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(height: geometry.size.height * CGFloat(min(level * 3, 1.0)))
                        .animation(.easeOut(duration: 0.1), value: level)
                }
            }
        }
        .frame(width: 8)
    }
}

/// Circular input level indicator
struct CircularInputLevelView: View {
    let level: Float
    let isRunning: Bool
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 4)
            
            // Level ring
            if isRunning {
                Circle()
                    .trim(from: 0, to: CGFloat(min(level * 3, 1.0)))
                    .stroke(
                        levelColor,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.1), value: level)
            }
        }
    }
    
    private var levelColor: Color {
        let normalizedLevel = min(level * 3, 1.0)
        if normalizedLevel < 0.6 {
            return .green
        } else if normalizedLevel < 0.8 {
            return .yellow
        } else {
            return .red
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        InputLevelView(level: 0.3, isRunning: true)
            .padding(.horizontal)
        
        HStack(spacing: 20) {
            VerticalInputLevelView(level: 0.2, isRunning: true)
                .frame(height: 100)
            
            VerticalInputLevelView(level: 0.5, isRunning: true)
                .frame(height: 100)
            
            VerticalInputLevelView(level: 0.9, isRunning: true)
                .frame(height: 100)
        }
        
        HStack(spacing: 20) {
            CircularInputLevelView(level: 0.2, isRunning: true)
                .frame(width: 50, height: 50)
            
            CircularInputLevelView(level: 0.5, isRunning: true)
                .frame(width: 50, height: 50)
            
            CircularInputLevelView(level: 0.9, isRunning: true)
                .frame(width: 50, height: 50)
        }
    }
    .padding()
    .background(Color.black)
}
