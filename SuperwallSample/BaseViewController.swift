//
//  BaseViewController.swift
//  SuperwallSample
//
//  Created by Simon Chang on 2023/7/25.
//

import UIKit
import Alamofire

class BaseViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    // MARK: - View Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate
        NotificationCenter.default.addObserver(self, selector: #selector(receiveAction(_:)), name: NSNotification.Name("action"), object: sceneDelegate?.token)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Action
    @objc func receiveAction(_ notification: Notification) {
        let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate
        if sceneDelegate?.action != nil {
            doAction(sceneDelegate!.action!)
        }
    }
    
    // call 自家伺服器 API 綁定API
    func doAction(_ passAction: String) {
        let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate
        sceneDelegate?.action = nil
        if passAction == "binding" {
            let defaults = UserDefaults.standard
            let userID = defaults.string(forKey: "account")
            let token = sceneDelegate?.token
            sceneDelegate?.token = nil
            
            if userID == nil {
                showAlert("Error", "Please login first")
                return
            }

            if token == nil {
                showAlert("Error", "No token")
                return
            }

            print("doaction binding")
            // get value of custom property from Info.plist
            let infoDict = Bundle.main.infoDictionary
            let serverUrl = infoDict?["serverUrl"] as? String
            let url = "\(serverUrl!)/channel/app/api/bind"
            let parameters = ["token": token!, "userID": userID!]
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
                                    self.showAlert("Success", "綁定成功")
                                } else {
                                    if let message = json["message"] as? String {
                                        self.showAlert("Error", message)
                                    }else{
                                        self.showAlert("Error", "綁定失敗")
                                    }
                                }
                            }else if let message = json["message"] as? String {
                                self.showAlert("Error", message)
                            }else {
                                self.showAlert("Error", "綁定失敗")
                            }
                        } else {
                            self.showAlert("Error", "綁定失敗")
                        }
                    } catch {
                        self.showAlert("Error", "綁定失敗")
                    }
                case .failure(let error):
                    print(error)
                    self.showLoading(false)
                    self.showAlert("Error", "綁定失敗")
                }
            }
        }
    }
    
    // MARK: - Alert
    
    func showAlert(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okBtn = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okBtn)
        self.present(alert, animated: true)
    }

    // MARK: - Loading
    @objc var activityIndicator:UIActivityIndicatorView?
    @objc func showLoading(_ isShow:Bool = true){
        if isShow && activityIndicator == nil{
            activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
            activityIndicator?.isOpaque = false
            activityIndicator?.center = self.view.center
            activityIndicator?.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
            activityIndicator?.style = UIActivityIndicatorView.Style.medium
            activityIndicator?.color = UIColor.white
            self.view.addSubview(activityIndicator!)
            activityIndicator?.startAnimating()
        }else{
            if activityIndicator != nil{
                activityIndicator?.stopAnimating()
                activityIndicator?.removeFromSuperview()
                activityIndicator = nil
            }
        }
    }

}
