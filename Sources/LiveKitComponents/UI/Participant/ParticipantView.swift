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

public struct ParticipantView: View {
    private let _showInformation: Bool

    @EnvironmentObject private var _participant: Participant
    @Environment(\.liveKitUIOptions) private var _ui: UIOptions

    public init(showInformation: Bool = true) {
        _showInformation = showInformation
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            let cameraReference = TrackReference(participant: _participant, source: .camera)
            let microphoneReference = TrackReference(participant: _participant, source: .microphone)

            if let cameraTrack = cameraReference.resolve(), !cameraTrack.isMuted {
                VideoTrackView(trackReference: cameraReference)
            } else if let microphoneTrack = microphoneReference.resolve(), !microphoneTrack.isMuted,
                      let audioTrack = microphoneTrack.track as? AudioTrack
            {
                if _participant.isAgent {
                    AgentBarAudioVisualizer(audioTrack: audioTrack, agentState: _participant.agentState)
                } else {
                    BarAudioVisualizer(audioTrack: audioTrack)
                }
            } else {
                _ui.noTrackView()
            }

            if _showInformation {
                ParticipantInformationView()
                    .padding(5)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(7)
                    .padding()
            }
        }
        .animation(.easeOut, value: _participant.trackPublications)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
