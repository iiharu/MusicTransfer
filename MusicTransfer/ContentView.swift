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
// instance生成は, 最初からしておいて,
// paramをセットする方向
// ITLibraryは使い捨てでもいいのでは?
// 一番大事なこと. PlayListから曲を拾ってきた時にしっかりとしたパスが見つかること.
//
//  パスはStirngでなくURLで持ってた方が良さそう


class iTunesTransfer {
    
    var walkman_music_folder: String = "/Volumes/WALKMAN/MUSIC"
    // apiVersion
    // "1.0": iTunes.app, "1.1": Music.app
    var apiVersion: String = "1.1"
    
    let fileManager: FileManager = FileManager.default
    
    var dict: Dictionary<NSNumber, String> = [:]
    
    init() {}
    
    init(walkman_music_folder: String) {
        if (walkman_music_folder != "") {
            self.walkman_music_folder = walkman_music_folder
        }
        // self.walkman_music_folder = "/Users/iiharu/Desktop/WALKMAN/MUSIC"
    }
    
    func transfer() {
        // ITLibrary
        guard let library = try? ITLibrary(apiVersion: apiVersion) else {return} // raise Exception
        // AllSongItems
                
        // Transfer Songs
        let allSongItems = library.allMediaItems.filter({$0.mediaKind == ITLibMediaItemMediaKind.kindSong})
        for item in allSongItems {
            transfer(mediaItem: item)
        }
        
        // Transfer Playlists
        print("Transfer Playlists")
        let allPlaylist = library.allPlaylists.filter({$0.isMaster != true}).filter({$0.items.count > 0})
        for list in allPlaylist {
            transfer(playlist: list)
        }
        
    }
    
    func transfer(mediaItem: ITLibMediaItem) {
        // Returns mediaItem is not song.
        if (mediaItem.mediaKind != ITLibMediaItemMediaKind.kindSong) {
            print("mediaItem is not song")
            return
        }
        
        // Track
        let id = mediaItem.persistentID.intValue // NSValue
        guard let location = mediaItem.location else {
            print("mediaItem's location is nil")
            return
        }
        
        // src
        let src: URL = location
        // replace /Users/iiharu/Music/Music/Media.localized/Music -> walkman_music_folder
        
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
        
        // mediaItemPathから定義してるけど、
        // 転送先から定義して, walkman_music_folderを消すのがいいかも
        // mediaItemのとこから転送先を作っていくってなるとそっちの方が恋率良さそう
        var mediaItemPath:String = src.path
        if let range = mediaItemPath.range(of: (mediaFolderLocation.path + "/")) {
            mediaItemPath.replaceSubrange(range, with: "")
        }
        // Add Playlist
        dict[mediaItem.persistentID] = mediaItemPath
        
        let dst:URL = URL(fileURLWithPath: walkman_music_folder).appendingPathComponent(mediaItemPath)

        //print(mediaItemPath)
        //print(dst)


        // AlbumArtist
        //        let album = mediaItem.album
        //        var albumArtist = album.albumArtist
        //        if (albumArtist == nil) {
        //            if (album.isCompilation) {
        //                albumArtist = "Compilation"
        //            } else {
        //                albumArtist = mediaItem.artist?.name
        //            }
        //        }
        //        // AlbumTitle
        //        let albumTitle = album.title
        //        // AlbumDiscNumber
        //        let discNumber = album.discNumber
        //        // TrackNumber
        //        let trackNumber = mediaItem.trackNumber
        //        // Title
        //        let title = mediaItem.title
        //        // Extension
        //        let ext = location.pathExtension
        //        var dst = title + "." + ext
        //        if (trackNumber > 0) {
        //            dst = "\(trackNumber) \(dst)"
        //            if (discNumber > 0) {
        //                dst = "\(discNumber)-\(dst)"
        //            }
        //        }
        //        if (albumTitle != nil) {
        //            dst = albumTitle! + "/" + dst
        //        }
        //        if (albumArtist != nil) {
        //            dst = albumArtist! + "/" + dst
        //        }

        // Copy
        let parentFolderLocation = dst.deletingLastPathComponent()
        do {
            // CreateDirectory
            var isDir:ObjCBool = ObjCBool(false)
            if (fileManager.fileExists(atPath: dst.path, isDirectory: &isDir)) {
                if (!isDir.boolValue) {
                    // raise Error
                    print("\(parentFolderLocation.path) is exsists, but it is not directory")
                    return
                }
            } else {
                try fileManager.createDirectory(at: parentFolderLocation, withIntermediateDirectories: true, attributes: nil)
            }
            // CopyItem
            var willCopy: Bool = true
//            if (fileManager.fileExists(atPath: dst.path)) {
//                let srcModificationDate = try fileManager.attributesOfItem(atPath: src.path)[FileAttributeKey.modificationDate] as! Date
//                let dstModificationDate = try fileManager.attributesOfItem(atPath: dst.path)[FileAttributeKey.modificationDate] as! Date
//                if (srcModificationDate > dstModificationDate) {
//                    willCopy = true
//                } else {
//                    willCopy = false
//                }
//            }
            if (willCopy) {
                try fileManager.copyItem(at: src, to: dst)
            }
        }
        catch (let e) {
            print(e)
        }
    }
    
    func transfer(playlist: ITLibPlaylist) {

        // Filter out nil item
        let items:[String?] = playlist.items.map({dict[$0.persistentID]}).filter({$0 != nil})
        if (items.count == 0) {
            return
        }
        
        let m3u8: URL = URL(fileURLWithPath: walkman_music_folder).appendingPathComponent(playlist.name + ".M3U8")
        
        // Contents
        var contents: String = "#EXTM3U\n"
        for item in items {
            contents.append(contentsOf: "#EXTINF:,\n")
            contents.append(contentsOf: item! + "\n")
        }

        // Dump M3U8
        do {
            if (!fileManager.fileExists(atPath: m3u8.path)) {
                    fileManager.createFile(atPath: m3u8.path, contents: nil, attributes: nil)
            }
            let handle = try FileHandle(forUpdating: m3u8)
            handle.write(contents.data(using: .utf8)!)
            handle.closeFile()
        } catch let e {
            print(e)
        }
    }
}

