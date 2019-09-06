//
//  DemoViewController.swift
//  SwiftR
//
//  Created by Adam Hartford on 5/26/16.
//  Copyright © 2016 Adam Hartford. All rights reserved.
//

import UIKit
import SwiftR

class DemoViewController: UIViewController {
    
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var chatTextView: UITextView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var startButton: UIBarButtonItem!
    
    var chatHub: Hub!
    var connection: SignalR!
    var name: String!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        connection = SignalR("http://pixelserver-001-site29.ctempurl.com/signalr/hubs")
        connection.headers = ["Authorization": "Bearer h8EaM-xUeIzzK0YyWMmOkuzXAgoPajo777-7-AIGc4coANVUChRkHv7yq3H0djFBktInBulHeLOB3WXFfYe_ixynUDtHbw_86FGqRQTJ_0RKDUs9i48IyUXyBINFteHOJ_0T5YCAAJCciSzAMDwzDcu6HKeP51jJVW6wfT6WkXaBz7AUyKqtcPH2MhJtupxCC9qJk0HCgJzHAo3A97wY7aaWBzC4ap0TEthPEGYwdXjFA1fX6kdXPyQs71ZX0qvo98h4W4Y6xrpuV7eCbi8t5Imcy5oIbY-yH5meUkhpk8Xw8CATCe1EjpzzhA3X9i1ZrTrfAVfWl6F_O1FpPw-4IMXzvOjOsF0DacUMaLmwX_7KWyPGjpNXAk3CUPf2ADNmn0HncbW_-XBv_garP0CXSi1vBE7sfIZRgCKIsPfUhBE9_w8nTYa1tFYSpUk_6r95xDSis99bh_GrAUHrv9OeNChyy4pnmYeu_OcrtIjEWeXSdK0rOV1CvvMrkK4TtxRC9yJLAqzuWwBO5HEjaoez_Q-wMMsxwRWunoDn3kX8wTw"]

        connection.useWKWebView = false
        connection.signalRVersion = .v2_2_0

        chatHub = Hub("chatHub")
        chatHub.on("broadcastMessage") { [weak self] args in
            if let name = args?[0] as? String, let message = args?[1] as? String, let text = self?.chatTextView.text {
                self?.chatTextView.text = "\(text)\n\n\(name): \(message)"
            }
        }
        connection.addHub(chatHub)
        
        connection.starting = { [weak self] in
            print("starting....")

            self?.statusLabel.text = "Starting..."
            self?.startButton.isEnabled = false
            self?.sendButton.isEnabled = false
            do{
                let RoomId = 1
                try self?.chatHub.invoke("Join", arguments: [RoomId])

            } catch {
                print(error)

            }

            }
        
        
        connection.connected = { [weak self] in

            print("connected")
            
            print("Connection ID: \(self!.connection.connectionID!)")
            
            self?.statusLabel.text = "Connected"
            self?.startButton.isEnabled = true
            self?.startButton.title = "Stop"
            self?.sendButton.isEnabled = true
            
            do{
                let RoomId = 1
                try self?.chatHub.invoke("Join", arguments: [RoomId])
                
            } catch {
                print(error)
            }

            
            }
        
        
        

        
        connection.reconnecting = { [weak self] in
            self?.statusLabel.text = "Reconnecting..."
                        self?.startButton.isEnabled = false
                        self?.sendButton.isEnabled = false
        }
        
        connection.reconnected = { [weak self] in

            self?.startButton.isEnabled = true
            self?.startButton.title = "Stop"
            self?.sendButton.isEnabled = true

            do{
                let RoomId = 1
                try self?.chatHub.invoke("Join", arguments: [RoomId])
                
            } catch {
                print(error)

            }
            
            
            }
        


        connection.disconnected = { [weak self] in
            self?.statusLabel.text = "Disconnected"
            self?.startButton.isEnabled = true
            self?.startButton.title = "Start"
            self?.sendButton.isEnabled = false
        }

        connection.connectionSlow = { print("Connection slow...") }

        connection.error = { [weak self] error in
            print("Error: \(String(describing: error))")

            
            if let source = error?["source"] as? String, source == "TimeoutException" {
                print("Connection timed out. Restarting...")
                self?.connection.start()
            }
        }
        
        connection.start()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let alertController = UIAlertController(title: "Name", message: "Please enter your name", preferredStyle: .alert)

        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.name = alertController.textFields?.first?.text

            if let name = self?.name , name.isEmpty {
                self?.name = "Anonymous"
            }

            alertController.textFields?.first?.resignFirstResponder()
        }

        alertController.addTextField { textField in
            textField.placeholder = "Your Name"
        }

        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func send(_ sender: AnyObject?) {
        let RoomId = 1
        if let hub = chatHub, let message = messageTextField.text {
            do {
                try hub.invoke("send", arguments: [RoomId, message])
            } catch {
                print(error)
                
            }
        }
        messageTextField.resignFirstResponder()
    }
    
    @IBAction func startStop(_ sender: AnyObject?) {
        if startButton.title == "Start" {
            connection.start()
        } else {
            connection.stop()
        }
    }

}
