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

public struct LazyHorVGrid<Content: View>: View {
    private let _axis: Axis
    private let _spacing: CGFloat?
    private let _content: () -> Content

    public init(axis: Axis = .horizontal,
                spacing: CGFloat? = nil,
                @ViewBuilder content: @escaping () -> Content)
    {
        _axis = axis
        _spacing = spacing
        _content = content
    }

    public var body: some View {
        Group {
            if _axis == .vertical {
                LazyVGrid(columns: [GridItem(.flexible())], spacing: _spacing, content: _content)
            } else {
                LazyHGrid(rows: [GridItem(.flexible())], spacing: _spacing, content: _content)
            }
        }
    }
}
