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

public struct LiveKitComponentsEnvironmentKey: EnvironmentKey {
    // This is the default value that SwiftUI will fallback to if you don't pass the object
    public static var defaultValue: UIPreference = .init()
}

public extension EnvironmentValues {
    var liveKitUIPreference: UIPreference {
        get { self[LiveKitComponentsEnvironmentKey.self] }
        set { self[LiveKitComponentsEnvironmentKey.self] = newValue }
    }
}

public struct ComponentsScope<Content: View>: View {
    var content: () -> Content
    let preference: UIPreference

    public init(configuration: UIPreference? = nil,
                @ViewBuilder _ content: @escaping () -> Content)
    {
        preference = configuration ?? UIPreference()
        self.content = content
    }

    public var body: some View {
        content()
            .environment(\.liveKitUIPreference, preference)
    }
}
