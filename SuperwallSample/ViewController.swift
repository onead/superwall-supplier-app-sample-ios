//
//  ViewController.swift
//  SuperwallSample
//
//  Created by Simon Chang on 2023/7/18.
//

import UIKit
import Alamofire

class ViewController: BaseViewController, UITextFieldDelegate {

    @IBOutlet weak var loginView: UIView!
    @IBOutlet weak var accountTxt: UITextField!
    @IBOutlet weak var passwordTxt: UITextField!
    @IBOutlet weak var siteSelect: UISegmentedControl!
    @IBOutlet weak var loginBtn: UIButton!
    
    @IBOutlet weak var insideView: UIView!
    @IBOutlet weak var missionBtn: UIButton!
    @IBOutlet weak var logoutBtn: UIButton!
    @IBOutlet weak var infoTxt: UILabel!
    var url: String?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let infoDict = Bundle.main.infoDictionary
        let site = infoDict?["site"] as? Int
        
        siteSelect.selectedSegmentIndex = site ?? 0

        accountTxt.delegate = self
        passwordTxt.delegate = self
        
        missionBtn.layer.cornerRadius = 10
        missionBtn.layer.masksToBounds = true
        
        logoutBtn.backgroundColor = .clear
        
        loginBtn.layer.cornerRadius = 10
        loginBtn.layer.masksToBounds = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(receiveRemoteNotification), name: NSNotification.Name("appReceiveRemoteNotification"), object: nil)
       
        let defaults = UserDefaults.standard
        if let _ = defaults.string(forKey: "account") {
            loginView.isHidden = true
            showInfo()
            self.askNotificationPermission()
        }else{
            insideView.isHidden = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // get scene delegate public variables
        let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate

        if let action = sceneDelegate?.action {
            doAction(action)
        }

        let defaults = UserDefaults.standard
        if let _ = defaults.string(forKey: "account") {
            getUrl()
        }
    }
    
    @IBAction func onMissionShow(_ sender: Any) {
        // present WKWebView with url
        if(url == nil) {
            showAlert("Error", "沒有取得網址")
            return
        }
        openWebView()
    }
    
    @IBAction func onLogin(_ sender: Any) {
        gotoLogin()
    }
    
    func gotoLogin() {
        accountTxt.resignFirstResponder()
        passwordTxt.resignFirstResponder()
        let account = accountTxt.text
        let password = passwordTxt.text
        
        if account == "" || password == "" {
            showAlert("警告", "請輸入帳號密碼")
            return
        }

        // 驗證 accountTxt 09 開頭 10碼 用正規表示法
        let accountRegex = "^[0][9]\\d{8}$"
        let accountPredicate = NSPredicate(format: "SELF MATCHES %@", accountRegex)
        if !accountPredicate.evaluate(with: account) {
            showAlert("警告", "請輸入正確的手機號碼")
            return
        }

        showLoading(true)
        // delay 1.5 sec
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.showLoading(false)
            self.saveAccount(account!)
            self.loginView.isHidden = true
            self.insideView.isHidden = false
            self.showInfo()
            self.askNotificationPermission()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.getUrl()
        }
    }
    
    func showInfo() {
        let defaults = UserDefaults.standard
        let gender:String = defaults.string(forKey: "gender") ?? ""
        let birthYear:Int = defaults.integer(forKey: "birthYear")
        let infoDict = Bundle.main.infoDictionary
        let site = infoDict?["currentSchemeName"] as? String ?? ""
        infoTxt.text = "\(site) : \(gender) / \(birthYear)"
    }
    
    @IBAction func onLogout(_ sender: Any) {
        let alert = UIAlertController(title: "訊息", message: "確定要登出？", preferredStyle: .alert)
        let okBtn = UIAlertAction(title: "確定", style: .default, handler: { (action: UIAlertAction!) -> Void in
            self.revokeNotification()
            self.loginView.isHidden = false
            self.insideView.isHidden = true
            let defaults = UserDefaults.standard
            defaults.removeObject(forKey: "account")
            defaults.removeObject(forKey: "gender")
            defaults.removeObject(forKey: "birthYear")
        })
        let cancelBtn = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alert.addAction(okBtn)
        alert.addAction(cancelBtn)
        self.present(alert, animated: true)
    }
    
    func saveAccount(_ account: String) {
        let defaults = UserDefaults.standard
        defaults.set(account, forKey: "account")

        // random generate string M or F
        let gender: String = ["M", "F"].randomElement()!
        defaults.set(gender, forKey: "gender")

        // random generate number 1950 ~ 2005
        let birthYear: Int = Int.random(in: 1950...2005)
        defaults.set(birthYear, forKey: "birthYear")
        
        switch siteSelect.selectedSegmentIndex {
        case 0:
            defaults.set("dev", forKey: "site")
        case 1:
            defaults.set("demo", forKey: "site")
        case 2:
            defaults.set("stage", forKey: "site")
        case 3:
            defaults.set("local", forKey: "site")
        default:
            print("no select site")
        }
    }

    // Call 自家伺服器 API 取得任務牆網址
    func getUrl() {
        print("getUrl")
        
        let defaults = UserDefaults.standard
        let memberID:String = defaults.string(forKey: "account") ?? ""
        let gender:String = defaults.string(forKey: "gender") ?? "" //一般狀況下不會由app取得性別，此為範例
        let birthYear:Int = defaults.integer(forKey: "birthYear")  //一般狀況下不會由app取得生日，此為範例
        let infoDict = Bundle.main.infoDictionary
        let serverUrl = infoDict?["serverUrl"] as? String
        let url = "\(serverUrl!)/channel/app/api/getUrl"
        let parameters = ["memberID": memberID, "gender": gender, "birthYear": birthYear] as [String : Any]
        showLoading(true)
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
        .responseData { response in
            switch response.result {
            case .success(let data):
                self.showLoading(false)
                do {
                    let json = try JSONSerialization.jsonObject(with: data)
                    if let json = json as? [String: Any] {
                        print(json)
                        if let ok = json["ok"] as? Bool {
                            if ok == true {
                                if let url = json["url"] as? String {
                                    self.url = url
                                } else {
                                    self.showAlert("Error", "取得任務網址失敗")
                                }
                            } else {
                                self.showAlert("Error", "取得任務網址失敗")
                            }
                        }else{
                            self.showAlert("Error", "取得任務網址失敗")
                        }
                    } else {
                        self.showAlert("Error", "取得任務網址失敗")
                    }
                } catch {
                    self.showAlert("Error", "取得任務網址失敗")
                }
            case .failure(let error):
                print(error)
                self.showLoading(false)
                self.showAlert("Error", "Get url failed")
            }
        }
    }
    
    // MARK: - push notification
    func askNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("D'oh: \(error.localizedDescription)")
            } else {
                print("permission request")
                DispatchQueue.main.async(execute: {
                    UIApplication.shared.registerForRemoteNotifications()
                })
            }
        }
    }
    
    @objc func receiveRemoteNotification() {
        let defaults = UserDefaults.standard
        let memberID:String = defaults.string(forKey: "account") ?? ""
        let pushToken:String = defaults.string(forKey: "pushToken") ?? ""
        let deviceID:String = UIDevice.current.identifierForVendor!.uuidString
        let infoDict = Bundle.main.infoDictionary
        let serverUrl = infoDict?["serverUrl"] as? String
        let url = "\(serverUrl!)/channel/app/api/registerNotification"
        let parameters = ["memberID": memberID, "deviceID": deviceID, "pushToken": pushToken, "os": "iOS"] as [String : Any]
        
        showLoading(true)
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
        .responseData { response in
            switch response.result {
            case .success(let data):
                self.showLoading(false)
                do {
                    let json = try JSONSerialization.jsonObject(with: data)
                    if let json = json as? [String: Any] {
                        if let ok = json["ok"] as? Bool {
                            if ok == true {
                                self.showAlert("Success", "註冊推播成功")
                            } else {
                                self.showAlert("Error", "註冊推播失敗")
                            }
                        }
                    } else {
                        self.showAlert("Error", "註冊推播失敗")
                    }
                } catch {
                    self.showAlert("Error", "註冊推播失敗")
                }
            case .failure(let error):
                print(error)
                self.showLoading(false)
                self.showAlert("Error", "註冊推播失敗")
            }
        }
    }
    
    func revokeNotification() {
        let defaults = UserDefaults.standard
        let deviceID:String = UIDevice.current.identifierForVendor!.uuidString
        let infoDict = Bundle.main.infoDictionary
        let serverUrl = infoDict?["serverUrl"] as? String
        let url = "\(serverUrl!)/channel/app/api/revokeNotification"
        let parameters = ["deviceID": deviceID, "os": "iOS"] as [String : Any]
        defaults.removeObject(forKey: "pushToken")
        
        showLoading(true)
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
        .responseData { response in
            switch response.result {
            case .success(let data):
                self.showLoading(false)
                do {
                    let json = try JSONSerialization.jsonObject(with: data)
                    if let json = json as? [String: Any] {
                        if let ok = json["ok"] as? Bool {
                            if ok == true {
                                self.showAlert("Success", "註銷推播成功")
                            } else {
                                self.showAlert("Error", "註銷推播失敗")
                            }
                        }
                    } else {
                        self.showAlert("Error", "註銷推播失敗")
                    }
                } catch {
                    self.showAlert("Error", "註銷推播失敗")
                }
            case .failure(let error):
                print(error)
                self.showLoading(false)
                self.showAlert("Error", "註銷推播失敗")
            }
        }
    }
    
    // MARK: - OpenWebView
    func openWebView() {
         self.performSegue(withIdentifier: "gotoWebView", sender: self)
    }
    
    // MARK: - Textfield
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.isEqual(accountTxt){
            passwordTxt.becomeFirstResponder()
        }else if textField.isEqual(passwordTxt){
            textField.resignFirstResponder()
            gotoLogin()
        }
        return true
    }
    
    // MARK: - Navigation

        // In a storyboard-based application, you will often want to do a little preparation before navigation
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "gotoWebView" {
                let destViewController = segue.destination as! WebViewController;
                destViewController.url = url
            }
        }
}

