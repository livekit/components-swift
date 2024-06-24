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

public struct RoomScope<Content: View>: View {
    private let _content: () -> Content
    @StateObject private var _room: Room

    private let _url: String?
    private let _token: String?
    private let _connect: Bool

    private let _enableCamera: Bool
    private let _enableMicrophone: Bool

    public init(room: Room? = nil,
                url: String? = nil,
                token: String? = nil,
                connect: Bool = true,
                enableCamera: Bool = false,
                enableMicrophone: Bool = false,
                roomOptions: RoomOptions? = nil,
                @ViewBuilder _ content: @escaping () -> Content)
    {
        __room = StateObject(wrappedValue: room ?? Room(roomOptions: roomOptions))
        _url = url
        _token = token
        _connect = connect
        _enableCamera = enableCamera
        _enableMicrophone = enableMicrophone
        _content = content
    }

    public var body: some View {
        _content()
            .environmentObject(_room)
            .onAppear {
                if _connect, let url = _url, let token = _token {
                    Task {
                        try await _room.connect(url: url, token: token)
                        if _enableCamera { try await _room.localParticipant.setCamera(enabled: true) }
                        if _enableMicrophone { try await _room.localParticipant.setMicrophone(enabled: true) }
                    }
                }
            }
            .onDisappear {
                Task {
                    await _room.disconnect()
                }
            }
    }
}
