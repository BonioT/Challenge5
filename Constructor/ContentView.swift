//
//  ContentView.swift
//  Constructor
//
//  Created by Antonio Bonetti on 24/02/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = SceneViewModel()
    @State private var snapshot: UIImage?

    var body: some View {
        NavigationStack {
            SceneBuilderView(viewModel: viewModel, snapshot: $snapshot)
                .navigationDestination(isPresented: Binding(
                    get: { snapshot != nil },
                    set: { if !$0 { snapshot = nil } }
                )) {
                    if let image = snapshot {
                        DrawView(backgroundImage: image)
                    }
                }
        }
    }
}

#Preview("ContentView") {
    ContentView()
}
