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

import AVFoundation
import LiveKit
import SwiftUI

public class AudioProcessor: ObservableObject, AudioRenderer {
    public let isCentered: Bool
    public let smoothingFactor: Float

    // Normalized to 0.0-1.0 range.
    @Published public var bands: [Float]

    private let _processor: AudioVisualizeProcessor
    private weak var _track: AudioTrack?

    public init(track: AudioTrack?,
                bandCount: Int,
                isCentered: Bool = true,
                smoothingFactor: Float = 0.3)
    {
        self.isCentered = isCentered
        self.smoothingFactor = smoothingFactor
        bands = Array(repeating: 0.0, count: bandCount)

        _processor = AudioVisualizeProcessor(bandsCount: bandCount)
        _track = track
        _track?.add(audioRenderer: self)
    }

    deinit {
        _track?.remove(audioRenderer: self)
    }

    public func render(pcmBuffer: AVAudioPCMBuffer) {
        let newBands = _processor.process(pcmBuffer: pcmBuffer)
        guard var newBands else { return }

        // If centering is enabled, rearrange the normalized bands
        if isCentered {
            newBands.sort(by: >)
            newBands = centerBands(newBands)
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            self.bands = zip(self.bands, newBands).map { old, new in
                self._smoothTransition(from: old, to: new, factor: self.smoothingFactor)
            }
        }
    }

    // MARK: - Private

    /// Centers the sorted bands by placing higher values in the middle.
    @inline(__always) private func centerBands(_ sortedBands: [Float]) -> [Float] {
        var centeredBands = [Float](repeating: 0, count: sortedBands.count)
        var leftIndex = sortedBands.count / 2
        var rightIndex = leftIndex

        for (index, value) in sortedBands.enumerated() {
            if index % 2 == 0 {
                // Place value to the right
                centeredBands[rightIndex] = value
                rightIndex += 1
            } else {
                // Place value to the left
                leftIndex -= 1
                centeredBands[leftIndex] = value
            }
        }

        return centeredBands
    }

    /// Applies an easing function to smooth the transition.
    @inline(__always) private func _smoothTransition(from oldValue: Float, to newValue: Float, factor: Float) -> Float {
        // Calculate the delta change between the old and new value
        let delta = newValue - oldValue
        // Apply an ease-in-out cubic easing curve
        let easedFactor = _easeInOutCubic(t: factor)
        // Calculate and return the smoothed value
        return oldValue + delta * easedFactor
    }

    /// Easing function: ease-in-out cubic
    @inline(__always) private func _easeInOutCubic(t: Float) -> Float {
        t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2
    }
}

/// A SwiftUI view that visualizes audio levels as a series of vertical bars,
/// responding to real-time audio data processed from an audio track.
///
/// `BarAudioVisualizer` displays bars whose heights and opacities dynamically
/// reflect the magnitude of audio frequencies in real time, creating an
/// interactive, visual representation of the audio track's spectrum. This
/// visualizer can be customized in terms of bar count, color, corner radius,
/// spacing, and whether the bars are centered based on frequency magnitude.
///
/// Usage:
/// ```
/// let audioTrack: AudioTrack = ...
/// BarAudioVisualizer(audioTrack: audioTrack)
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
/// BarAudioVisualizer(audioTrack: audioTrack, barColor: .blue, barCount: 10)
/// ```
public struct BarAudioVisualizer: View {
    public let barCount: Int
    public let barColor: Color
    public let barCornerRadius: CGFloat
    public let barSpacingFactor: CGFloat
    public let barMinOpacity: Double
    public let isCentered: Bool

    public let audioTrack: AudioTrack?
    public let agentState: AgentState?

    @StateObject private var audioProcessor: AudioProcessor

    @State private var animationProperties: PhaseAnimationProperties
    @State private var animationPhase: Int = 0

    public init(audioTrack: AudioTrack?,
                agentState: AgentState? = nil,
                barColor: Color = .white,
                barCount: Int = 7,
                barCornerRadius: CGFloat = 100,
                barSpacingFactor: CGFloat = 0.015,
                barMinOpacity: CGFloat = 0.35,
                isCentered: Bool = true)
    {
        self.audioTrack = audioTrack
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
            let duration = animationProperties.duration(agentState: agentState)
            let highlightingSequence = animationProperties.highlightingSequence(agentState: agentState)
            if #available(iOS 17.0, *) {
                PhaseAnimator(highlightingSequence) { highlighted in
                    bars(geometry: geometry, highlighted: highlighted)
                } animation: { _ in
                    .easeInOut(duration: duration)
                }
            } else {
                let highlighted = highlightingSequence[animationPhase % highlightingSequence.count]
                bars(geometry: geometry, highlighted: highlighted)
                    .onAppear {
                        Task {
                            while !Task.isCancelled {
                                try? await Task.sleep(nanoseconds: UInt64(duration * Double(NSEC_PER_SEC)))
                                withAnimation(.easeInOut(duration: duration)) { animationPhase += 1 }
                            }
                        }
                    }
                    .onChange(of: agentState) { _ in
                        animationPhase = 0
                    }
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

private struct PhaseAnimationProperties {
    typealias HighlightedBars = Set<Int>

    private let durations: [AgentState: TimeInterval]
    private let sequences: [AgentState: [HighlightedBars]]

    init(barCount: Int) {
        durations = [
            .connecting: 2 / Double(barCount),
            .initializing: 2,
            .listening: 0.5,
            .thinking: 0.15,
            .speaking: 1000,
        ]
        sequences = [
            .connecting: Self.generateConnectingSequence(barCount: barCount),
            .initializing: Self.generateThinkingSequence(barCount: barCount),
            .listening: Self.generateListeningSequence(barCount: barCount),
            .thinking: Self.generateThinkingSequence(barCount: barCount),
            .speaking: Self.generateSpeakingSequence(barCount: barCount),
        ]
    }

    func duration(agentState: AgentState?) -> TimeInterval {
        guard let agentState else { return 1 }
        return durations[agentState] ?? 1
    }

    func highlightingSequence(agentState: AgentState?) -> [HighlightedBars] {
        guard let agentState else { return [[]] }
        return sequences[agentState] ?? [[]]
    }

    private static func generateConnectingSequence(barCount: Int) -> [HighlightedBars] {
        var seq: [HighlightedBars] = []
        for x in 0 ..< barCount {
            seq.append(HighlightedBars([x, barCount - 1 - x]))
        }
        return seq
    }

    private static func generateThinkingSequence(barCount: Int) -> [HighlightedBars] {
        var seq: [HighlightedBars] = []
        for x in 0 ..< barCount {
            seq.append([x])
        }
        for x in (0 ..< barCount).reversed() {
            seq.append([x])
        }
        return seq
    }

    private static func generateListeningSequence(barCount: Int) -> [HighlightedBars] {
        let center = barCount / 2
        return [[center], []]
    }

    private static func generateSpeakingSequence(barCount: Int) -> [HighlightedBars] {
        [Set(Array(0 ..< barCount))]
    }
}
