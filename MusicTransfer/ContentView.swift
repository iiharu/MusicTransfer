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
    
    var dict: Dictionary<NSNumber, String> = [:]
    
    init() {}
    
    init(walkman_music_folder: String) {
        if (walkman_music_folder != "") {
            self.walkman_music_folder = walkman_music_folder
        }
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
        let allPlaylist = library.allPlaylists.filter({$0.isMaster != true}).filter({$0.items.count > 0})

        for list in allPlaylist {
            transfer(playlist: list)
            return
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
        let homeFolderLocation: URL = FileManager.default.homeDirectoryForCurrentUser
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

        // copy
        // file exsits and dir -> ok
        // file exsits and not dir -> ng
        // file not exsits -> ok
        let parentFolderLocation = dst.deletingLastPathComponent()
        return
        let dryrun = true
        if (!dryrun) {
            do {
                var isDir:ObjCBool = ObjCBool(false)
                if (FileManager.default.fileExists(atPath: dst.path, isDirectory: &isDir)) {
                    if (!isDir.boolValue) {
                        // raise Error
                        print("\(parentFolderLocation.path) is exsists, but it is not directory")
                        return
                    }
                } else {
                        try FileManager.default.createDirectory(at: parentFolderLocation, withIntermediateDirectories: true, attributes: nil)
              
                }
                try FileManager.default.copyItem(at: src, to: dst)
            }
            catch (let e) {
                print(e)
            }
        }
    }
    
    func transfer(playlist: ITLibPlaylist) {
        print(playlist.name)
        let items = playlist.items.map({dict[$0.persistentID]}).filter({$0 != nil})
//        let count: int = items.reduce(0, {$0 + [$0 != nil ]})
        let count: Int = items.reduce(0, {$0 + (($1 != nil) ? 1 : 0)})
        let m38u: URL = URL(fileURLWithPath: walkman_music_folder).appendingPathComponent(playlist.name + ".m38u")
        // print(items)
        print(items[0])
        print(items.count)
        print(count)
    }

}

