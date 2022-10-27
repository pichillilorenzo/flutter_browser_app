import 'package:flutter/material.dart';
import 'package:flutter_browser/models/browser_model.dart';
import 'package:flutter_browser/models/webview_model.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

class AndroidSettings extends StatefulWidget {
  const AndroidSettings({Key? key}) : super(key: key);

  @override
  State<AndroidSettings> createState() => _AndroidSettingsState();
}

class _AndroidSettingsState extends State<AndroidSettings> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: _buildAndroidWebViewTabSettings(),
    );
  }

  List<Widget> _buildAndroidWebViewTabSettings() {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    if (browserModel.webViewTabs.isEmpty) {
      return [];
    }
    var currentWebViewModel = Provider.of<WebViewModel>(context, listen: true);
    var webViewController = currentWebViewModel.webViewController;

    var widgets = <Widget>[
      const ListTile(
        title: Text("Current WebView Android Settings"),
        enabled: false,
      ),
      ListTile(
        title: const Text("Text Zoom"),
        subtitle: const Text("Sets the text zoom of the page in percent."),
        trailing: SizedBox(
          width: 50.0,
          child: TextFormField(
            initialValue: currentWebViewModel.settings?.textZoom.toString(),
            keyboardType: const TextInputType.numberWithOptions(),
            onFieldSubmitted: (value) async {
              currentWebViewModel.settings?.textZoom = int.parse(value);
              webViewController?.setSettings(
                  settings:
                      currentWebViewModel.settings ?? InAppWebViewSettings());
              currentWebViewModel.settings =
                  await webViewController?.getSettings();
              browserModel.save();
              setState(() {});
            },
          ),
        ),
      ),
      SwitchListTile(
        title: const Text("Clear Session Cache"),
        subtitle: const Text(
            "Sets whether the WebView should have the session cookie cache cleared before the new window is opened."),
        value: currentWebViewModel.settings?.clearSessionCache ?? false,
        onChanged: (value) async {
          currentWebViewModel.settings?.clearSessionCache = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          currentWebViewModel.settings = await webViewController?.getSettings();
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Built In Zoom Controls"),
        subtitle: const Text(
            "Sets whether the WebView should use its built-in zoom mechanisms."),
        value: currentWebViewModel.settings?.builtInZoomControls ?? false,
        onChanged: (value) async {
          currentWebViewModel.settings?.builtInZoomControls = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          currentWebViewModel.settings = await webViewController?.getSettings();
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Display Zoom Controls"),
        subtitle: const Text(
            "Sets whether the WebView should display on-screen zoom controls when using the built-in zoom mechanisms."),
        value: currentWebViewModel.settings?.displayZoomControls ?? false,
        onChanged: (value) async {
          currentWebViewModel.settings?.displayZoomControls = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          currentWebViewModel.settings = await webViewController?.getSettings();
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Database storage API"),
        subtitle: const Text(
            "Sets whether the Database storage API should be enabled."),
        value: currentWebViewModel.settings?.databaseEnabled ?? true,
        onChanged: (value) async {
          currentWebViewModel.settings?.databaseEnabled = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          currentWebViewModel.settings = await webViewController?.getSettings();
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("DOM storage API"),
        subtitle:
            const Text("Sets whether the DOM storage API should be enabled."),
        value: currentWebViewModel.settings?.domStorageEnabled ?? true,
        onChanged: (value) {
          setState(() {
            currentWebViewModel.settings?.domStorageEnabled = value;
            webViewController?.setSettings(
                settings:
                    currentWebViewModel.settings ?? InAppWebViewSettings());
            browserModel.save();
          });
        },
      ),
      SwitchListTile(
        title: const Text("Use Wide View Port"),
        subtitle: const Text(
            "Sets whether the WebView should enable support for the \"viewport\" HTML meta tag or should use a wide viewport."),
        value: currentWebViewModel.settings?.useWideViewPort ?? true,
        onChanged: (value) async {
          currentWebViewModel.settings?.useWideViewPort = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          currentWebViewModel.settings = await webViewController?.getSettings();
          browserModel.save();
          setState(() {});
        },
      ),
      const ListTile(
        title: Text("Mixed Content Mode"),
        subtitle: Text(
            "Configures the WebView's behavior when a secure origin attempts to load a resource from an insecure origin."),
      ),
      Container(
        padding: const EdgeInsets.only(
            left: 20.0, top: 0.0, right: 20.0, bottom: 10.0),
        alignment: Alignment.center,
        child: DropdownButton<MixedContentMode>(
          hint: const Text("Mixed Content Mode"),
          onChanged: (value) async {
            currentWebViewModel.settings?.mixedContentMode = value;
            webViewController?.setSettings(
                settings:
                    currentWebViewModel.settings ?? InAppWebViewSettings());
            currentWebViewModel.settings =
                await webViewController?.getSettings();
            browserModel.save();
            setState(() {});
          },
          value: currentWebViewModel.settings?.mixedContentMode,
          items: MixedContentMode.values.map((mixedContentMode) {
            return DropdownMenuItem<MixedContentMode>(
              value: mixedContentMode,
              child: Text(
                mixedContentMode.toString(),
                style: const TextStyle(fontSize: 12.5),
              ),
            );
          }).toList(),
        ),
      ),
      SwitchListTile(
        title: const Text("Allow Content Access"),
        subtitle: const Text(
            "Enables or disables content URL access within WebView. Content URL access allows WebView to load content from a content provider installed in the system."),
        value: currentWebViewModel.settings?.allowContentAccess ?? true,
        onChanged: (value) async {
          currentWebViewModel.settings?.allowContentAccess = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          currentWebViewModel.settings = await webViewController?.getSettings();
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Allow File Access"),
        subtitle: const Text(
            "Enables or disables file access within WebView. Note that this enables or disables file system access only."),
        value: currentWebViewModel.settings?.allowFileAccess ?? true,
        onChanged: (value) async {
          currentWebViewModel.settings?.allowFileAccess = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          currentWebViewModel.settings = await webViewController?.getSettings();
          browserModel.save();
          setState(() {});
        },
      ),
      const ListTile(
        title: Text("App Cache Path"),
        subtitle: Text(
            "Sets the path to the Application Caches files. In order for the Application Caches API to be enabled, this option must be set a path to which the application can write."),
      ),
      Container(
        padding: const EdgeInsets.only(
            left: 20.0, top: 0.0, right: 20.0, bottom: 20.0),
        alignment: Alignment.center,
        child: TextFormField(
          initialValue: currentWebViewModel.settings?.appCachePath,
          keyboardType: TextInputType.text,
          onFieldSubmitted: (value) async {
            currentWebViewModel.settings?.appCachePath = value.trim();
            webViewController?.setSettings(
                settings:
                    currentWebViewModel.settings ?? InAppWebViewSettings());
            currentWebViewModel.settings =
                await webViewController?.getSettings();
            browserModel.save();
            setState(() {});
          },
        ),
      ),
      SwitchListTile(
        title: const Text("Block Network Image"),
        subtitle: const Text(
            "Sets whether the WebView should not load image resources from the network (resources accessed via http and https URI schemes)."),
        value: currentWebViewModel.settings?.blockNetworkImage ?? false,
        onChanged: (value) async {
          currentWebViewModel.settings?.blockNetworkImage = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          currentWebViewModel.settings = await webViewController?.getSettings();
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Block Network Loads"),
        subtitle: const Text(
            "Sets whether the WebView should not load resources from the network."),
        value: currentWebViewModel.settings?.blockNetworkLoads ?? false,
        onChanged: (value) async {
          currentWebViewModel.settings?.blockNetworkLoads = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          currentWebViewModel.settings = await webViewController?.getSettings();
          browserModel.save();
          setState(() {});
        },
      ),
      const ListTile(
        title: Text("Cache Mode"),
        subtitle: Text(
            "Overrides the way the cache is used. The way the cache is used is based on the navigation type."),
      ),
      Container(
        padding: const EdgeInsets.only(
            left: 20.0, top: 0.0, right: 20.0, bottom: 10.0),
        alignment: Alignment.center,
        child: DropdownButton<CacheMode>(
          hint: const Text("Cache Mode"),
          onChanged: (value) async {
            currentWebViewModel.settings?.cacheMode = value;
            webViewController?.setSettings(
                settings:
                    currentWebViewModel.settings ?? InAppWebViewSettings());
            currentWebViewModel.settings =
                await webViewController?.getSettings();
            browserModel.save();
            setState(() {});
          },
          value: currentWebViewModel.settings?.cacheMode,
          items: CacheMode.values.map((cacheMode) {
            return DropdownMenuItem<CacheMode>(
              value: cacheMode,
              child: Text(
                cacheMode.toString(),
                style: const TextStyle(fontSize: 12.5),
              ),
            );
          }).toList(),
        ),
      ),
      ListTile(
        title: const Text("Cursive Font Family"),
        subtitle: const Text("Sets the cursive font family name."),
        trailing: SizedBox(
          width: MediaQuery.of(context).size.width / 3,
          child: TextFormField(
            initialValue: currentWebViewModel.settings?.cursiveFontFamily,
            keyboardType: TextInputType.text,
            onFieldSubmitted: (value) async {
              currentWebViewModel.settings?.cursiveFontFamily = value;
              webViewController?.setSettings(
                  settings:
                      currentWebViewModel.settings ?? InAppWebViewSettings());
              currentWebViewModel.settings =
                  await webViewController?.getSettings();
              browserModel.save();
              setState(() {});
            },
          ),
        ),
      ),
      ListTile(
        title: const Text("Default Fixed Font Size"),
        subtitle: const Text("Sets the default fixed font size."),
        trailing: SizedBox(
          width: 50,
          child: TextFormField(
            initialValue:
                currentWebViewModel.settings?.defaultFixedFontSize.toString(),
            keyboardType: const TextInputType.numberWithOptions(),
            onFieldSubmitted: (value) async {
              currentWebViewModel.settings?.defaultFixedFontSize =
                  int.parse(value);
              webViewController?.setSettings(
                  settings:
                      currentWebViewModel.settings ?? InAppWebViewSettings());
              currentWebViewModel.settings =
                  await webViewController?.getSettings();
              browserModel.save();
              setState(() {});
            },
          ),
        ),
      ),
      ListTile(
        title: const Text("Default Font Size"),
        subtitle: const Text("Sets the default font size."),
        trailing: SizedBox(
          width: 50.0,
          child: TextFormField(
            initialValue:
                currentWebViewModel.settings?.defaultFontSize.toString(),
            keyboardType: const TextInputType.numberWithOptions(),
            onFieldSubmitted: (value) async {
              currentWebViewModel.settings?.defaultFontSize = int.parse(value);
              webViewController?.setSettings(
                  settings:
                      currentWebViewModel.settings ?? InAppWebViewSettings());
              currentWebViewModel.settings =
                  await webViewController?.getSettings();
              browserModel.save();
              setState(() {});
            },
          ),
        ),
      ),
      ListTile(
        title: const Text("Default Text Encoding Name"),
        subtitle: const Text(
            "Sets the default text encoding name to use when decoding html pages."),
        trailing: SizedBox(
          width: MediaQuery.of(context).size.width / 3,
          child: TextFormField(
            initialValue: currentWebViewModel.settings?.defaultTextEncodingName,
            keyboardType: TextInputType.text,
            onFieldSubmitted: (value) async {
              currentWebViewModel.settings?.defaultTextEncodingName = value;
              webViewController?.setSettings(
                  settings:
                      currentWebViewModel.settings ?? InAppWebViewSettings());
              currentWebViewModel.settings =
                  await webViewController?.getSettings();
              browserModel.save();
              setState(() {});
            },
          ),
        ),
      ),
      const ListTile(
        title: Text("Disabled Action Mode Menu Items"),
        subtitle: Text(
            "Disables the action mode menu items according to menuItems flag."),
      ),
      Container(
        padding: const EdgeInsets.only(
            left: 20.0, top: 0.0, right: 20.0, bottom: 10.0),
        alignment: Alignment.center,
        child: DropdownButton<ActionModeMenuItem>(
          hint: const Text("Action Mode Menu Items"),
          onChanged: (value) async {
            currentWebViewModel.settings?.disabledActionModeMenuItems = value;
            webViewController?.setSettings(
                settings:
                    currentWebViewModel.settings ?? InAppWebViewSettings());
            currentWebViewModel.settings =
                await webViewController?.getSettings();
            browserModel.save();
            setState(() {});
          },
          value: currentWebViewModel.settings?.disabledActionModeMenuItems,
          items: ActionModeMenuItem.values.map((actionModeMenuItem) {
            return DropdownMenuItem<ActionModeMenuItem>(
              value: actionModeMenuItem,
              child: Text(
                actionModeMenuItem.toString(),
                style: const TextStyle(fontSize: 12.5),
              ),
            );
          }).toList(),
        ),
      ),
      ListTile(
        title: const Text("Fantasy Font Family"),
        subtitle: const Text("Sets the fantasy font family name."),
        trailing: SizedBox(
          width: MediaQuery.of(context).size.width / 3,
          child: TextFormField(
            initialValue: currentWebViewModel.settings?.fantasyFontFamily,
            keyboardType: TextInputType.text,
            onFieldSubmitted: (value) async {
              currentWebViewModel.settings?.fantasyFontFamily = value;
              webViewController?.setSettings(
                  settings:
                      currentWebViewModel.settings ?? InAppWebViewSettings());
              currentWebViewModel.settings =
                  await webViewController?.getSettings();
              browserModel.save();
              setState(() {});
            },
          ),
        ),
      ),
      ListTile(
        title: const Text("Fixed Font Family"),
        subtitle: const Text("Sets the fixed font family name."),
        trailing: SizedBox(
          width: MediaQuery.of(context).size.width / 3,
          child: TextFormField(
            initialValue: currentWebViewModel.settings?.fixedFontFamily,
            keyboardType: TextInputType.text,
            onFieldSubmitted: (value) async {
              currentWebViewModel.settings?.fixedFontFamily = value;
              webViewController?.setSettings(
                  settings:
                      currentWebViewModel.settings ?? InAppWebViewSettings());
              currentWebViewModel.settings =
                  await webViewController?.getSettings();
              browserModel.save();
              setState(() {});
            },
          ),
        ),
      ),
      ListTile(
        title: const Text("Force Dark"),
        subtitle: const Text("Set the force dark mode for this WebView."),
        trailing: DropdownButton<ForceDark>(
          hint: const Text("Force Dark"),
          onChanged: (value) async {
            currentWebViewModel.settings?.forceDark = value;
            webViewController?.setSettings(
                settings:
                    currentWebViewModel.settings ?? InAppWebViewSettings());
            currentWebViewModel.settings =
                await webViewController?.getSettings();
            browserModel.save();
            setState(() {});
          },
          value: currentWebViewModel.settings?.forceDark,
          items: ForceDark.values.map((forceDark) {
            return DropdownMenuItem<ForceDark>(
              value: forceDark,
              child: Text(
                forceDark.toString(),
                style: const TextStyle(fontSize: 12.5),
              ),
            );
          }).toList(),
        ),
      ),
      SwitchListTile(
        title: const Text("Geolocation Enabled"),
        subtitle: const Text("Sets whether Geolocation API is enabled."),
        value: currentWebViewModel.settings?.geolocationEnabled ?? true,
        onChanged: (value) async {
          currentWebViewModel.settings?.geolocationEnabled = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          currentWebViewModel.settings = await webViewController?.getSettings();
          browserModel.save();
          setState(() {});
        },
      ),
      ListTile(
        title: const Text("Layout Algorithm"),
        subtitle: const Text(
            "Sets the underlying layout algorithm. This will cause a re-layout of the WebView."),
        trailing: DropdownButton<LayoutAlgorithm>(
          hint: const Text("Layout Algorithm"),
          onChanged: (value) async {
            currentWebViewModel.settings?.layoutAlgorithm = value;
            webViewController?.setSettings(
                settings:
                    currentWebViewModel.settings ?? InAppWebViewSettings());
            currentWebViewModel.settings =
                await webViewController?.getSettings();
            browserModel.save();
            setState(() {});
          },
          value: currentWebViewModel.settings?.layoutAlgorithm,
          items: LayoutAlgorithm.values.map((layoutAlgorithm) {
            return DropdownMenuItem<LayoutAlgorithm>(
              value: layoutAlgorithm,
              child: Text(
                layoutAlgorithm.toString(),
                style: const TextStyle(fontSize: 12.5),
              ),
            );
          }).toList(),
        ),
      ),
      SwitchListTile(
        title: const Text("Load With Overview Mode"),
        subtitle: const Text(
            "Sets whether the WebView loads pages in overview mode, that is, zooms out the content to fit on screen by width."),
        value: currentWebViewModel.settings?.loadWithOverviewMode ?? false,
        onChanged: (value) async {
          currentWebViewModel.settings?.loadWithOverviewMode = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          currentWebViewModel.settings = await webViewController?.getSettings();
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Loads Images Automatically"),
        subtitle: const Text(
            "Sets whether the WebView should load image resources. Note that this method controls loading of all images, including those embedded using the data URI scheme."),
        value: currentWebViewModel.settings?.loadsImagesAutomatically ?? true,
        onChanged: (value) async {
          currentWebViewModel.settings?.loadsImagesAutomatically = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          currentWebViewModel.settings = await webViewController?.getSettings();
          browserModel.save();
          setState(() {});
        },
      ),
      ListTile(
        title: const Text("Minimum Logical Font Size"),
        subtitle: const Text("Sets the minimum logical font size."),
        trailing: SizedBox(
          width: 50.0,
          child: TextFormField(
            initialValue:
                currentWebViewModel.settings?.minimumLogicalFontSize.toString(),
            keyboardType: const TextInputType.numberWithOptions(),
            onFieldSubmitted: (value) async {
              currentWebViewModel.settings?.minimumLogicalFontSize =
                  int.parse(value);
              webViewController?.setSettings(
                  settings:
                      currentWebViewModel.settings ?? InAppWebViewSettings());
              currentWebViewModel.settings =
                  await webViewController?.getSettings();
              browserModel.save();
              setState(() {});
            },
          ),
        ),
      ),
      ListTile(
        title: const Text("Initial Scale"),
        subtitle: const Text(
            "Sets the initial scale for this WebView. 0 means default."),
        trailing: SizedBox(
          width: 50.0,
          child: TextFormField(
            initialValue: currentWebViewModel.settings?.initialScale.toString(),
            keyboardType: const TextInputType.numberWithOptions(),
            onFieldSubmitted: (value) async {
              currentWebViewModel.settings?.initialScale = int.parse(value);
              webViewController?.setSettings(
                  settings:
                      currentWebViewModel.settings ?? InAppWebViewSettings());
              currentWebViewModel.settings =
                  await webViewController?.getSettings();
              browserModel.save();
              setState(() {});
            },
          ),
        ),
      ),
      SwitchListTile(
        title: const Text("Need Initial Focus"),
        subtitle:
            const Text("Tells the WebView whether it needs to set a node."),
        value: currentWebViewModel.settings?.needInitialFocus ?? true,
        onChanged: (value) async {
          currentWebViewModel.settings?.needInitialFocus = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          currentWebViewModel.settings = await webViewController?.getSettings();
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Offscreen Pre Raster"),
        subtitle: const Text(
            "Sets whether this WebView should raster tiles when it is offscreen but attached to a window."),
        value: currentWebViewModel.settings?.offscreenPreRaster ?? false,
        onChanged: (value) async {
          currentWebViewModel.settings?.offscreenPreRaster = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          currentWebViewModel.settings = await webViewController?.getSettings();
          browserModel.save();
          setState(() {});
        },
      ),
      ListTile(
        title: const Text("Sans-Serif Font Family"),
        subtitle: const Text("Sets the sans-serif font family name."),
        trailing: SizedBox(
          width: MediaQuery.of(context).size.width / 3,
          child: TextFormField(
            initialValue: currentWebViewModel.settings?.sansSerifFontFamily,
            keyboardType: TextInputType.text,
            onFieldSubmitted: (value) async {
              currentWebViewModel.settings?.sansSerifFontFamily = value;
              webViewController?.setSettings(
                  settings:
                      currentWebViewModel.settings ?? InAppWebViewSettings());
              currentWebViewModel.settings =
                  await webViewController?.getSettings();
              browserModel.save();
              setState(() {});
            },
          ),
        ),
      ),
      ListTile(
        title: const Text("Serif Font Family"),
        subtitle: const Text("Sets the serif font family name."),
        trailing: SizedBox(
          width: MediaQuery.of(context).size.width / 3,
          child: TextFormField(
            initialValue: currentWebViewModel.settings?.serifFontFamily,
            keyboardType: TextInputType.text,
            onFieldSubmitted: (value) async {
              currentWebViewModel.settings?.serifFontFamily = value;
              webViewController?.setSettings(
                  settings:
                      currentWebViewModel.settings ?? InAppWebViewSettings());
              currentWebViewModel.settings =
                  await webViewController?.getSettings();
              browserModel.save();
              setState(() {});
            },
          ),
        ),
      ),
      ListTile(
        title: const Text("Standard Font Family"),
        subtitle: const Text("Sets the standard font family name."),
        trailing: SizedBox(
          width: MediaQuery.of(context).size.width / 3,
          child: TextFormField(
            initialValue: currentWebViewModel.settings?.standardFontFamily,
            keyboardType: TextInputType.text,
            onFieldSubmitted: (value) async {
              currentWebViewModel.settings?.standardFontFamily = value;
              webViewController?.setSettings(
                  settings:
                      currentWebViewModel.settings ?? InAppWebViewSettings());
              currentWebViewModel.settings =
                  await webViewController?.getSettings();
              browserModel.save();
              setState(() {});
            },
          ),
        ),
      ),
      SwitchListTile(
        title: const Text("Save Form Data"),
        subtitle: const Text(
            "Sets whether the WebView should save form data. In Android O, the platform has implemented a fully functional Autofill feature to store form data."),
        value: currentWebViewModel.settings?.saveFormData ?? true,
        onChanged: (value) async {
          currentWebViewModel.settings?.saveFormData = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          currentWebViewModel.settings = await webViewController?.getSettings();
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Third Party Cookies Enabled"),
        subtitle: const Text(
            "Sets whether the Webview should enable third party cookies."),
        value: currentWebViewModel.settings?.thirdPartyCookiesEnabled ?? true,
        onChanged: (value) async {
          currentWebViewModel.settings?.thirdPartyCookiesEnabled = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          currentWebViewModel.settings = await webViewController?.getSettings();
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Hardware Acceleration"),
        subtitle: const Text(
            "Sets whether the Webview should enable Hardware Acceleration."),
        value: currentWebViewModel.settings?.hardwareAcceleration ?? true,
        onChanged: (value) async {
          currentWebViewModel.settings?.hardwareAcceleration = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          currentWebViewModel.settings = await webViewController?.getSettings();
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Support Multiple Windows"),
        subtitle: const Text(
            "Sets whether the WebView whether supports multiple windows."),
        value: currentWebViewModel.settings?.supportMultipleWindows ?? false,
        onChanged: (value) async {
          currentWebViewModel.settings?.supportMultipleWindows = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          currentWebViewModel.settings = await webViewController?.getSettings();
          browserModel.save();
          setState(() {});
        },
      ),
      const ListTile(
        title: Text("Over Scroll Mode"),
        subtitle: Text("Sets the WebView's over-scroll mode."),
      ),
      Container(
        padding: const EdgeInsets.only(
            left: 20.0, top: 0.0, right: 20.0, bottom: 10.0),
        alignment: Alignment.center,
        child: DropdownButton<OverScrollMode>(
          hint: const Text("Over Scroll Mode"),
          onChanged: (value) async {
            currentWebViewModel.settings?.overScrollMode = value;
            webViewController?.setSettings(
                settings:
                    currentWebViewModel.settings ?? InAppWebViewSettings());
            currentWebViewModel.settings =
                await webViewController?.getSettings();
            browserModel.save();
            setState(() {});
          },
          value: currentWebViewModel.settings?.overScrollMode,
          items: OverScrollMode.values.map((overScrollMode) {
            return DropdownMenuItem<OverScrollMode>(
              value: overScrollMode,
              child: Text(
                overScrollMode.toString(),
                style: const TextStyle(fontSize: 12.5),
              ),
            );
          }).toList(),
        ),
      ),
      SwitchListTile(
        title: const Text("Network Available"),
        subtitle: const Text("Informs WebView of the network state."),
        value: currentWebViewModel.settings?.networkAvailable ?? true,
        onChanged: (value) async {
          currentWebViewModel.settings?.networkAvailable = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          currentWebViewModel.settings = await webViewController?.getSettings();
          browserModel.save();
          setState(() {});
        },
      ),
      const ListTile(
        title: Text("Scroll Bar Style"),
        subtitle: Text("Specify the style of the scrollbars."),
      ),
      Container(
        padding: const EdgeInsets.only(
            left: 20.0, top: 0.0, right: 20.0, bottom: 10.0),
        alignment: Alignment.center,
        child: DropdownButton<ScrollBarStyle>(
          hint: const Text("Scroll Bar Style"),
          onChanged: (value) async {
            currentWebViewModel.settings?.scrollBarStyle = value;
            webViewController?.setSettings(
                settings:
                    currentWebViewModel.settings ?? InAppWebViewSettings());
            currentWebViewModel.settings =
                await webViewController?.getSettings();
            browserModel.save();
            setState(() {});
          },
          value: currentWebViewModel.settings?.scrollBarStyle,
          items: ScrollBarStyle.values.map((scrollBarStyle) {
            return DropdownMenuItem<ScrollBarStyle>(
              value: scrollBarStyle,
              child: Text(
                scrollBarStyle.toString(),
                style: const TextStyle(fontSize: 12.5),
              ),
            );
          }).toList(),
        ),
      ),
      const ListTile(
        title: Text("Vertical Scrollbar Position"),
        subtitle: Text("Set the position of the vertical scroll bar."),
      ),
      Container(
        padding: const EdgeInsets.only(
            left: 20.0, top: 0.0, right: 20.0, bottom: 10.0),
        alignment: Alignment.center,
        child: DropdownButton<VerticalScrollbarPosition>(
          hint: const Text("Vertical Scrollbar Position"),
          onChanged: (value) async {
            currentWebViewModel.settings?.verticalScrollbarPosition = value;
            webViewController?.setSettings(
                settings:
                    currentWebViewModel.settings ?? InAppWebViewSettings());
            currentWebViewModel.settings =
                await webViewController?.getSettings();
            browserModel.save();
            setState(() {});
          },
          value: currentWebViewModel.settings?.verticalScrollbarPosition,
          items:
              VerticalScrollbarPosition.values.map((verticalScrollbarPosition) {
            return DropdownMenuItem<VerticalScrollbarPosition>(
              value: verticalScrollbarPosition,
              child: Text(
                verticalScrollbarPosition.toString(),
                style: const TextStyle(fontSize: 12.5),
              ),
            );
          }).toList(),
        ),
      ),
      ListTile(
        title: const Text("Scroll Bar Default Delay Before Fade"),
        subtitle: const Text(
            "Defines the delay in milliseconds that a scrollbar waits before fade out."),
        trailing: SizedBox(
          width: 50.0,
          child: TextFormField(
            initialValue: currentWebViewModel
                    .settings?.scrollBarDefaultDelayBeforeFade
                    ?.toString() ??
                "0",
            keyboardType: const TextInputType.numberWithOptions(),
            onFieldSubmitted: (value) async {
              currentWebViewModel.settings?.scrollBarDefaultDelayBeforeFade =
                  int.parse(value);
              webViewController?.setSettings(
                  settings:
                      currentWebViewModel.settings ?? InAppWebViewSettings());
              currentWebViewModel.settings =
                  await webViewController?.getSettings();
              browserModel.save();
              setState(() {});
            },
          ),
        ),
      ),
      SwitchListTile(
        title: const Text("Scrollbar Fading Enabled"),
        subtitle: const Text(
            "Define whether scrollbars will fade when the view is not scrolling."),
        value: currentWebViewModel.settings?.scrollbarFadingEnabled ?? true,
        onChanged: (value) async {
          currentWebViewModel.settings?.scrollbarFadingEnabled = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          currentWebViewModel.settings = await webViewController?.getSettings();
          browserModel.save();
          setState(() {});
        },
      ),
      ListTile(
        title: const Text("Scroll Bar Fade Duration"),
        subtitle:
            const Text("Define the scrollbar fade duration in milliseconds."),
        trailing: SizedBox(
          width: 50.0,
          child: TextFormField(
            initialValue: currentWebViewModel.settings?.scrollBarFadeDuration
                    ?.toString() ??
                "0",
            keyboardType: const TextInputType.numberWithOptions(),
            onFieldSubmitted: (value) async {
              currentWebViewModel.settings?.scrollBarFadeDuration =
                  int.parse(value);
              webViewController?.setSettings(
                  settings:
                      currentWebViewModel.settings ?? InAppWebViewSettings());
              currentWebViewModel.settings =
                  await webViewController?.getSettings();
              browserModel.save();
              setState(() {});
            },
          ),
        ),
      ),
      ListTile(
        title: const Text("Vertical Scrollbar Thumb Color"),
        subtitle: const Text("Sets the vertical scrollbar thumb color."),
        trailing: SizedBox(
            width: 140.0,
            child: ElevatedButton(
              child: Text(
                currentWebViewModel.settings?.verticalScrollbarThumbColor
                        ?.toString() ??
                    'Pick a color!',
                style: const TextStyle(fontSize: 12.5),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      content: SingleChildScrollView(
                        child: ColorPicker(
                          pickerColor: const Color(0xffffffff),
                          onColorChanged: (value) async {
                            currentWebViewModel
                                .settings?.verticalScrollbarThumbColor = value;
                            webViewController?.setSettings(
                                settings: currentWebViewModel.settings ??
                                    InAppWebViewSettings());
                            currentWebViewModel.settings =
                                await webViewController?.getSettings();
                            browserModel.save();
                            setState(() {});
                          },
                          labelTypes: const [
                            ColorLabelType.rgb,
                            ColorLabelType.hsv,
                            ColorLabelType.hsl
                          ],
                          pickerAreaHeightPercent: 0.8,
                        ),
                      ),
                    );
                  },
                );
              },
            )),
      ),
      ListTile(
        title: const Text("Vertical Scrollbar Track Color"),
        subtitle: const Text("Sets the vertical scrollbar track color."),
        trailing: SizedBox(
            width: 140.0,
            child: ElevatedButton(
              child: Text(
                currentWebViewModel.settings?.verticalScrollbarTrackColor
                        ?.toString() ??
                    'Pick a color!',
                style: const TextStyle(fontSize: 12.5),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      content: SingleChildScrollView(
                        child: ColorPicker(
                          pickerColor: const Color(0xffffffff),
                          onColorChanged: (value) async {
                            currentWebViewModel
                                .settings?.verticalScrollbarTrackColor = value;
                            webViewController?.setSettings(
                                settings: currentWebViewModel.settings ??
                                    InAppWebViewSettings());
                            currentWebViewModel.settings =
                                await webViewController?.getSettings();
                            browserModel.save();
                            setState(() {});
                          },
                          labelTypes: const [
                            ColorLabelType.rgb,
                            ColorLabelType.hsv,
                            ColorLabelType.hsl
                          ],
                          pickerAreaHeightPercent: 0.8,
                        ),
                      ),
                    );
                  },
                );
              },
            )),
      ),
      ListTile(
        title: const Text("Horizontal Scrollbar Thumb Color"),
        subtitle: const Text("Sets the horizontal scrollbar thumb color."),
        trailing: SizedBox(
            width: 140.0,
            child: ElevatedButton(
              child: Text(
                currentWebViewModel.settings?.horizontalScrollbarThumbColor
                        ?.toString() ??
                    'Pick a color!',
                style: const TextStyle(fontSize: 12.5),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      content: SingleChildScrollView(
                        child: ColorPicker(
                          pickerColor: const Color(0xffffffff),
                          onColorChanged: (value) async {
                            currentWebViewModel.settings
                                ?.horizontalScrollbarThumbColor = value;
                            webViewController?.setSettings(
                                settings: currentWebViewModel.settings ??
                                    InAppWebViewSettings());
                            currentWebViewModel.settings =
                                await webViewController?.getSettings();
                            browserModel.save();
                            setState(() {});
                          },
                          labelTypes: const [
                            ColorLabelType.rgb,
                            ColorLabelType.hsv,
                            ColorLabelType.hsl
                          ],
                          pickerAreaHeightPercent: 0.8,
                        ),
                      ),
                    );
                  },
                );
              },
            )),
      ),
      ListTile(
        title: const Text("Horizontal Scrollbar Track Color"),
        subtitle: const Text("Sets the horizontal scrollbar track color."),
        trailing: SizedBox(
            width: 140.0,
            child: ElevatedButton(
              child: Text(
                currentWebViewModel.settings?.horizontalScrollbarTrackColor
                        ?.toString() ??
                    'Pick a color!',
                style: const TextStyle(fontSize: 12.5),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      content: SingleChildScrollView(
                        child: ColorPicker(
                          pickerColor: const Color(0xffffffff),
                          onColorChanged: (value) async {
                            currentWebViewModel.settings
                                ?.horizontalScrollbarTrackColor = value;
                            webViewController?.setSettings(
                                settings: currentWebViewModel.settings ??
                                    InAppWebViewSettings());
                            currentWebViewModel.settings =
                                await webViewController?.getSettings();
                            browserModel.save();
                            setState(() {});
                          },
                          labelTypes: const [
                            ColorLabelType.rgb,
                            ColorLabelType.hsv,
                            ColorLabelType.hsl
                          ],
                          pickerAreaHeightPercent: 0.8,
                        ),
                      ),
                    );
                  },
                );
              },
            )),
      ),
    ];

    return widgets;
  }
}
