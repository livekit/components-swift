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

#if compiler(>=6.0)
extension EnvironmentValues {
    @Entry var liveKitUIOptions: UIOptions = .init()
}
#else
private struct UIOptionsKey: EnvironmentKey {
    // This is the default value that SwiftUI will fallback to if you don't pass the object
    public static var defaultValue: UIOptions = .init()
}

public extension EnvironmentValues {
    var liveKitUIOptions: UIOptions {
        get { self[UIOptionsKey.self] }
        set { self[UIOptionsKey.self] = newValue }
    }
}
#endif

public struct ComponentsScope<Content: View>: View {
    private let _content: () -> Content
    private let _options: UIOptions

    public init(uiOptions: UIOptions? = nil,
                @ViewBuilder _ content: @escaping () -> Content)
    {
        _options = uiOptions ?? UIOptions()
        _content = content
    }

    public var body: some View {
        _content()
            .environment(\.liveKitUIOptions, _options)
    }
}
