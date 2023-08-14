//
//  WebViewController.swift
//  SuperwallSample
//
//  Created by Simon Chang on 2023/7/18.
//

import UIKit
import WebKit

class WebViewController: BaseViewController, WKUIDelegate, WKNavigationDelegate {
    var url: String?
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var closeBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self;
        webView.uiDelegate = self;
        closeBtn.addTarget(self, action: #selector(closeBtnAction), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if url != nil {
            let myURL = URL(string: url!)
            let myRequest = URLRequest(url: myURL!)
            webView.load(myRequest)
        }
    }

    @objc func closeBtnAction(sender: UIButton!) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // 實作 window.open 外開 default browser 的功能
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        return nil
    }
}
