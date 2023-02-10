//
//  ContentView.swift
//  PreventScreenGrab
//
//  Created by Daniel Bonates on 10/02/23.
//

import SwiftUI

struct ContentView: View {
    @State var hideMe: Bool = false
    var body: some View {
        VStack {
            Toggle("Hide Hello World from screenshot", isOn: $hideMe)
            Spacer()
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Text("Hello, world!")
                Text("Test it on device!")
                    .font(.footnote)
            }
            .hiddenFromSystemSnaphot(when: hideMe)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
