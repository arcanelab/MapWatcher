//
//  ViewController.swift
//  MapWatcher
//
//  Created by Zoltán Majoros on 30/Aug/2015.
//  Copyright © 2016 Zoltán Majoros. All rights reserved.
//

import UIKit
import AlamofireImage

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ServerInfoManagerDelegate
{
    @IBOutlet weak var currentMap: UILabel!
    @IBOutlet weak var currentPlayers: UILabel!
    @IBOutlet weak var mapImage: UIImageView!
    @IBOutlet weak var enableSwitch: UISwitch!
    @IBOutlet weak var tableOfMapsToWatch: UITableView!
    @IBOutlet weak var editingButtons: UIStackView!
    @IBOutlet weak var editCancelButton: UIButton!
    
    var serverInfoManager: ServerInfoManager?

    // conforming to ServerInfoManagerDelegate
    public func serverInfoDidRefresh(_ serverInfo: ServerInfo)
    {
//        print("^ \(Date().description) VC: serverInfoDidRefresh()")
        currentMap.text = serverInfo.activeMap
        currentPlayers.text = String(serverInfo.numberOfPlayers)
        
        if let url = serverInfo.mapImageURL
        {
            if let url = URL(string: url)
            {
                mapImage.af_setImage(withURL: url)
            }
        }
    }
    
    // conforming to ServerInfoManagerDelegate
    func watchedMapIsActive(_ map: String)
    {
        if UIApplication.shared.applicationState == UIApplicationState.active
        {
            let alert = UIAlertController(title: "Favorite map is running", message: map, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func addNewItemToTableView(_ sender: UIButton)
    {
        let alert = UIAlertController(title: "Enter name", message: nil, preferredStyle: .alert)
        alert.addTextField(configurationHandler: nil)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default)
        { _ in
            if let newItem = alert.textFields![0].text
            {
                if newItem.isEmpty == false
                {
                    if(sender.tag == 0) // The UIButtons are tagged: newMap = 0, newServer = 1
                    {
                        self.serverInfoManager?.addMapToWatch(mapName: newItem)
                    }
                    else
                    {
                        self.serverInfoManager?.addServer(url: newItem)
                    }
                    self.tableOfMapsToWatch.reloadData()
                }
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func enableToggle(_ sender: UISwitch)
    {
        if(enableSwitch.isOn)
        {
            serverInfoManager?.queryServerInfo()
        }
    }
    
    weak var timer: Timer?
    
    func timerToQueryServerInfo(timer: Timer)
    {
        if enableSwitch.isOn { serverInfoManager?.queryServerInfo() }
    }

    private func setShadow(view: UIView, color: UIColor = UIColor.gray, offset: Double = 2.0, opacity: Float = 0.5, radius: Float = 3.0)
    {
        let shadowView = UIView(frame: view.frame)
        
        shadowView.layer.shadowColor = color.cgColor
        shadowView.layer.shadowOffset = CGSize(width: offset, height: offset)
        shadowView.layer.shadowPath = UIBezierPath(roundedRect: shadowView.bounds, cornerRadius: CGFloat(radius)).cgPath
        shadowView.layer.shadowOpacity = opacity;
        shadowView.layer.shadowRadius = CGFloat(radius);
        shadowView.layer.masksToBounds = false;
        
        shadowView.backgroundColor = UIColor.black
        //        self.view.addSubview(shadowView)
        self.view.insertSubview(shadowView, at: 0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if(serverInfoManager == nil)
        {
            serverInfoManager = ServerInfoManager(delegate: self)
        }
        
        view.backgroundColor = UIColor.init(patternImage: UIImage(imageLiteralResourceName: "first_aid_kit"))
        tableOfMapsToWatch.backgroundColor = UIColor.init(patternImage: UIImage(imageLiteralResourceName: "debut_light"))
        /*
         tableOfMapsToWatch.layer.shadowColor = UIColor.gray.cgColor
         tableOfMapsToWatch.layer.shadowOffset = CGSize(width: 10.0, height: 10.0)
         tableOfMapsToWatch.layer.shadowOpacity = 0.33;
         tableOfMapsToWatch.layer.shadowRadius = 3.0;
         tableOfMapsToWatch.layer.masksToBounds = false;
         */
        tableOfMapsToWatch.delegate = self
        tableOfMapsToWatch.dataSource = self
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        editingButtons.isHidden = true
        
        setShadow(view: tableOfMapsToWatch)
        setShadow(view: mapImage, opacity: 1.0, radius: 5.0)
        
        timer = Timer.scheduledTimer(timeInterval: 150, target: self, selector: #selector(self.timerToQueryServerInfo), userInfo: nil, repeats: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        serverInfoManager?.queryServerInfo()
    }
    
// --- Delegate Methods for the table view ---
    
    @IBAction func editTableView(_ sender: UIButton)
    {
        if(tableOfMapsToWatch.isEditing)
        {
            tableOfMapsToWatch.setEditing(false, animated: true)
            editCancelButton.setTitle("Edit", for: UIControlState.normal)
            
            UIView.animate(withDuration: 0.3, animations: {self.editingButtons.alpha = 0.0}, completion: {finished in self.editingButtons.isHidden = true})
        }
        else
        {
            tableOfMapsToWatch.setEditing(true, animated: true)
            editCancelButton.setTitle("OK", for: UIControlState.normal)
            
            editingButtons.alpha = 0.0
            editingButtons.isHidden = false
            UIView.animate(withDuration: 0.3, animations: {self.editingButtons.alpha = 1.0}, completion: nil)
        }
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            switch indexPath.section
            {
                case 0: // maps
                    serverInfoManager?.removeMap(index: indexPath.row)
                case 1: // servers
                    serverInfoManager?.removeServer(index: indexPath.row)
                default:
                    break
            }
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.reloadData()
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        switch section
        {
        case 0:
            return serverInfoManager?.mapsToWatch.count ?? 0
        case 1:
            return serverInfoManager?.servers.count ?? 0
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        switch indexPath.section
        {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "MapNameCell", for: indexPath)
            cell.textLabel?.text = serverInfoManager?.mapsToWatch[indexPath.row]
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "URLCell", for: indexPath)
            cell.textLabel?.text = serverInfoManager?.servers[indexPath.row].url
            return cell
        default:
            return tableView.dequeueReusableCell(withIdentifier: "MapCell", for: indexPath)
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 43
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell")
        {
            cell.textLabel?.text = section == 0 ? "Maps" : "Servers"
            cell.backgroundColor = UIColor.init(patternImage: UIImage(imageLiteralResourceName: "debut_light"))
            return cell
        }
        else
        {
            return nil
        }
    }
}
