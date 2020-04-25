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
    private var copy_location_map: Dictionary<NSNumber, (src: URL, dst: String)> = [:]
    
    // Playlist Map (name -> [NSNumber])
    private var playlist_map: Dictionary<String, [NSNumber]> = [:]
    
    
    // Class Method
    // Replace `/` with `_`
    private class func replace_slash_with_underscore(str: String) -> String {
        var _str: String = str
        while ((_str.range(of: "/")) != nil) {
            if let range = _str.range(of: "/") {
                _str.replaceSubrange(range, with: "_")
            }
        }
        return _str
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
        artist = replace_slash_with_underscore(str: artist)
        
        // Title
        var title: String = album.title ?? ""
        title = replace_slash_with_underscore(str: title)
        
        // File Name
        guard var name: String = item.location?.lastPathComponent else {
            print("mediaItem's location is nil")
            return nil // TODO: raise Error
        }
        name = replace_slash_with_underscore(str: name)
        
        let dst:String = artist + "/" + title + "/" + name
        
        return dst
    }
    
    // Get src dst modification interval
    func get_file_modification_interval(src: String, dst: String) -> TimeInterval? {
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
            // src (location)
            guard let src: URL = item.location else {
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
    func transfer () -> Void {
        
        var isDir: ObjCBool = ObjCBool(false)
        
        // Check WALKMAN_MUSIC_FOLDER
        if (!fileManager.fileExists(atPath: self.walkman_music_folder, isDirectory: &isDir) || !isDir.boolValue) {
            print("No such directory \(self.walkman_music_folder)")
            return // TODO: raise Error
        }

        // Transfer Songs
        for (_, (src, dst)) in copy_location_map {
            
            // destination
            let dstLocation: URL = URL(fileURLWithPath: self.walkman_music_folder).appendingPathComponent(dst)
            
            // parentFolderLocation
            let parentFolderLocation: URL = dstLocation.deletingLastPathComponent()

            // Create parentFolderLocation does not exists.
            if (!fileManager.fileExists(atPath: parentFolderLocation.path, isDirectory: &isDir)) {
                // createDirectory
                do {
                    try fileManager.createDirectory(at: parentFolderLocation, withIntermediateDirectories: true, attributes: nil)
                } catch (let e) {
                    print(e)
                }
            } else if (!isDir.boolValue) {
                // Skip if parentFolderLocation is exist and not folder
                print("\(parentFolderLocation) exist and not folder")
                continue // TODO: raise Error
            }
            
            // CopyItem
            if (fileManager.fileExists(atPath: dstLocation.path)) {
                // get interval copy src between copy dst
                guard let interval = get_file_modification_interval(src: src.path, dst: dstLocation.path) else {
                    continue
                }
                // if interval is -60 ~ 60 then skip copy
                if (abs(interval) < 60) {
                    continue
                }
                // copy dst is old then remove dst
                do {
                    try fileManager.removeItem(at: dstLocation)
                } catch (let e) {
                    print(e)
                }
            }
            do {
                try fileManager.copyItem(at: src, to: dstLocation)
            } catch(let e) {
                print(e)
            }
        }
        
        // Transfer Playlist
        for (name, ids) in playlist_map {
            // [NFC String]
            let items: [String?] = ids.map({copy_location_map[$0]?.dst.precomposedStringWithCanonicalMapping}).filter({$0 != nil})
            
            // M3U8
            let m3u8: URL = URL(fileURLWithPath: self.walkman_music_folder).appendingPathComponent(name + ".M3U8")

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
}

