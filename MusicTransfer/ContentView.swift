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
    
//    class Track {
//        // let id: Int
//        // let trackNumber: Int
//        // let title: String
//        // let artist: ITLibArtist
//        // let album: ITLibAlbum
//        // let location: URL
//        let mediaItem: ITLibMediaItem
//        init(mediaItem: ITLibMediaItem) {
//            self.mediaItem = mediaItem;
//        }
//    }
//    class Playlist {
//        // let title: String
//        // let items: [ITLibMediaItem]
//        let playlist: ITLibPlaylist
//        init(playlist: ITLibPlaylist) {
//            self.playlist = playlist
//        }
//    }
    
    var walkman_music_folder: String = "/Volumes/WALKMAN/MUSIC"
    // apiVersion
    // "1.0": iTunes.app, "1.1": Music.app
    var apiVersion: String = "1.1"
    
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
        
        // var allPlaylists = library.allPlaylists
        // var allMediaItems = library.allMediaItems
        // var allSongItems = allMediaItems.filter({$0.mediaKind == ITLibMediaItemMediaKind.kindSong})
        
        // Transfer Songs
        let allSongItems = library.allMediaItems.filter({$0.mediaKind == ITLibMediaItemMediaKind.kindSong})
        
        for item in allSongItems {
            transfer(mediaItem: item)
            return
        }
        
        // Transfer Playlists
        
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
        var str = src.path
        if let range = str.range(of: mediaFolderLocation.path) {
            str.replaceSubrange(range, with: walkman_music_folder)
        }
        let dst = URL(fileURLWithPath: str)
        
        // copy
        // file exsits and dir -> ok
        // file exsits and not dir -> ng
        // file not exsits -> ok
        let parentFolderLocation = dst.deletingLastPathComponent()
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


}

