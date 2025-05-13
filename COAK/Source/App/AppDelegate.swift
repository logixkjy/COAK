//
//  AppDelegate.swift
//  COAK
//
//  Created by JooYoung Kim on 5/13/25.
//

import UIKit
import Firebase
import FirebaseMessaging
import FirebaseAuth
import UserNotifications
import FirebaseFirestore

// AppDelegate 역할을 하는 클래스
class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        // 푸시 알림 권한 요청
        UNUserNotificationCenter.current().delegate = self
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error)")
            } else {
                print("Notification permission granted: \(granted)")
            }
        }
        application.registerForRemoteNotifications()
        
        Messaging.messaging().delegate = self
        
        return true
    }

    
    // 푸시 알림 권한 요청
    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ Push notification permission granted.")
            } else {
                print("❌ Push notification permission denied.")
            }
        }
    }
    
    // APNs 토큰 수신
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
            Messaging.messaging().apnsToken = deviceToken
            print("APNs Token registered: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
        }
    
    func subscribeToAllTopic() {
        Messaging.messaging().subscribe(toTopic: "all") { error in
            if let error = error {
                print("Error subscribing to all topic: \(error.localizedDescription)")
            } else {
                print("Successfully subscribed to all topic")
            }
        }
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        print("FCM registration token: \(fcmToken)")
        
        // 전체 푸시 토픽 구독
        Messaging.messaging().subscribe(toTopic: "all") { error in
            if let error = error {
                print("Error subscribing to all topic: \(error.localizedDescription)")
            } else {
                print("Successfully subscribed to all topic")
            }
        }
        
        subscribeToAllTopic()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound, .badge])
    }
}
