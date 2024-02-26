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

/// The Camera Toggle Button is a button that toggles the camera on and off.
public struct CameraToggleButton<Label: View, PublishedLabel: View>: View {
    @EnvironmentObject var room: Room
    @State var isBusy = false

    let label: ComponentBuilder<Label>
    let publishedLabel: ComponentBuilder<PublishedLabel>

    public init(@ViewBuilder label: @escaping ComponentBuilder<Label>, @ViewBuilder published: @escaping ComponentBuilder<PublishedLabel>) {
        self.label = label
        publishedLabel = published
    }

    var isCameraEnabled: Bool {
        room.localParticipant.isCameraEnabled()
    }

    public var body: some View {
        Button {
            Task {
                isBusy = true
                defer { Task { @MainActor in isBusy = false } }
                try await room.localParticipant.setCamera(enabled: !isCameraEnabled)
            }
        } label: {
            if isCameraEnabled {
                publishedLabel()
            } else {
                label()
            }
        }.disabled(isBusy)
    }
}
