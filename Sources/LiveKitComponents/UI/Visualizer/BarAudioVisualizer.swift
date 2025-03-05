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
    public let barColor: Color
    public let barCount: Int
    public let barCornerRadius: CGFloat
    public let barSpacingFactor: CGFloat
    public let barMinOpacity: Double
    public let isCentered: Bool

    @StateObject private var audioProcessor: AudioProcessor

    public init(audioTrack: AudioTrack?,
                barColor: Color = .primary,
                barCount: Int = 5,
                barCornerRadius: CGFloat = 100,
                barSpacingFactor: CGFloat = 0.015,
                barMinOpacity: CGFloat = 0.35,
                isCentered: Bool = true)
    {
        self.barColor = barColor
        self.barCount = barCount
        self.barCornerRadius = barCornerRadius
        self.barSpacingFactor = barSpacingFactor
        self.barMinOpacity = Double(barMinOpacity)
        self.isCentered = isCentered

        _audioProcessor = StateObject(wrappedValue: AudioProcessor(track: audioTrack,
                                                                   bandCount: barCount,
                                                                   isCentered: isCentered))
    }

    public var body: some View {
        GeometryReader { geometry in
            bars(geometry: geometry)
        }
    }

    @ViewBuilder
    private func bars(geometry: GeometryProxy) -> some View {
        let barMinHeight = (geometry.size.width - geometry.size.width * barSpacingFactor * CGFloat(barCount + 2)) / CGFloat(barCount)
        HStack(alignment: .center, spacing: geometry.size.width * barSpacingFactor) {
            ForEach(0 ..< audioProcessor.bands.count, id: \.self) { index in
                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: barMinHeight)
                        .fill(barColor)
                        .frame(height: (geometry.size.height - barMinHeight) * CGFloat(audioProcessor.bands[index]) + barMinHeight)
                    Spacer()
                }
            }
        }
        .padding(geometry.size.width * barSpacingFactor)
    }
}
