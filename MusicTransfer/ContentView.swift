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
    let transfer: iTunesTransfer = iTunesTransfer()
    @State var walkman_music_folder: String = ""
    @State var is_transfering: Bool = false
    var body: some View {
        VStack{
            Text("WALKMAN MUSIC folder (such as /Volumes/WALKMAN/MUSIC)")
            TextField("/Volumes/WALKMAN/MUSIC", text: $walkman_music_folder).textFieldStyle(RoundedBorderTextFieldStyle()).padding()
            Button(action: {
                self.transfer.set_walkman_music_folder(dir: self.walkman_music_folder)
                // self.transfer.transfer()
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
    private (set) public var walkman_music_folder: String = "/Volumes/WALKMAN/MUSIC"
    // apiVersion ("1.0" -> iTunes.app, "1.1" -> Music.app)
    private var apiVersion: String = "1.1"
    // FileManager
    private let fileManager: FileManager = FileManager.default
    // SongDict persistentID -> NFC Normalized path from /Volumes/WALKMAN/MUSIC
    private var dict: Dictionary<NSNumber, String> = [:]
    // wheter transfering now
    private var is_transfering: Bool = false
    
    init() {}
    
    init(walkman_music_folder: String) {
        if (walkman_music_folder != "") {
            self.walkman_music_folder = walkman_music_folder
            // self.walkman_music_folder = "/Users/iiharu/Desktop/WALKMAN/MUSIC" // to debug
        }
    }
    
    func set_walkman_music_folder(dir: String) {
        var isDir: ObjCBool = ObjCBool(false)
        
        if (fileManager.fileExists(atPath: dir, isDirectory: &isDir) && isDir.boolValue) {
            self.walkman_music_folder = dir
        } else {
            print("no such directory \(dir)")
            return // TODO: raise Error
        }

        
    }
    
    // Transfer Library
    func transfer() {
        
        is_transfering = true
        
        // Check walkman_music_folder
        var isDir: ObjCBool = ObjCBool(false)
        if (fileManager.fileExists(atPath: self.walkman_music_folder, isDirectory: &isDir) && isDir.boolValue) {
            print("walkman_music_folder is exitst")
        } else {
            print("no such directory \(self.walkman_music_folder)")
            is_transfering = false
            return // TODO: raise Error
        }
        
        // ITLibrary
        guard let library: ITLibrary = try? ITLibrary(apiVersion: apiVersion) else {
            is_transfering = false
            return // TODO: raise Error
        }
        // AllSongItems
        
        // Transfer Songs
        let allSongItems: [ITLibMediaItem] = library.allMediaItems.filter({$0.mediaKind == ITLibMediaItemMediaKind.kindSong})
        for item: ITLibMediaItem in allSongItems {
            transfer(mediaItem: item)
            //return // TO DEBUG
        }
        
        //return // TO DEBUG
        
        // Transfer Playlists
        print("Transfer Playlists")
        let allPlaylist: [ITLibPlaylist] = library.allPlaylists.filter({$0.isMaster != true}).filter({$0.items.count > 0})
        for list: ITLibPlaylist in allPlaylist {
            transfer(playlist: list)
        }
        
        is_transfering = false
        return
    }

    // Replace `/` with `_`
    private func replace_slash_with_underscore(str: String) -> String {
        var _str: String = str
        while ((_str.range(of: "/")) != nil) {
            if let range = _str.range(of: "/") {
                _str.replaceSubrange(range, with: "_")
            }
        }
        return _str
    }

    // Get copy_dst (relative path from /Volumes/WALKMAN/MUSIC)
    private func get_copy_dst(item: ITLibMediaItem) -> String? {
        // Album
        let album: ITLibAlbum = item.album
        
        // Artist
        var albumArtist: String = ""
        if (album.albumArtist != nil) {
            albumArtist = album.albumArtist!
        } else {
            if (album.isCompilation) {
                albumArtist = "Compilation"
            } else if (item.artist?.name != nil) {
                albumArtist = item.artist!.name!
            }
        }
        albumArtist = replace_slash_with_underscore(str: albumArtist)
        
        // Title
        var albumTitle: String = album.title ?? ""
        albumTitle = replace_slash_with_underscore(str: albumTitle)
        
        // FileName
        guard var fileName: String = item.location?.lastPathComponent else {
            print("mediaItem's location is nil")
            return nil // TODO: raise Error
        }
        fileName = replace_slash_with_underscore(str: fileName)
        
        let copy_dst = albumArtist + "/" + albumTitle + "/" + fileName

        return copy_dst
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
        
        // mediaItemPath
        guard let mediaItemPath: String = get_copy_dst(item: mediaItem) else {
            print("get_copy_dst failed")
            return // TODO: raise Error
        }

        // Register mediaItemPath (UNICDOE NFC) to dictionary for transfer playlist.
        dict[id] = mediaItemPath.precomposedStringWithCanonicalMapping // NFD -> NFC

        // Append mediaItemPath to walkman_music_folder
        let dst: URL = URL(fileURLWithPath: self.walkman_music_folder).appendingPathComponent(mediaItemPath)
        // return // To debug
        
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

