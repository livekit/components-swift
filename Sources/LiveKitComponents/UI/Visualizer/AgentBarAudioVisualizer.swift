/*
 * Copyright 2025 LiveKit
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * Copyright 2025 LiveKit
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import LiveKit
import SwiftUI

/// A SwiftUI view that visualizes audio levels and agent states as a series of animated vertical bars.
/// This visualizer is specifically designed to provide visual feedback for different agent states
/// (connecting, initializing, listening, thinking, speaking) while also responding to real-time
/// audio data when available.
///
/// `AgentBarAudioVisualizer` displays bars whose heights and opacities dynamically
/// reflect the magnitude of audio frequencies in real time, creating an
/// interactive, visual representation of the audio track's spectrum. This
/// visualizer can be customized in terms of bar count, color, corner radius,
/// spacing, and whether the bars are centered based on frequency magnitude.
///
/// Usage:
/// ```
/// let audioTrack: AudioTrack = ...
/// let agentState: AgentState = ...
/// AgentBarAudioVisualizer(audioTrack: audioTrack, agentState: agentState)
/// ```
///
/// - Parameters:
///   - audioTrack: The `AudioTrack` providing audio data to be visualized.
///   - agentState: Triggers transitions between visualizer animation states.
///   - barColor: The color used to fill each bar, defaulting to white.
///   - barCount: The number of bars displayed, defaulting to 7.
///   - barCornerRadius: The corner radius applied to each bar, giving a
///     rounded appearance. Defaults to 100.
///   - barSpacingFactor: Determines the spacing between bars as a factor
///     of view width. Defaults to 0.015.
///   - isCentered: A Boolean indicating whether higher-decibel bars
///     should be centered. Defaults to `true`.
///
/// Example:
/// ```
/// AgentBarAudioVisualizer(audioTrack: audioTrack, barColor: .blue, barCount: 10)
/// ```
public struct AgentBarAudioVisualizer: View {
    public let barCount: Int
    public let barColor: Color
    public let barCornerRadius: CGFloat
    public let barSpacingFactor: CGFloat
    public let barMinOpacity: Double
    public let isCentered: Bool

    private let agentState: AgentState

    @StateObject private var audioProcessor: AudioProcessor

    @State private var animationProperties: PhaseAnimationProperties
    @State private var animationPhase: Int = 0
    @State private var animationTask: Task<Void, Never>?

    public init(audioTrack: AudioTrack?,
                agentState: AgentState,
                barColor: Color = .primary,
                barCount: Int = 5,
                barCornerRadius: CGFloat = 100,
                barSpacingFactor: CGFloat = 0.015,
                barMinOpacity: CGFloat = 0.16,
                isCentered: Bool = true)
    {
        self.agentState = agentState

        self.barColor = barColor
        self.barCount = barCount
        self.barCornerRadius = barCornerRadius
        self.barSpacingFactor = barSpacingFactor
        self.barMinOpacity = Double(barMinOpacity)
        self.isCentered = isCentered

        _audioProcessor = StateObject(wrappedValue: AudioProcessor(track: audioTrack,
                                                                   bandCount: barCount,
                                                                   isCentered: isCentered))

        animationProperties = PhaseAnimationProperties(barCount: barCount)
    }

    public var body: some View {
        GeometryReader { geometry in
            let highlightingSequence = animationProperties.highlightingSequence(agentState: agentState)
            let highlighted = highlightingSequence[animationPhase % highlightingSequence.count]
            let duration = animationProperties.duration(agentState: agentState)

            bars(geometry: geometry, highlighted: highlighted)
                .onAppear {
                    animationTask?.cancel()
                    animationTask = Task {
                        while !Task.isCancelled {
                            try? await Task.sleep(nanoseconds: UInt64(duration * Double(NSEC_PER_SEC)))
                            withAnimation(.easeInOut) { animationPhase += 1 }
                        }
                    }
                }
                .onDisappear {
                    animationTask?.cancel()
                }
                .animation(.easeOut, value: agentState)
                .onChange(of: agentState) { _ in
                    animationPhase = 0
                }
        }
    }

    @ViewBuilder
    private func bars(geometry: GeometryProxy, highlighted: PhaseAnimationProperties.HighlightedBars) -> some View {
        let barMinHeight = (geometry.size.width - geometry.size.width * barSpacingFactor * CGFloat(barCount + 2)) / CGFloat(barCount)
        HStack(alignment: .center, spacing: geometry.size.width * barSpacingFactor) {
            ForEach(0 ..< audioProcessor.bands.count, id: \.self) { index in
                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: barMinHeight)
                        .fill(barColor)
                        .opacity(highlighted.contains(index) ? 1 : barMinOpacity)
                        .frame(height: (geometry.size.height - barMinHeight) * CGFloat(audioProcessor.bands[index]) + barMinHeight)
                    Spacer()
                }
            }
        }
        .padding(geometry.size.width * barSpacingFactor)
    }
}

extension AgentBarAudioVisualizer {
    private struct PhaseAnimationProperties {
        typealias HighlightedBars = Set<Int>

        private let barCount: Int
        private let veryLongDuration: TimeInterval = 1000

        init(barCount: Int) {
            self.barCount = barCount
        }

        func duration(agentState: AgentState) -> TimeInterval {
            switch agentState {
            case .connecting, .initializing: return 2 / Double(barCount)
            case .listening: return 0.5
            case .thinking: return 0.15
            case .speaking: return veryLongDuration
            default: return veryLongDuration
            }
        }

        func highlightingSequence(agentState: AgentState) -> [HighlightedBars] {
            switch agentState {
            case .connecting, .initializing: return (0 ..< barCount).map { HighlightedBars([$0, barCount - 1 - $0]) }
            case .thinking: return Array((0 ..< barCount) + (0 ..< barCount).reversed()).map { HighlightedBars([$0]) }
            case .listening: return barCount % 2 == 0 ? [[(barCount / 2) - 1, barCount / 2], []] : [[barCount / 2], []]
            case .speaking: return [HighlightedBars(0 ..< barCount)]
            default: return [[]]
            }
        }
    }
}
