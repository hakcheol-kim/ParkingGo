//
//  AppDelegate.swift
//  ParkingGo
//
//  Created by 김학철 on 2021/03/02.
//

import UIKit
import Firebase
import FirebaseMessaging
import KafkaRefresh

@main

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var loadingView:UIView?
    
    static var instance: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        
        window = UIWindow.init(frame: UIScreen.main.bounds)
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        window!.rootViewController = storyboard.instantiateViewController(withIdentifier: "MainViewController")
        window!.makeKeyAndVisible()
        self.registApnsPushKey()
        KafkaRefreshDefaults.standard()?.headDefaultStyle = KafkaRefreshStyle.animatableRing
        
        return true
    }
    
    func registApnsPushKey() {
        Messaging.messaging().delegate = self
        self.registerForRemoteNoti()
    }
    func registerForRemoteNoti() {
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { (granted: Bool, error:Error?) in
            if error == nil {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        if deviceToken.count == 0 {
            return
        }
        print("==== apns token:\(deviceToken.hexString)")
        //파이어베이스에 푸쉬토큰 등록
        Messaging.messaging().apnsToken = deviceToken
    }
    
    // 앱이 백그라운드에있는 동안 알림 메시지를 받으면
    //이 콜백은 사용자가 애플리케이션을 시작하는 알림을 탭할 때까지 실행되지 않습니다.
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        Messaging.messaging().appDidReceiveMessage(userInfo)
    }
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("=== apn token regist failed")
    }
    
    func startIndicator() {
        DispatchQueue.main.async(execute: {
            if self.loadingView == nil {
                self.loadingView = UIView(frame: UIScreen.main.bounds)
            }
            self.window!.addSubview(self.loadingView!)
            self.loadingView?.tag = 100000
            self.loadingView?.startAnimation(raduis: 25.0)
            
            //혹시라라도 indicator 계속 돌고 있으면 강제로 제거 해준다. 10초후에
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+60) {
                if let loadingView = self.window?.viewWithTag(100000) {
                    loadingView.removeFromSuperview()
                }
            }
        })
    }
    
    func stopIndicator() {
        DispatchQueue.main.async(execute: {
            if self.loadingView != nil {
                self.loadingView!.stopAnimation()
                self.loadingView?.removeFromSuperview()
            }
        })
    }
    func remakePushData(_ userInfo:[String:Any]?) -> [String:Any]? {
        guard let userInfo = userInfo else {
            return nil
        }
//        ["MP_ID": 481598, "pushType": 정기차량, "HO": 1805, "gcm.message_id": 1615734663662635, "gcm.notification.message": 정기차량이 입차하였습니다. 확인하실려면 클릭하여 앱을 활성화하세요, "VehicleNo": 67다8250, "InTime": 14:42:20, "google.c.a.e": 1, "Message": 정기차량이 입차하였습니다. 확인하실려면 클릭하여 앱을 활성화하세요, "DONG": 116, "google.c.sender.id": 853625059658, "POSTMB_DEVICE_NAME": 서문입구1_LPR, "aps": {
//            alert =     {
//                title = "\Uc815\Uae30\Ucc28\Ub7c9\Uc774 \Uc785\Ucc28\Ud558\Uc600\Uc2b5\Ub2c8\Ub2e4.";
//            };
//            sound = default;
//        }, "InDay": 2020-12-30, "gcm.notification.alert": 경보발생, "ContentTitle": 정기차량이 입차하였습니다.]
        var data:[String:Any] = [:]
        let keys = ["pushType", "MP_ID", "POSTMB_DEVICE_NAME", "DONG", "HO", "InTime", "InDay", "VehicleNo", "ContentTitle", "Message"];
        for key in keys {
            if let value = userInfo[key] {
                data[key] = value
            }
        }
        
//        var pushData:[String:Any] = [:]
//        pushData["registration_ids"] = Messaging.messaging().fcmToken
//        pushData["data"] = data
//        pushData["priority"] = "high"
        
        return data
    }
    
    func getJsonData(_ data:[String:Any]) -> String? {
        do {
            let jsData = try JSONSerialization.data(withJSONObject: data, options: .sortedKeys)
            let json = String.init(data: jsData, encoding: .utf8)
            return json
        } catch {
            print("diction to json error")
            return nil
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    //앱이 켜진상태, Forground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        guard let userInfo = notification.request.content.userInfo as? [String:Any], let pushType = userInfo["pushType"] as? String else {
            return
        }
        
//        guard let data = remakePushData(userInfo) else {
//            return
//        }
        
//        let jsonString = self.getJsonData(userInfo)
        
        if let title = userInfo["ContentTitle"] as? String, let msg = userInfo["Message"] as? String {
            let alert = UIAlertController.init(title: title, message: msg, preferredStyle: .alert)
            alert.addAction(UIAlertAction.init(title: "Ok", style: .default, handler: { (action) in
                alert.dismiss(animated: true, completion: nil)
            }))
            AppDelegate.instance.window?.rootViewController?.present(alert, animated: true, completion: nil)
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.notiName.pushData), object:userInfo)
        }
    }
    
    //앱이 백그라운드 들어갔을때 푸쉬온것을 누르면 여기 탄다.
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        guard let userInfo = response.notification.request.content.userInfo as? [String:Any],
              let _ = userInfo["pushType"] as? String else {
            return
        }
//        guard let data = remakePushData(userInfo) else {
//            return
//        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.notiName.pushData), object: userInfo)
        }
    }
    
}
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard fcmToken != nil else {
            print("===== error: fcm token key not receive")
            return
        }
        print("fcm: \(fcmToken!)")
    }
}
