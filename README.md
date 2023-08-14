#  SuperWall iOS Sample App

## SuperWall 任務牆流程
1. app啟動時 Call 自家伺服器 API 取得任務牆網址 (參考ViewController.swift > getUrl())
2. 用webview開啟任務牆網址，Sample裡面使用WKWebView (參考WebViewController.swift)
3. WebViewController.swift 在web上一個 closeBtn，點擊後關閉任務牆 (參考WebViewController.swift > closeBtn , closeBtnAction())
4. webview 實作 window.open 外開 default browser 的功能 (參考WebViewController.swift > func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures))

## SuperWall 點數綁定流程
1. 開啟APP帶入綁定token (參考SceneDelegate.swift)
2. call 自家伺服器 API 綁定API (參考BaseViewController.swift > func doAction(_ passAction: String))