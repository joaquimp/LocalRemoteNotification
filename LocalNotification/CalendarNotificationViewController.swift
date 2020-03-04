//
//  ViewController.swift
//  LocalNotification
//
//  Created by Joaquim Pessoa Filho on 16/11/16.
//  Copyright © 2016 br.mackenzie.MackMobile. All rights reserved.
//

import UIKit
import UserNotifications

class CalendarNotificationViewController: UIViewController, UNUserNotificationCenterDelegate {

    @IBOutlet weak var timeIntervalTextField: UITextField!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var enableActionsButton: UISwitch!
    @IBOutlet weak var showBadgeButton: UISwitch!
    @IBOutlet weak var logTextView: UITextView!
    @IBOutlet weak var enableCustaomSoundButton: UISwitch!
    @IBOutlet weak var registryNotificationButton: UIButton!
    @IBOutlet weak var showVideoButton: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.logTextView.text = ""
        self.configureNotificationsCategories()
        
        UNUserNotificationCenter.current().delegate = self
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.requestNotificationAuthorization()
    }
    
    
    func configureNotificationsCategories() {
        let ignoreAction = UNNotificationAction(identifier: "ignoreAction", title: "Ignore", options: .destructive)
        
        let unlockAction = UNNotificationAction(identifier: "unlockAction", title: "Need unlock", options: .authenticationRequired)
        
        let foregroundAction = UNNotificationAction(identifier: "foregroundAction", title: "Foreground", options: .foreground)
        
        let category = UNNotificationCategory(identifier: "defaultCategory", actions: [], intentIdentifiers: [], options: [])
        let categoryWithActions = UNNotificationCategory(identifier: "notificationWithActions", actions: [ignoreAction, unlockAction, foregroundAction], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category, categoryWithActions])
    }
    
    func requestNotificationAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            
            DispatchQueue.main.async {
                if !granted {
                    self.logTextView.text = "Notification access denied\n"
                    self.logTextView.insertText("Go to Settings > Notifications > LocalNotification app and enable notification\n")
                    self.logTextView.insertText("After that close the app and open again ;)\n")
                    self.registryNotificationButton.isEnabled = false
                } else {
                    self.logTextView.text = "Allowed access to notifications\n"
                }
            }
        }
    }
    
    
    @IBAction func hideKeyboard(_ sender: UISwitch? = nil) {
        self.timeIntervalTextField.resignFirstResponder()
        self.messageTextField.resignFirstResponder()
    }
    
    @IBAction func clearButton(_ sender: Any) {
        self.logTextView.text = ""
    }
    

    @IBAction func registryNotificationAction(_ sender: Any) {
        
        self.hideKeyboard()
        
        // Remove Badge
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        // Setp 1
        
        let content = UNMutableNotificationContent()
        content.title = "Simple Local Notification"
        content.body = self.messageTextField.text ?? "A message to inform that this notification has no message"
        content.sound = UNNotificationSound.default
        content.badge = self.showBadgeButton.isOn ? 5 : nil
        
        if enableCustaomSoundButton.isOn {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "ring.m4r"))
        }
        
        if enableActionsButton.isOn {
            content.categoryIdentifier = "notificationWithActions"
        } else {
            content.categoryIdentifier = "defaultCategory"
        }
        
        var attachments:[UNNotificationAttachment] = []
        
        if showVideoButton.isOn {
            if let path = Bundle.main.path(forResource: "video", ofType: "mp4") {
                let url = URL(fileURLWithPath: path)
                do {
                    let aux = try UNNotificationAttachment(identifier: "video", url: url, options: nil)
                    attachments.append(aux)
                } catch {
                    print("Attachment problem (video)")
                }
            }
        }
        
        if let path = Bundle.main.path(forResource: "image", ofType: "png") {
            let url = URL(fileURLWithPath: path)
            do {
                let aux = try UNNotificationAttachment(identifier: "image", url: url, options: nil)
                attachments.append(aux)
            } catch {
                print("Attachment problem (image)")
            }
        }
        
        content.attachments = attachments
        
        
        // Setp 2
        let seconds = Double(self.timeIntervalTextField.text ?? "60") ?? 60
        let date = Date().addingTimeInterval(seconds)
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: .current, from: date)
        let newComponents = DateComponents(calendar: calendar, timeZone: .current, day: components.day, hour: components.hour, minute: components.minute, second: components.second)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: newComponents, repeats: false)
        
        // Step 3
        let request = UNNotificationRequest(identifier: "SimpleTriggerNotification", content: content, trigger: trigger)
        
        // Step 4
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().add(request, withCompletionHandler: {
            (error) in
            
            if error != nil {
                let message = "Erro to add request"
                let alertController = UIAlertController(title: "Registry Notification", message: message, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                
                self.present(alertController, animated: true, completion: nil)
            } else {
                DispatchQueue.main.async {
                    self.logTextView.insertText("Notification registered to:\n\t\(date)\n")
                }
            }
        })
    }

    // MARK:- UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        DispatchQueue.main.async {
            switch response.actionIdentifier {
            case "ignoreAction":
                self.logTextView.insertText("User choose ignore Action\n")
            case "unlockAction":
                self.logTextView.insertText("User choose Unlock Action\n")
            case "foregroundAction":
                self.logTextView.insertText("User choose Foreground Action\n")
            default:
                self.logTextView.insertText("User choose Unknowed Action\n")
            }
        }
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        completionHandler(.sound)
        
        let content = notification.request.content
        
        DispatchQueue.main.async {
            self.logTextView.insertText("Notification received\n")
            self.logTextView.insertText("\tTitle: \(content.title)\n")
            self.logTextView.insertText("\tBody: \(content.body)\n")
            
            if let badge = content.badge {
                self.logTextView.insertText("\tBadge: \(badge)\n")
            }
            
            if let _ = content.sound {
                self.logTextView.insertText("\tSound: enable\n")
            }
            
            if content.attachments.count > 0 {
                self.logTextView.insertText("\tAttachments: there are \(content.attachments.count) elements")
            }
        }
    }
}
