//
//  Safari.swift
//  Deliberate
//
//  Created by Daniele Spaccapeli on 13/03/25.
//

import SwiftUI
import SafariServices

struct Safari: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
