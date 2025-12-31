//
//  ClipboardHelpers.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/27.
//

import SwiftUI

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

func copyToClipboard(_ text: String) {
    #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    #elseif os(iOS)
        UIPasteboard.general.string = text
    #endif
}
