import Cocoa
import FlutterMacOS
import window_manager_plus

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return NSApp.windows.filter({$0 is MainFlutterWindow || $0 is WindowManagerPlusFlutterWindow}).count == 1
  }
}
