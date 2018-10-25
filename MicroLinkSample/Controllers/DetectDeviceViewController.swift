//
//  DetectDeviceViewController.swift
//  MicroLinkSample
//


import UIKit
import CoreBluetooth

struct microLinkPeripheral {
    let p: CBPeripheral
    let deviceName: String
    let rssi: NSNumber?
}

class DetectDeviceViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    var fromInitialView: Bool = false
    // BLE
    var centralManager : CBCentralManager!
    var peripheral: CBPeripheral!
    var microLinkPeripherals: [microLinkPeripheral] = []
 
    var titleForReadings: String?
  
    var refreshCont: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    
    
    func setupUI() {
        self.tableView.tableFooterView = UIView()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        // Initialize central manager

        centralManager = CBCentralManager(delegate: self, queue: nil, options: nil)
        
        
        self.refreshCont = UIRefreshControl()
        self.refreshCont.addTarget(self, action: #selector(self.refresh(_:)), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(refreshCont)
    }
    
    override func viewDidAppear(_ animated: Bool) {
         scanPeripherals()
      //  proceedToMainScreen()
    }
    
    @objc func refresh(_ sender:AnyObject) {
        NSLog("Refreshing...")
        scanPeripherals()
        refreshCont.endRefreshing()
    }
    

    fileprivate func scanPeripherals() {
        tableView.reloadData()
        centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey:true])
    }
    
    fileprivate func getNoPeripheralsLabel() -> UILabel {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont(name: "Verdana", size: 15.0)
        label.text = "No devices found, swipe down to refresh."
        
        return label
    }
    

}

extension DetectDeviceViewController: UITableViewDelegate,UITableViewDataSource {
    
    // MARK: - Table view data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView.backgroundView = microLinkPeripherals.isEmpty ? getNoPeripheralsLabel() : nil
        return microLinkPeripherals.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! DeviceCustomCell
        
        guard indexPath.row < microLinkPeripherals.count else {
            cell.titleLabel.text = ""
            cell.detailLabel.text = ""
            cell.signalLabel.text = ""
            return cell
        }
        
        // Configure the cell...
        let peri = microLinkPeripherals[indexPath.row]
        cell.titleLabel?.text = peri.deviceName == "" ? "New microLink" : peri.deviceName
        
        
        cell.detailLabel?.text = peri.p.identifier.uuidString
        UserDefaults.standard.set(peri.p.identifier.uuidString, forKey: "peridUUID")
        if let rssi = peri.rssi, rssi.doubleValue < 0.0 {
            cell.signalLabel?.text = getSignalLevel(rssi)
        }
        else {
            cell.signalLabel?.text = ""
        }
        
        return cell
    }
    
    func getSignalLevel(_ rssi: NSNumber) -> String {
        
        if rssi.doubleValue > -50.0 {
            return "●●●●"
        }
        else if rssi.doubleValue > -60.0 {
            return "●●●○"
        }
        else if rssi.doubleValue > -70.0 {
            return "●●○○"
        }
        else if rssi.doubleValue > -80.0 {
            return "●○○○"
        }
        else {
            return "○○○○"
        }
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        fromInitialView = true
        guard indexPath.row != microLinkPeripherals.count else { return }
        
        centralManager?.stopScan()
        
        let peri = microLinkPeripherals[indexPath.row]
       
        peripheral = peri.p
        titleForReadings = peri.deviceName
        centralManager.connect(peripheral, options: nil)
        
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    
    fileprivate func showAlertWithText (_ header : String = "Warning", message : String) {
        let alert = UIAlertController(title: header, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
}

//MARK:- CBCentralManagerDelegate
extension DetectDeviceViewController: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            scanPeripherals()
        }
        else {
            showAlertWithText("Error", message: "Bluetooth not initialized")
        }
    }
    
    fileprivate func foundmicroLinkIndex(_ p: CBPeripheral) -> (Bool, Int) {
        guard microLinkPeripherals.count > 0 else { return (false, 0) }
        
        for i in 0..<microLinkPeripherals.count {
            if microLinkPeripherals[i].p == p {
                return (true, i)
            }
        }
        return (false, 0)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
      //  print("Discovered \(String(describing: peripheral.name)) at \(RSSI)")
        if (peripheral.name == "microLink") {
            appendOrReplacePeripheral(peripheral, deviceName: peripheral.name ?? "", rssi: RSSI)
        }
        
    }
    
    fileprivate func appendOrReplacePeripheral(_ peripheral: CBPeripheral, deviceName: String, rssi: NSNumber?) {
        let (found, index) = foundmicroLinkIndex(peripheral)
        let newmicroLinkPeripheral = microLinkPeripheral(p: peripheral, deviceName: deviceName, rssi: rssi)
        if !found {
            microLinkPeripherals.append(newmicroLinkPeripheral)
            tableView.reloadData()
        }
        else {
            let offset = tableView.contentOffset.y + tableView.contentInset.top
            guard offset >= 0.0 else { return } // do not reload table while it is refreshing
            microLinkPeripherals.replaceSubrange(index...index, with: [newmicroLinkPeripheral])
            tableView.reloadData()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // Set default protocol to 0
        if UserDefaults.standard.object(forKey: "ProtocolNumber") == nil {
            UserDefaults.standard.set(0, forKey: "ProtocolNumber")
        }
        self.peripheral = peripheral
        proceedToMainScreen()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        if let error = error {
            
            print("didDisconnectPeripheral error: \(error)")
        }
    

    }
    
    
    func proceedToMainScreen() {
        let mainVC = self.storyboard?.instantiateViewController(withIdentifier: "MainViewController") as! MainViewController
        mainVC.connectedPeripheral = self.peripheral
        self.navigationController?.pushViewController(mainVC, animated: true)
    }
    
    
}


