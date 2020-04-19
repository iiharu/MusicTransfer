//
//  ContentView.swift
//  MusicTransfer
//
//  Created by Yasuharu Iida on 2020/04/01.
//  Copyright © 2020 Yasuharu Iida. All rights reserved.
//

import SwiftUI
import iTunesLibrary

struct ContentView: View {
    @State var walkman_music_folder = ""
    var body: some View {
        VStack{
            Text("WALKMAN MUSIC folder (such as /Volumes/WALKMAN/MUSIC)")
            TextField("/Volumes/WALKMAN/MUSIC", text: $walkman_music_folder).textFieldStyle(RoundedBorderTextFieldStyle()).padding()
            Button(action:{
                let transfer = iTunesTransfer(walkman_music_folder: self.walkman_music_folder)
                transfer.transfer()
            }) {Text("Transfer!")}
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


// iTunes Transfer
class iTunesTransfer {
    
    // Walkman Music Folder
    var walkman_music_folder: String = "/Volumes/WALKMAN/MUSIC"
    // apiVersion ("1.0" -> iTunes.app, "1.1" -> Music.app)
    var apiVersion: String = "1.1"
    // FileManager
    let fileManager: FileManager = FileManager.default
    // SongDict persistentID -> NFC Normalized path from /Volumes/WALKMAN/MUSIC
    var dict: Dictionary<NSNumber, String> = [:]
    
    init() {}
    
    init(walkman_music_folder: String) {
        if (walkman_music_folder != "") {
            self.walkman_music_folder = walkman_music_folder
        }
    }
    
    // Transfer Library
    func transfer() {
        // ITLibrary
        guard let library: ITLibrary = try? ITLibrary(apiVersion: apiVersion) else {return} // raise Exception
        // AllSongItems
        
        // Transfer Songs
        let allSongItems: [ITLibMediaItem] = library.allMediaItems.filter({$0.mediaKind == ITLibMediaItemMediaKind.kindSong})
        for item: ITLibMediaItem in allSongItems {
            transfer(mediaItem: item)
        }
        
        // Transfer Playlists
        print("Transfer Playlists")
        let allPlaylist: [ITLibPlaylist] = library.allPlaylists.filter({$0.isMaster != true}).filter({$0.items.count > 0})
        for list: ITLibPlaylist in allPlaylist {
            transfer(playlist: list)
        }
    }
    
    // Transfer MediaItem
    func transfer(mediaItem: ITLibMediaItem) {
        // Returns mediaItem is not song.
        if (mediaItem.mediaKind != ITLibMediaItemMediaKind.kindSong) {
            print("mediaItem is not song")
            return
        }
        
        // Track
        let id: NSNumber = mediaItem.persistentID
        // Returns if mediaItem.location is nil.
        guard let location: URL = mediaItem.location else {
            print("mediaItem's location is nil")
            return
        }
        
        // src
        let src: URL = location
        
        // dst
        let homeFolderLocation: URL = fileManager.homeDirectoryForCurrentUser
        var mediaFolderLocation: URL = homeFolderLocation
        if (atof(apiVersion) > 1.0) {
            for d in ["Music", "Music", "Media.localized", "Music"]
            {
                mediaFolderLocation.appendPathComponent(d, isDirectory: true)
            }
        } else {
            for d in ["Music", "iTunes", "iTunes Media"]
            {
                mediaFolderLocation.appendPathComponent(d, isDirectory: true)
            }
        }
        
        // MediaItemPath (path from /Volumes/WALKMAN/MUSIC/)
        var mediaItemPath: String = src.path
        if let range = mediaItemPath.range(of: (mediaFolderLocation.path + "/")) {
            mediaItemPath.replaceSubrange(range, with: "")
        }
        // Add Playlist
        // Registar mediaItem path to dictionary for transfering playlist.
        dict[id] = mediaItemPath.precomposedStringWithCanonicalMapping // NFD -> NFC
        // dst (`copy to` path form /)
        let dst: URL = URL(fileURLWithPath: walkman_music_folder).appendingPathComponent(mediaItemPath)
        
        // CreateDirectory if not exists.
        let parentFolderLocation: URL = dst.deletingLastPathComponent()
        var isDir: ObjCBool = ObjCBool(false)
        if (fileManager.fileExists(atPath: dst.path, isDirectory: &isDir) && !isDir.boolValue) {
            print("\(parentFolderLocation.path) is exsists, but it is not directory")
            return
        }
        do {
            try fileManager.createDirectory(at: parentFolderLocation, withIntermediateDirectories: true, attributes: nil)
        }
        catch (let e) {
            print(e)
        }
        
        // CopyItem
        var willCopy: Bool = true
        do {
            if (fileManager.fileExists(atPath: dst.path)) {
                let srcModificationDate = try fileManager.attributesOfItem(atPath: src.path)[FileAttributeKey.modificationDate] as! Date
                let dstModificationDate = try fileManager.attributesOfItem(atPath: dst.path)[FileAttributeKey.modificationDate] as! Date
                if (dstModificationDate > srcModificationDate) {
                    willCopy = false
                }
            }
        } catch(let e) {
            print(e)
        }
        do {
            if (willCopy) {
                try fileManager.copyItem(at: src, to: dst)
            }
        } catch (let e) {
            print(e)
        }
        
    }
    
    // Transfer Playlist
    func transfer(playlist: ITLibPlaylist) {
        
        // Filter out nil item
        let items: [String?] = playlist.items.map({dict[$0.persistentID]}).filter({$0 != nil})
        if (items.count == 0) {
            return
        }
        
        // M3U8 path
        let m3u8: URL = URL(fileURLWithPath: walkman_music_folder).appendingPathComponent(playlist.name + ".M3U8")
        
        // M3U8 Contents
        var contents: String = "#EXTM3U\n"
        for item: String? in items {
            contents.append(contentsOf: "#EXTINF:,\n")
            contents.append(contentsOf: item! + "\n")
        }
        
        // Dump M3U8
        if (!fileManager.fileExists(atPath: m3u8.path)) {
            fileManager.createFile(atPath: m3u8.path, contents: nil, attributes: nil)
        }
        do {
            let handle: FileHandle = try FileHandle(forUpdating: m3u8)
            handle.write(contents.data(using: .utf8)!)
            handle.closeFile()
        } catch (let e) {
            print(e)
        }
    }
    
}

