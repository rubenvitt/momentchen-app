//
//  ParticleEffectView.swift
//  Momentchen
//
//  Created by Developer Agent on 23.10.2025.
//

import SwiftUI

/// Confetti particle effect for celebrating successful actions
/// Uses native SwiftUI animations for a joyful, delightful experience
struct ParticleEffectView: View {
    // MARK: - Properties

    let colors: [Color]
    let particleCount: Int
    @State private var particles: [Particle] = []
    @State private var isAnimating = false

    // MARK: - Initialization

    init(colors: [Color] = [.blue, .green, .orange, .yellow, .pink, .purple], particleCount: Int = 8) {
        self.colors = colors
        self.particleCount = particleCount
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                ParticleShape()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .offset(x: particle.x, y: particle.y)
                    .opacity(particle.opacity)
                    .rotationEffect(.degrees(particle.rotation))
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    // MARK: - Animation

    private func startAnimation() {
        // Generate initial particles at center
        particles = (0..<particleCount).map { index in
            Particle(
                id: index,
                color: colors.randomElement() ?? .blue,
                x: 0,
                y: 0,
                size: CGFloat.random(in: 6...12),
                opacity: 1.0,
                rotation: Double.random(in: 0...360)
            )
        }

        // Animate particles outward
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            isAnimating = true
            particles = particles.map { particle in
                var updated = particle
                // Random direction and distance
                let angle = Double.random(in: 0...(2 * .pi))
                let distance = CGFloat.random(in: 50...120)
                updated.x = cos(angle) * distance
                updated.y = sin(angle) * distance - 30 // Slight upward bias
                updated.rotation = Double.random(in: 0...720)
                return updated
            }
        }

        // Fade out particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.4)) {
                particles = particles.map { particle in
                    var updated = particle
                    updated.opacity = 0
                    updated.y += 20 // Fall down while fading
                    return updated
                }
            }
        }
    }
}

// MARK: - Particle Model

private struct Particle: Identifiable {
    let id: Int
    let color: Color
    var x: CGFloat
    var y: CGFloat
    let size: CGFloat
    var opacity: Double
    var rotation: Double
}

// MARK: - Particle Shape

private struct ParticleShape: Shape {
    func path(in rect: CGRect) -> Path {
        // Create a simple rounded square for particles
        Path(roundedRect: rect, cornerRadius: rect.width * 0.3)
    }
}

// MARK: - Modifier for Easy Use

extension View {
    /// Add particle effect overlay that triggers on boolean change
    /// - Parameters:
    ///   - isTriggered: Binding that triggers the effect when set to true
    ///   - colors: Array of colors for particles (defaults to app theme colors)
    /// - Returns: Modified view with particle effect
    func particleEffect(isTriggered: Binding<Bool>, colors: [Color]? = nil) -> some View {
        self.overlay {
            if isTriggered.wrappedValue {
                ParticleEffectView(colors: colors ?? [.blue, .green, .orange, .yellow, .pink, .purple])
                    .onAppear {
                        // Reset trigger after animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            isTriggered.wrappedValue = false
                        }
                    }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        Text("Particle Effect Demo")
            .font(.title)

        ParticleEffectView()
            .frame(width: 200, height: 200)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))

        ParticleEffectView(colors: [.blue, .purple], particleCount: 12)
            .frame(width: 200, height: 200)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    .padding()
}
