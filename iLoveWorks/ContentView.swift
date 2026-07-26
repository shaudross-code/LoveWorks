//
//  ContentView.swift
//  iLoveWorks
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "clock.fill")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("ClockWork iOS")
                .font(.headline)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
