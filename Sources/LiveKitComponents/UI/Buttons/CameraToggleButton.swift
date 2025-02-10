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

/// The Camera Toggle Button is a button that toggles the camera on and off.
public struct CameraToggleButton<Label: View, PublishedLabel: View>: View {
    private let _label: ComponentBuilder<Label>
    private let _publishedLabel: ComponentBuilder<PublishedLabel>

    @EnvironmentObject private var _room: Room
    @State private var _isBusy = false

    public var isCameraEnabled: Bool {
        _room.localParticipant.isCameraEnabled()
    }

    public init(@ViewBuilder label: @escaping ComponentBuilder<Label>,
                @ViewBuilder published: @escaping ComponentBuilder<PublishedLabel>)
    {
        _label = label
        _publishedLabel = published
    }

    public var body: some View {
        Button {
            Task {
                _isBusy = true
                defer { Task { @MainActor in _isBusy = false } }
                try await _room.localParticipant.setCamera(enabled: !isCameraEnabled)
            }
        } label: {
            if isCameraEnabled {
                _publishedLabel()
            } else {
                _label()
            }
        }.disabled(_isBusy)
    }
}
