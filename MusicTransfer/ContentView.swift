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
    @ObservedObject var transfer: iTunesTransfer = iTunesTransfer()
    var body: some View {
        VStack{
            Text("WALKMAN MUSIC folder (such as /Volumes/WALKMAN/MUSIC)")
            // when on commit -> validate
            TextField("/Volumes/WALKMAN/MUSIC",
                      text: .init(
                        get:
                        {self.transfer.walkman_music_folder},
                        set:
                        {self.transfer.walkman_music_folder = $0}
                )
            ).textFieldStyle(RoundedBorderTextFieldStyle()).padding()
            Button(action: {
                self.transfer.transfer()
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
class iTunesTransfer : ObservableObject {
    // Walkman Music Folder
    @Published var walkman_music_folder: String = "/Volumes/WALKMAN/MUSIC"
    // apiVersion ("1.0" -> iTunes.app, "1.1" -> Music.app)
    private var apiVersion: String = "1.1"
    // FileManager
    private let fileManager: FileManager = FileManager.default
    
    // SongDict persistentID -> NFC Normalized path from /Volumes/WALKMAN/MUSIC
    private var dict: Dictionary<NSNumber, String> = [:]
    
    // Copy Location Map (persistentID -> (Copy src, Copy dst (NFD))
    private var copy_location_map: Dictionary<NSNumber, (src: String, dst: String)> = [:]
    
    // Playlist Map (name -> [NSNumber])
    private var playlist_map: Dictionary<String, [NSNumber]> = [:]
    
    // Class Method
    // Replace special char with
    private class func replace_special_char_with_underscore(str: String) -> String {
        var _str: String = str
        if (_str.hasSuffix(".")) {
            _str.removeLast()
            _str.append(contentsOf: "_")
        }
        let pattern = "[\"*/:<>?´’]"
        return _str.replacingOccurrences(of: pattern, with: "_", options: .regularExpression)
    }
    
    // Get dst (NFD) from item (relative path from WALKMAN_MUSIC_FOLDER (/Volumes/WALKMAN/MUSIC))
    private class func get_dst_from_item(item: ITLibMediaItem) -> String? {
        // Album
        let album: ITLibAlbum = item.album
        
        // Artist
        var artist: String = ""
        if (album.albumArtist != nil) {
            artist = album.albumArtist!
        } else {
            if (album.isCompilation) {
                artist = "Compilation"
            } else if (item.artist?.name != nil) {
                artist = item.artist!.name!
            }
        }
        artist = replace_special_char_with_underscore(str: artist)
        
        // Title
        var title: String = album.title ?? ""
        title = replace_special_char_with_underscore(str: title)
        
        // File Name
        guard var name: String = item.location?.lastPathComponent else {
            print("mediaItem's location is nil")
            return nil // TODO: raise Error
        }
        name = replace_special_char_with_underscore(str: name)
        
        let dst:String = artist + "/" + title + "/" + name
        
        return dst
    }
    
    // Get src dst modification interval
    func get_file_modification_interval(src: String, dst: String,
                                        fileManager: FileManager = FileManager.default) -> TimeInterval? {
        if (!fileManager.fileExists(atPath: src) || !fileManager.fileExists(atPath: dst)) {
            return nil
        }
        
        do {
            let srcModificationDate: Date = try fileManager.attributesOfItem(atPath: src)[FileAttributeKey.modificationDate] as! Date
            let dstModificaitonDate: Date = try fileManager.attributesOfItem(atPath: dst)[FileAttributeKey.modificationDate] as! Date
            let interval = srcModificationDate.timeIntervalSince(dstModificaitonDate)
            return interval
        } catch (let e) {
            print(e)
            return nil
        }
    }
    
    // Constructor
    init() {
        guard let library: ITLibrary = try? ITLibrary(apiVersion: apiVersion) else {
            print("Initialization ITLibrary failed.")
            return // TODO: raise Error
        }
        
        // Songs
        // allSongItems
        let allSongItems: [ITLibMediaItem] = library.allMediaItems.filter({$0.mediaKind == ITLibMediaItemMediaKind.kindSong && $0.location != nil})
        for item: ITLibMediaItem in allSongItems {
            // ID
            let id: NSNumber = item.persistentID
            // src
            guard let src: String = item.location?.path else {
                print("ITLibMediaItem's location is nil.")
                return // TODO: raise Error
            }
            // dst (relative path from /Volumes/WALKMAN/MUSIC)
            guard let dst: String = iTunesTransfer.get_dst_from_item(item: item) else {
                print("Set destination is failed.")
                return // TODO: raise Error
            }
            
            // Insert (src, dst) tuple to copy_location_map
            // CAUTION: dst is NFD (Normalization Form Canonical Decomposition)
            copy_location_map[id] = (src, dst)
        }
        
        // Playlists
        // allPlaylist
        let allPlaylist: [ITLibPlaylist] = library.allPlaylists.filter({$0.isMaster != true && $0.items.count > 0})
        for playlist: ITLibPlaylist in allPlaylist {
            // Track IDs
            let ids: [NSNumber] = playlist.items.map({$0.persistentID})
            // Insert (name, ids) pair to playlist map
            playlist_map[playlist.name] = ids
        }
    }
    
    // Instance Method
    func transfer_song(src: String, dst: String,
                       fileManager: FileManager = FileManager.default) -> Void {
        // Check src
        if (!fileManager.fileExists(atPath: src)) {
            return // TODO: push error to error stack
        }

        // Check dst parent dir
        let dstParDir: String = (dst as NSString).deletingLastPathComponent
        do {
            try fileManager.createDirectory(atPath: dstParDir, withIntermediateDirectories: true, attributes: nil)
        } catch (let e) {
            print(e)
            return // TODO: push error to error stack
        }

        // CopyItem
        if (fileManager.fileExists(atPath: dst)) {
            guard let interval = self.get_file_modification_interval(src: src, dst: dst, fileManager: fileManager) else {
                return // TODO: push error to error stack
            }
            if (abs(interval) < 60) {
                return // TODO: push error to error stack
            }
            do{
                try fileManager.removeItem(atPath: dst)
            } catch (let e) {
                print(e)
                return // TODO: push error to error stack
            }
        }
        do {
            try fileManager.copyItem(atPath: src, toPath: dst)
        } catch (let e) {
            print (e)
            return // TODO: push error to error stack
        }
    }

    // transfer playlist
    func transfer_playlist (name: String, items: [String?],
                            fileManager: FileManager = FileManager.default) -> Void {
        // M3U8
        let m3u8: String = [self.walkman_music_folder, name + ".M3U8"].joined(separator: "/")

        // Contents
        var contents: String = "#EXTM3U\n"
        for item: String? in items {
            contents.append(contentsOf: "#EXTINF:,\n")
            contents.append(contentsOf: item! + "\n")
        }

        // Dump
        fileManager.createFile(atPath: m3u8, contents: nil, attributes: nil)
        guard let handle: FileHandle = FileHandle(forUpdatingAtPath: m3u8) else {
            return // TODO: push error to error stack
        }
        handle.write(contents.data(using: .utf8)!)
        handle.closeFile()
    }

    func transfer () -> Void {
        
        var isDir: ObjCBool = ObjCBool(false)
        
        // Check WALKMAN_MUSIC_FOLDER
        if (!fileManager.fileExists(atPath: self.walkman_music_folder, isDirectory: &isDir) || !isDir.boolValue) {
            print("No such directory \(self.walkman_music_folder)")
            return // TODO: raise Error
        }

        // Transfer Songs
        let dispatch_group = DispatchGroup()
        for (_, (src, dst)) in copy_location_map {
            DispatchQueue.global().async(group: dispatch_group){
                let copySrc: String = src
                let copyDst: String = [self.walkman_music_folder, dst].joined(separator: "/")
                self.transfer_song(src: copySrc, dst: copyDst)
            }
        }
        let _ = dispatch_group.wait(timeout: .distantFuture)
        
        // Transfer Playlist
        for (name, ids) in playlist_map {
            // get item relative path (as unicode nfc)
            let items: [String?] = ids.map({copy_location_map[$0]?.dst.precomposedStringWithCanonicalMapping}).filter({$0 != nil})
            DispatchQueue.global().async(group: dispatch_group){
                self.transfer_playlist(name: name, items: items)
            }
        }
        let _ = dispatch_group.wait(timeout: .distantFuture)
    }

}

