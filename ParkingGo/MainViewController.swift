//
//  MainViewController.swift
//  ParkingGo
//
//  Created by 김학철 on 2021/03/02.
//
import UIKit
import WebKit
import WKCookieWebView
import FirebaseMessaging
import Toast_Swift
import KafkaRefresh

class MainViewController: UIViewController, WKScriptMessageHandler {
    
    var webView: WKCookieWebView!
    var popupWebView: WKWebView?
    var serverUrl:String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(notificationHandler(_ :)), name: Notification.Name(Constants.notiName.pushData), object: nil)
        
        self.setupWebView()
        if let cookieDictionary = UserDefaults.standard.object(forKey: Constants.dfsKey.cookies) as? [String:Any], cookieDictionary.isEmpty == false {
            serverUrl = Constants.url.loginCheck

            self.restoreCookies()
            let cookies = cookieDictionary
                .compactMap({ $0.value as? [HTTPCookiePropertyKey: Any] })
                .compactMap({ HTTPCookie(properties: $0) })

            let cookie = cookies.first;
            var req = URLRequest.init(url: URL(string: serverUrl)!)

            req.httpMethod = "POST"
            if let value = cookie?.value {
                let params:[String:String] = ["UserInfo":value]
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
                    req.httpBody = jsonData
                } catch {
                }
            }
            if let name = cookie?.name, let value = cookie?.value {
                req.setValue("\(name)=\(value);", forHTTPHeaderField: "Cookie")
            }

            self.webView.load(req)
        }
        else {
//            guard let fileUrl = Bundle.main.path(forResource: "test", ofType: "html") else {
//                return
//            }
//            let htmlStr = try! String(contentsOfFile: fileUrl, encoding: .utf8)
//            webView.loadHTMLString(htmlStr, baseURL: Bundle.main.bundleURL)
            
            serverUrl = Constants.url.login
            let req = URLRequest.init(url: URL(string: serverUrl)!)
            self.webView.load(req)
        }
        let headBlock = {
            self.webView.reload()
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.0) {
                self.webView.scrollView.headRefreshControl.endRefreshing()
            }
        }
        webView.scrollView.bindHeadRefreshHandler(headBlock, themeColor: RGB(245, 210, 70), refreshStyle: KafkaRefreshStyle.replicatorWoody)
    }
    
    private func setupWebView() {
        webView = WKCookieWebView.init(frame: self.view.bounds, configurationBlock: { [weak self] (config) in
            let pref = WKPreferences()
            pref.javaScriptEnabled = true
            pref.javaScriptCanOpenWindowsAutomatically = true
            
            let controller = WKUserContentController()
            controller.add(self!, name: "GetUserLoginInfo")
            controller.add(self!, name: "SetUserLoginInfo")
            controller.add(self!, name: "GetMobileInfo")
            
            config.allowsInlineMediaPlayback = true
            config.userContentController = controller
            config.preferences = pref
        })
        
        view.addSubview(webView)
            
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0).isActive = true;
        webView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: 0).isActive = true;
        webView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0).isActive = true;
        webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0).isActive = true;
        webView.allowsBackForwardNavigationGestures = true
        
        webView.evaluateJavaScript("navigator.userAgent") { [weak webView] (result, error) in
            if let webView = webView, let userAgent = result as? String {
                webView.customUserAgent = userAgent + "/ParkingGo/ios"
            }
        }
        
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.onUpdateCookieStorage = { [weak self] (webView) in
            self?.printCookie()
            self?.storeCookies()
        }
    }
    
    
    @objc private func printCookie  () {
        guard let url = webView.url else {
            return
        }
        
        print("=====================Cookies=====================")
        HTTPCookieStorage.shared.cookies(for: url)?.forEach({ (cookie) in
            print(cookie)
        })
    }
  
    func storeCookies() {
        guard let serverBaseUrl = URL(string: serverUrl) else {
            return
        }
        let cookiesStorage: HTTPCookieStorage = .shared
        var cookieDict: [String: Any] = [:]
        cookiesStorage.cookies(for: serverBaseUrl)?.forEach({ cookieDict[$0.name] = $0.properties })
        
        let userDefaults = UserDefaults.standard
        userDefaults.set(cookieDict, forKey: Constants.dfsKey.cookies)
    }
    func restoreCookies() {
        let cookiesStorage: HTTPCookieStorage = .shared
        let userDefaults = UserDefaults.standard
        guard let cookieDictionary = userDefaults.dictionary(forKey: Constants.dfsKey.cookies) else {
            return
        }
        
        let cookies = cookieDictionary
            .compactMap({ $0.value as? [HTTPCookiePropertyKey: Any] })
            .compactMap({ HTTPCookie(properties: $0) })
        
        cookiesStorage.setCookies(cookies, for: URL(string: serverUrl), mainDocumentURL: nil)
    }
    func removeCookies() {
        UserDefaults.standard.removeObject(forKey: Constants.dfsKey.cookies)
        UserDefaults.standard.synchronize()
        guard let serverBaseUrl = URL(string: serverUrl) else {
            return
        }
        HTTPCookieStorage.shared.cookies(for: serverBaseUrl)?.forEach({ (cookie) in
            HTTPCookieStorage.shared.deleteCookie(cookie)
        })
    }
  
    func getCreateWebScript() -> String {
        let js = "var originalWindowClose=window.close;window.close=function(){var iframe=document.createElement('IFRAME');iframe.setAttribute('src','back://'),document.documentElement.appendChild(iframe);originalWindowClose.call(window)};"
        return js
    }
    
    //MARK:: notificationHandler
    @objc func notificationHandler(_ notification:NSNotification) {
        if notification.name.rawValue == Constants.notiName.pushData {
            self.serverUrl = Constants.url.pushRedirect
            var req = URLRequest(url: URL(string: serverUrl)!)
            req.httpMethod = "POST"
            if let jsonDic = notification.object as? [String:Any] {
                let params = ["PushMessage": jsonDic]
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
                    req.httpBody = jsonData
                } catch {
                    
                }
            }
            webView.load(req)
        }
    }
    //MARK:: WKScriptMessageHandler
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
//        let msg = "Recive native app action \nname: \(message.name),\ndata:\((message.body as? String) ?? "")"
//        self.view.makeToast(msg)
        
        if (message.name == "GetUserLoginInfo") {
            guard let userInfo = UserDefaults.standard.object(forKey: Constants.dfsKey.userInfo) else {
                return
            }
            let jsFunc = "javascript:ReceiveUserLoginInfo(\(userInfo));"
            self.webView.evaluateJavaScript(jsFunc) { (result, error) in
                let msg = "native app javascript func call.\n funcname: \(jsFunc)\n\ncallback:\(result ?? ""), error:\(String(describing: error))"
                print(msg)
            }
        }
        else if (message.name == "GetMobileInfo") {
            print("GetMobileInfo")

            guard let mobileKey = Messaging.messaging().fcmToken else {
                return
            }
            let phoneNum = ""
            let jsFunc = "javascript:ReceiveMobileInfo('\(mobileKey)', '\(phoneNum)')"
            self.webView.evaluateJavaScript(jsFunc) { (result, error) in
                let msg = "native app javascript func call.\n funcname: \(jsFunc)\n\ncallback:\(result ?? ""), error:\(String(describing: error))"
                print(msg)
            }
        }
        else if (message.name == "SetUserLoginInfo") {
            guard let usrinfo = message.body as? String else {
                return
            }
            UserDefaults.standard.setValue(usrinfo, forKey: Constants.dfsKey.userInfo)
            UserDefaults.standard.synchronize()
        }
    }
}

extension MainViewController:  WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(WKNavigationActionPolicy.allow)
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        decisionHandler(WKNavigationActionPolicy.allow, preferences)
        print("== navigationAction \(navigationAction.request)")
        guard let url = webView.url?.absoluteString else {
            return
        }
        if url.contains("Logon") {
            
        }
//        AppDelegate.instance.startIndicator()
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(WKNavigationResponsePolicy.allow)
        print("== navigationResponse \(navigationResponse.response)")
    }
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        //start indicator
        print("== didStartProvisionalNavigation: \(String(describing: webView.url?.absoluteString))")
    }
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        print("== redirecturl: \(String(describing: webView.url?.absoluteString))")
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("== didFailProvisionalNavigation: \(String(describing: webView.url?.absoluteString))")
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print("didcommit : \(String(describing: webView.url?.absoluteString))")
        guard let url = webView.url?.absoluteString else {
            return
        }
        if url.contains("LogOff") == true
            || url.contains("LogOut") == true {
            self.removeCookies()
            self.serverUrl = Constants.url.login
            webView.load(URLRequest(url: URL(string: serverUrl)!))
        }
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("== didFinish: \(String(describing: webView.url?.absoluteString))")
//        AppDelegate.instance.stopIndicator()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("== didFail: \(String(describing: webView.url?.absoluteString))")
//        AppDelegate.instance.stopIndicator()
    }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        print("== webViewWebContentProcessDidTerminate: \(String(describing: webView.url?.absoluteString))")
//        AppDelegate.instance.stopIndicator()
    }
    
}
    
extension MainViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        
        let userCtrl = WKUserContentController()

        let userScript = WKUserScript(source: getCreateWebScript(), injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        userCtrl.addUserScript(userScript)
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.userContentController = userCtrl
    
        popupWebView = WKWebView(frame: self.view.bounds, configuration: configuration)
        popupWebView?.allowsBackForwardNavigationGestures = true
        popupWebView?.navigationDelegate = self
        popupWebView?.uiDelegate = self
        
        self.view.addSubview(popupWebView!)
        
        return popupWebView!
    }
    func webViewDidClose(_ webView: WKWebView) {
        if let popupWebView = popupWebView, popupWebView.isEqual(webView){
            popupWebView.removeFromSuperview()
            self.popupWebView = nil
        }
    }
    
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        
        let alet = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alet.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            completionHandler()
        }))
        self.present(alet, animated: true, completion: nil)
    }
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        
        let alet = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alet.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            completionHandler(true)
        }))
        alet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            completionHandler(false)
        }))
        self.present(alet, animated: true, completion: nil)
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        
        let alet = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        alet.addTextField { (textField) in
        }
        alet.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            guard let tf = alet.textFields?.first else {
                return
            }
            completionHandler(tf.text)
        }))
        alet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            completionHandler(nil)
        }))
        self.present(alet, animated: true, completion: nil)
    }
}

