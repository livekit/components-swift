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

// TODO: Move this to SDK
extension Room {
    var firstAgentParticipant: RemoteParticipant? {
        remoteParticipants.values.first { $0.kind == .agent }
    }
}

public struct AgentBarAudioVisualizer: View {
    public let barColor: Color
    public let barCount: Int
    public let barCornerRadius: CGFloat
    public let barSpacingFactor: CGFloat
    public let barMinOpacity: Double
    public let isCentered: Bool

    @EnvironmentObject private var room: Room

    public init(barColor: Color = .primary,
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
        self.barMinOpacity = barMinOpacity
        self.isCentered = isCentered
    }

    public var body: some View {
        let firstAgentParticipant = room.firstAgentParticipant
        let agentState = firstAgentParticipant?.agentState ?? .unknown
        let firstAudioPublication = firstAgentParticipant?.firstAudioPublication as? RemoteTrackPublication
        let track = firstAudioPublication?.track

        let animation = agentState == .speaking
            ? nil
            : Animation.easeInOut(duration: 1)
            .repeatForever(autoreverses: true)
            .speed(1)

        BarAudioVisualizer(audioTrack: track as? AudioTrack,
                           barColor: barColor,
                           barCount: barCount,
                           barCornerRadius: barCornerRadius,
                           barSpacingFactor: barSpacingFactor,
                           barMinOpacity: barMinOpacity,
                           isCentered: isCentered)
            .id(track)
            .opacity(agentState == .speaking ? 1 : 0.3)
            .animation(animation, value: agentState)
    }
}
