/*
 * Copyright 2024 LiveKit
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
    @EnvironmentObject var participant: Participant
    @EnvironmentObject var ui: UIPreference

    let showInformation: Bool

    public init(showInformation: Bool = true) {
        self.showInformation = showInformation
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                let cameraReference = TrackReference(participant: participant, source: .camera)

                if cameraReference.isResolvable {
                    VideoTrackPublicationView()
                        .environmentObject(cameraReference)
                } else {
                    ui.videoDisabledView(geometry: geometry)
                }

                if showInformation {
                    ParticipantInformationView()
                        .padding(5)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(7)
                        .padding()
                }
            }
        }
    }
}
