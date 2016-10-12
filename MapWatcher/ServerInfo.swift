//
//  ServerInfo.swift
//  MapWatcher
//
//  Created by Zoltán Majoros on 13/Sep/2015.
//  Copyright © 2016 Zoltán Majoros. All rights reserved.
//

import Foundation
import Alamofire
import UserNotifications
import UserNotificationsUI

/*
 ServerInfoDelegate:
 A protocol used to notify an entity (in our case, a ServerInforManager instance)
 that the requested server information is available.
 */
protocol ServerInfoDelegate
{
    func serverInfoReady()
}

/*
 ServerInfo:
 A class containing information about a single game server
 */
class ServerInfo
{
    let url: String
    var numberOfPlayers = 0
    var activeMap = ""
    var mapImageURL: String?
    let managerDelegate: ServerInfoDelegate
    
    init(url: String, delegate: ServerInfoDelegate)
    {
        self.url = url
        managerDelegate = delegate
    }

    func retrieveServerInfo()
    {
        Alamofire.request(url).validate().responseString
            { response in
                if let html:String = response.result.value
                {
                    let ojRegex = OJRegex()
                    self.activeMap = ojRegex.getMapName(from: html)
                    self.numberOfPlayers = Int(ojRegex.getNumberOfPlayers(html)) ?? 0
                    self.mapImageURL = ojRegex.getImageURL(html)
                    self.managerDelegate.serverInfoReady()
                }
        }
    }
}

// ------------------------------------------------------------------------------------

protocol ServerInfoManagerDelegate
{
    func serverInfoDidRefresh(_ serverInfo: ServerInfo)
    func watchedMapIsActive(_ map: String)
}

/*
 ServerInfoManager: this class handles the array of ServerInfos and the array
 of maps to watch, and notifies the delegate when one of the desired maps are
 active on the server that has the most active number of players.
 
 It stores the data persistently across sessions via User Defaults.
 */
class ServerInfoManager: ServerInfoDelegate
{
    private var _mapsToWatch: [String] = []
    private var _servers: [ServerInfo] = []
    var delegate: ViewController?
    
    struct LastMapNotification
    {
        var date: Date = Date(timeIntervalSinceNow: -2000)
        var map: String = ""
    }
    
    var lastMapNotification = LastMapNotification()
    
    var mapsToWatch: [String] // we use getter to make it read-only
    {
        get
        {
            return _mapsToWatch
        }
    }
    
    var servers: [ServerInfo]
    {
        get
        {
            return _servers
        }
    }
    
    init(delegate: ViewController)
    {
        self.delegate = delegate
        
        //print(UserDefaults.standard.dictionaryRepresentation())
        if let restoredMaps = UserDefaults.standard.object(forKey: "maps") as? [String]
        {
            _mapsToWatch = restoredMaps
        }
        
        if let serverURLs = UserDefaults.standard.object(forKey: "servers") as? Array<String>
        {
            for url in serverURLs
            {
                _servers.append(ServerInfo(url: url, delegate: self))
            }
        }
    }
    
    func saveServersToUserDefaults()
    {
        var serverURLs = Array<String>()
        for server in _servers
        {
            serverURLs.append(server.url)
        }
        
        UserDefaults.standard.setValue(serverURLs, forKey: "servers")
    }
    
    func addServer(url: String)
    {
        _servers.append(ServerInfo(url: url, delegate: self))
        _servers.last?.retrieveServerInfo()
        saveServersToUserDefaults()
    }
    
    func removeServer(index: Int)
    {
        _servers.remove(at: index)
        saveServersToUserDefaults()
    }
    
    func addMapToWatch(mapName: String)
    {
        if _mapsToWatch.contains(mapName) == false
        {
            _mapsToWatch.append(mapName)
        }
        UserDefaults.standard.setValue(_mapsToWatch, forKey: "maps")
    }
    
    func removeMap(index: Int)
    {
        _mapsToWatch.remove(at: index)
        UserDefaults.standard.setValue(_mapsToWatch, forKey: "maps")
    }
    
    var numberOfRefreshingServers = 0
    
    func queryServerInfo()
    {
        numberOfRefreshingServers = _servers.count
        
        for server in _servers
        {
            server.retrieveServerInfo()
        }
    }
    
    func serverInfoReady() // method conforming to ServerInfoDelegate
    {
        numberOfRefreshingServers -= 1;
        if(numberOfRefreshingServers <= 0) // when we have info about all servers, then...
        {
            numberOfRefreshingServers = 0
            
            var serverWithMostPlayers: ServerInfo?
            
            for server in _servers // ...choose the one with the most number of players, and...
            {
                if serverWithMostPlayers == nil
                {
                    serverWithMostPlayers = server
                }
                else
                {
                    if server.numberOfPlayers > (serverWithMostPlayers?.numberOfPlayers)!
                    {
                        serverWithMostPlayers = server
                    }
                }
            }
            
            if serverWithMostPlayers == nil
            {
                return
            }
            else
            {
                delegate?.serverInfoDidRefresh(serverWithMostPlayers!) // ...update GUI via ViewController
                
                if let map = serverWithMostPlayers?.activeMap
                {
                    if _mapsToWatch.contains(map)
                    {
                        if (Date().timeIntervalSince(lastMapNotification.date) < 900) || (lastMapNotification.map == map)
                        {
                            return
                        }
                        
                        let notification = UILocalNotification()
                        notification.alertTitle = "Favorite map is running"
                        notification.alertBody = map
                        
                        let now = Date()
                        print(now)
                        notification.fireDate = now.addingTimeInterval(2)
                        notification.soundName = UILocalNotificationDefaultSoundName
                        
                        UIApplication.shared.scheduleLocalNotification(notification)
                        
                        delegate?.watchedMapIsActive(map)
                        
                        lastMapNotification.date = now
                        lastMapNotification.map = map
                    }
                }
            }
        }
    }
}
