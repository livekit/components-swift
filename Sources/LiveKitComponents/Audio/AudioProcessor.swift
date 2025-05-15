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

@preconcurrency import AVFoundation
import LiveKit

@MainActor
public final class AudioProcessor: ObservableObject, AudioRenderer {
    public let isCentered: Bool
    public let smoothingFactor: Float

    /// Normalized to 0.0-1.0 range.
    @Published public private(set) var bands: [Float]

    private let processor: AudioVisualizeProcessor
    private weak var track: AudioTrack?

    public init(track: AudioTrack?,
                bandCount: Int,
                isCentered: Bool = true,
                smoothingFactor: Float = 0.25)
    {
        self.isCentered = isCentered
        self.smoothingFactor = smoothingFactor
        bands = Array(repeating: 0.0, count: bandCount)

        processor = AudioVisualizeProcessor(bandsCount: bandCount)

        self.track = track
        track?.add(audioRenderer: self)
    }

    deinit {
        track?.remove(audioRenderer: self)
    }

    public nonisolated func render(pcmBuffer: AVAudioPCMBuffer) {
        Task {
            let newBands = await processor.process(pcmBuffer: pcmBuffer)
            guard var newBands else { return }

            // If centering is enabled, rearrange the normalized bands
            if isCentered {
                newBands.sort(by: >)
                newBands = Self.centerBands(newBands)
            }

            await MainActor.run { [newBands] in
                bands = zip(bands, newBands).map { old, new in
                    Self.smoothTransition(from: old, to: new, factor: smoothingFactor)
                }
            }
        }
    }

    // MARK: - Private

    /// Centers the sorted bands by placing higher values in the middle.
    @inline(__always) private nonisolated static func centerBands(_ sortedBands: [Float]) -> [Float] {
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
    @inline(__always) private nonisolated static func smoothTransition(from oldValue: Float, to newValue: Float, factor: Float) -> Float {
        // Calculate the delta change between the old and new value
        let delta = newValue - oldValue
        // Apply an ease-in-out cubic easing curve
        let easedFactor = easeInOutCubic(t: factor)
        // Calculate and return the smoothed value
        return oldValue + delta * easedFactor
    }

    /// Easing function: ease-in-out cubic
    @inline(__always) private nonisolated static func easeInOutCubic(t: Float) -> Float {
        t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2
    }
}
