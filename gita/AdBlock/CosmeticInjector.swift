import Foundation
import WebKit

enum CosmeticInjector {
  static func userScripts(url: String, tabHost: String) throws -> [WKUserScript] {
    let injections = try cosmeticInjections(url, tabHost, true)
    var scripts: [WKUserScript] = []

    if !injections.hideCss.isEmpty {
      let source = hideStyleScript(for: injections.hideCss)
      scripts.append(
        WKUserScript(
          source: source,
          injectionTime: .atDocumentStart,
          forMainFrameOnly: true
        )
      )
    }

    if !injections.scriptletsJs.isEmpty {
      scripts.append(
        WKUserScript(
          source: injections.scriptletsJs,
          injectionTime: .atDocumentStart,
          forMainFrameOnly: true
        )
      )
    }

    return scripts
  }

  static func injectIntoPage(_ injections: CosmeticInjections, in webView: WKWebView) {
    if !injections.hideCss.isEmpty {
      let source = hideStyleScript(for: injections.hideCss)
      webView.evaluateJavaScript(source, completionHandler: nil)
    }
    if !injections.scriptletsJs.isEmpty {
      webView.evaluateJavaScript(injections.scriptletsJs, completionHandler: nil)
    }
  }

  private static func hideStyleScript(for css: String) -> String {
    let escaped =
      css
      .replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "`", with: "\\`")
      .replacingOccurrences(of: "$", with: "\\$")
    return """
      (function(){
        var style = document.createElement('style');
        style.textContent = `\(escaped)`;
        (document.head || document.documentElement).appendChild(style);
      })();
      """
  }
}
