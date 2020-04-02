//
//  ContentView.swift
//  MusicTransfer
//
//  Created by Yasuharu Iida on 2020/04/01.
//  Copyright © 2020 Yasuharu Iida. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State var walkman_music_folder = ""
    var body: some View {
        VStack{
            Text("WALKMAN MUSIC folder (such as /Volumes/WALKMAN/MUSIC)")
            TextField("/Volumes/WALKMAN/MUSIC", text: $walkman_music_folder).textFieldStyle(RoundedBorderTextFieldStyle()).padding()
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
