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

import SwiftUI

/// A drop-in replacement `Button` that executes an async action and shows a busy label when in progress.
///
/// - Parameters:
///   - action: The async action to execute (can be throwing).
///   - label: The label to show when not busy.
///   - busyLabel: The label to show when busy. Defaults to an empty view.
///   - onError: Optional closure to handle errors thrown by the action.
public struct AsyncButton<Label: View, BusyLabel: View>: View {
    private let action: () async throws -> Void
    private let onError: ((Error) -> Void)?

    @ViewBuilder private let label: Label
    @ViewBuilder private let busyLabel: BusyLabel

    @State private var isBusy = false

    public init(
        action: @escaping () async throws -> Void,
        @ViewBuilder label: () -> Label,
        @ViewBuilder busyLabel: () -> BusyLabel = EmptyView.init,
        onError: ((Error) -> Void)? = nil
    ) {
        self.action = action
        self.onError = onError
        self.label = label()
        self.busyLabel = busyLabel()
    }

    public var body: some View {
        Button {
            isBusy = true
            Task {
                do {
                    try await action()
                } catch {
                    onError?(error)
                }
                isBusy = false
            }
        } label: {
            if isBusy {
                if busyLabel is EmptyView {
                    label
                } else {
                    busyLabel
                }
            } else {
                label
            }
        }
        .disabled(isBusy)
    }
}
