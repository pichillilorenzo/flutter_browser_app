import 'package:flutter/material.dart';
import 'package:flutter_browser/models/browser_model.dart';
import 'package:flutter_browser/models/webview_model.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

class AndroidSettings extends StatefulWidget {
  AndroidSettings({Key? key}) : super(key: key);

  @override
  _AndroidSettingsState createState() => _AndroidSettingsState();
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
    if (browserModel.webViewTabs.length == 0) {
      return [];
    }
    var currentWebViewModel = Provider.of<WebViewModel>(context, listen: true);
    var _webViewController = currentWebViewModel.webViewController;

    var widgets = <Widget>[
      ListTile(
        title: const Text("Current WebView Android Settings"),
        enabled: false,
      ),
      ListTile(
        title: const Text("Text Zoom"),
        subtitle: const Text("Sets the text zoom of the page in percent."),
        trailing: Container(
          width: 50.0,
          child: TextFormField(
            initialValue:
                currentWebViewModel.options?.android.textZoom.toString(),
            keyboardType: TextInputType.numberWithOptions(),
            onFieldSubmitted: (value) async {
              currentWebViewModel.options?.android.textZoom = int.parse(value);
              _webViewController?.setOptions(
                  options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
              currentWebViewModel.options =
                  await _webViewController?.getOptions();
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
        value: currentWebViewModel.options?.android.clearSessionCache ?? false,
        onChanged: (value) async {
          currentWebViewModel.options?.android.clearSessionCache = value;
          _webViewController?.setOptions(options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
          currentWebViewModel.options = await _webViewController?.getOptions();
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Built In Zoom Controls"),
        subtitle: const Text(
            "Sets whether the WebView should use its built-in zoom mechanisms."),
        value: currentWebViewModel.options?.android.builtInZoomControls ?? false,
        onChanged: (value) async {
          currentWebViewModel.options?.android.builtInZoomControls = value;
          _webViewController?.setOptions(options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
          currentWebViewModel.options = await _webViewController?.getOptions();
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Display Zoom Controls"),
        subtitle: const Text(
            "Sets whether the WebView should display on-screen zoom controls when using the built-in zoom mechanisms."),
        value: currentWebViewModel.options?.android.displayZoomControls ?? false,
        onChanged: (value) async {
          currentWebViewModel.options?.android.displayZoomControls = value;
          _webViewController?.setOptions(options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
          currentWebViewModel.options = await _webViewController?.getOptions();
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Database storage API"),
        subtitle: const Text(
            "Sets whether the Database storage API should be enabled."),
        value: currentWebViewModel.options?.android.databaseEnabled ?? true,
        onChanged: (value) async {
          currentWebViewModel.options?.android.databaseEnabled = value;
          _webViewController?.setOptions(options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
          currentWebViewModel.options = await _webViewController?.getOptions();
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("DOM storage API"),
        subtitle:
            const Text("Sets whether the DOM storage API should be enabled."),
        value: currentWebViewModel.options?.android.domStorageEnabled ?? true,
        onChanged: (value) {
          setState(() {
            currentWebViewModel.options?.android.domStorageEnabled = value;
            _webViewController?.setOptions(options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
            browserModel.save();
          });
        },
      ),
      SwitchListTile(
        title: const Text("Use Wide View Port"),
        subtitle: const Text(
            "Sets whether the WebView should enable support for the \"viewport\" HTML meta tag or should use a wide viewport."),
        value: currentWebViewModel.options?.android.useWideViewPort ?? true,
        onChanged: (value) async {
          currentWebViewModel.options?.android.useWideViewPort = value;
          _webViewController?.setOptions(options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
          currentWebViewModel.options = await _webViewController?.getOptions();
          browserModel.save();
          setState(() {});
        },
      ),
      ListTile(
        title: const Text("Mixed Content Mode"),
        subtitle: const Text(
            "Configures the WebView's behavior when a secure origin attempts to load a resource from an insecure origin."),
      ),
      Container(
        padding: EdgeInsets.only(left: 20.0, top: 0.0, right: 20.0, bottom: 10.0),
        alignment: Alignment.center,
        child: DropdownButton<AndroidMixedContentMode>(
          hint: Text("Mixed Content Mode"),
          onChanged: (value) async {
            currentWebViewModel.options?.android.mixedContentMode = value;
            _webViewController?.setOptions(options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
            currentWebViewModel.options = await _webViewController?.getOptions();
            browserModel.save();
            setState(() {});
          },
          value: currentWebViewModel.options?.android.mixedContentMode,
          items: AndroidMixedContentMode.values.map((mixedContentMode) {
            return DropdownMenuItem<AndroidMixedContentMode>(
              value: mixedContentMode,
              child: Text(
                mixedContentMode.toString(),
                style: TextStyle(fontSize: 12.5),
              ),
            );
          }).toList(),
        ),
      ),
      SwitchListTile(
        title: const Text("Allow Content Access"),
        subtitle: const Text(
            "Enables or disables content URL access within WebView. Content URL access allows WebView to load content from a content provider installed in the system."),
        value: currentWebViewModel.options?.android.allowContentAccess ?? true,
        onChanged: (value) async {
          currentWebViewModel.options?.android.allowContentAccess = value;
          _webViewController?.setOptions(options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
          currentWebViewModel.options = await _webViewController?.getOptions();
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Allow File Access"),
        subtitle: const Text(
            "Enables or disables file access within WebView. Note that this enables or disables file system access only."),
        value: currentWebViewModel.options?.android.allowFileAccess ?? true,
        onChanged: (value) async {
          currentWebViewModel.options?.android.allowFileAccess = value;
          _webViewController?.setOptions(options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
          currentWebViewModel.options = await _webViewController?.getOptions();
          browserModel.save();
          setState(() {});
        },
      ),
      ListTile(
        title: const Text("App Cache Path"),
        subtitle: const Text(
            "Sets the path to the Application Caches files. In order for the Application Caches API to be enabled, this option must be set a path to which the application can write."),
      ),
      Container(
        padding: EdgeInsets.only(left: 20.0, top: 0.0, right: 20.0, bottom: 20.0),
        alignment: Alignment.center,
        child: TextFormField(
          initialValue: currentWebViewModel.options?.android.appCachePath,
          keyboardType: TextInputType.text,
          onFieldSubmitted: (value) async {
            currentWebViewModel.options?.android.appCachePath = value.trim();
            _webViewController?.setOptions(
                options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
            currentWebViewModel.options =
            await _webViewController?.getOptions();
            browserModel.save();
            setState(() {});
          },
        ),
      ),
      SwitchListTile(
        title: const Text("Block Network Image"),
        subtitle: const Text(
            "Sets whether the WebView should not load image resources from the network (resources accessed via http and https URI schemes)."),
        value: currentWebViewModel.options?.android.blockNetworkImage ?? false,
        onChanged: (value) async {
          currentWebViewModel.options?.android.blockNetworkImage = value;
          _webViewController?.setOptions(options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
          currentWebViewModel.options = await _webViewController?.getOptions();
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Block Network Loads"),
        subtitle: const Text(
            "Sets whether the WebView should not load resources from the network."),
        value: currentWebViewModel.options?.android.blockNetworkLoads ?? false,
        onChanged: (value) async {
          currentWebViewModel.options?.android.blockNetworkLoads = value;
          _webViewController?.setOptions(options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
          currentWebViewModel.options = await _webViewController?.getOptions();
          browserModel.save();
          setState(() {});
        },
      ),
      ListTile(
        title: const Text("Cache Mode"),
        subtitle: const Text(
            "Overrides the way the cache is used. The way the cache is used is based on the navigation type."),
      ),
      Container(
        padding: EdgeInsets.only(left: 20.0, top: 0.0, right: 20.0, bottom: 10.0),
        alignment: Alignment.center,
        child: DropdownButton<AndroidCacheMode>(
          hint: Text("Cache Mode"),
          onChanged: (value) async {
            currentWebViewModel.options?.android.cacheMode = value;
            _webViewController?.setOptions(options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
            currentWebViewModel.options = await _webViewController?.getOptions();
            browserModel.save();
            setState(() {});
          },
          value: currentWebViewModel.options?.android.cacheMode,
          items: AndroidCacheMode.values.map((cacheMode) {
            return DropdownMenuItem<AndroidCacheMode>(
              value: cacheMode,
              child: Text(
                cacheMode.toString(),
                style: TextStyle(fontSize: 12.5),
              ),
            );
          }).toList(),
        ),
      ),
      ListTile(
        title: const Text("Cursive Font Family"),
        subtitle: const Text("Sets the cursive font family name."),
        trailing: Container(
          width: MediaQuery.of(context).size.width / 3,
          child: TextFormField(
            initialValue: currentWebViewModel.options?.android.cursiveFontFamily,
            keyboardType: TextInputType.text,
            onFieldSubmitted: (value) async {
              currentWebViewModel.options?.android.cursiveFontFamily = value;
              _webViewController?.setOptions(
                  options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
              currentWebViewModel.options =
                  await _webViewController?.getOptions();
              browserModel.save();
              setState(() {});
            },
          ),
        ),
      ),
      ListTile(
        title: const Text("Default Fixed Font Size"),
        subtitle: const Text("Sets the default fixed font size."),
        trailing: Container(
          width: 50,
          child: TextFormField(
            initialValue: currentWebViewModel
                .options?.android.defaultFixedFontSize
                .toString(),
            keyboardType: TextInputType.numberWithOptions(),
            onFieldSubmitted: (value) async {
              currentWebViewModel.options?.android.defaultFixedFontSize =
                  int.parse(value);
              _webViewController?.setOptions(
                  options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
              currentWebViewModel.options =
                  await _webViewController?.getOptions();
              browserModel.save();
              setState(() {});
            },
          ),
        ),
      ),
      ListTile(
        title: const Text("Default Font Size"),
        subtitle: const Text("Sets the default font size."),
        trailing: Container(
          width: 50.0,
          child: TextFormField(
            initialValue:
                currentWebViewModel.options?.android.defaultFontSize.toString(),
            keyboardType: TextInputType.numberWithOptions(),
            onFieldSubmitted: (value) async {
              currentWebViewModel.options?.android.defaultFontSize =
                  int.parse(value);
              _webViewController?.setOptions(
                  options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
              currentWebViewModel.options =
                  await _webViewController?.getOptions();
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
        trailing: Container(
          width: MediaQuery.of(context).size.width / 3,
          child: TextFormField(
            initialValue:
                currentWebViewModel.options?.android.defaultTextEncodingName,
            keyboardType: TextInputType.text,
            onFieldSubmitted: (value) async {
              currentWebViewModel.options?.android.defaultTextEncodingName =
                  value;
              _webViewController?.setOptions(
                  options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
              currentWebViewModel.options =
                  await _webViewController?.getOptions();
              browserModel.save();
              setState(() {});
            },
          ),
        ),
      ),
      ListTile(
        title: const Text("Disabled Action Mode Menu Items"),
        subtitle: const Text(
            "Disables the action mode menu items according to menuItems flag."),
      ),
      Container(
        padding: EdgeInsets.only(left: 20.0, top: 0.0, right: 20.0, bottom: 10.0),
        alignment: Alignment.center,
        child: DropdownButton<AndroidActionModeMenuItem>(
          hint: Text("Action Mode Menu Items"),
          onChanged: (value) async {
            currentWebViewModel.options?.android.disabledActionModeMenuItems =
                value;
            _webViewController?.setOptions(options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
            currentWebViewModel.options = await _webViewController?.getOptions();
            browserModel.save();
            setState(() {});
          },
          value:
          currentWebViewModel.options?.android.disabledActionModeMenuItems,
          items: AndroidActionModeMenuItem.values.map((actionModeMenuItem) {
            return DropdownMenuItem<AndroidActionModeMenuItem>(
              value: actionModeMenuItem,
              child: Text(
                actionModeMenuItem.toString(),
                style: TextStyle(fontSize: 12.5),
              ),
            );
          }).toList(),
        ),
      ),
      ListTile(
        title: const Text("Fantasy Font Family"),
        subtitle: const Text("Sets the fantasy font family name."),
        trailing: Container(
          width: MediaQuery.of(context).size.width / 3,
          child: TextFormField(
            initialValue: currentWebViewModel.options?.android.fantasyFontFamily,
            keyboardType: TextInputType.text,
            onFieldSubmitted: (value) async {
              currentWebViewModel.options?.android.fantasyFontFamily = value;
              _webViewController?.setOptions(
                  options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
              currentWebViewModel.options =
                  await _webViewController?.getOptions();
              browserModel.save();
              setState(() {});
            },
          ),
        ),
      ),
      ListTile(
        title: const Text("Fixed Font Family"),
        subtitle: const Text("Sets the fixed font family name."),
        trailing: Container(
          width: MediaQuery.of(context).size.width / 3,
          child: TextFormField(
            initialValue: currentWebViewModel.options?.android.fixedFontFamily,
            keyboardType: TextInputType.text,
            onFieldSubmitted: (value) async {
              currentWebViewModel.options?.android.fixedFontFamily = value;
              _webViewController?.setOptions(
                  options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
              currentWebViewModel.options =
                  await _webViewController?.getOptions();
              browserModel.save();
              setState(() {});
            },
          ),
        ),
      ),
      ListTile(
        title: const Text("Force Dark"),
        subtitle: const Text("Set the force dark mode for this WebView."),
        trailing: DropdownButton<AndroidForceDark>(
          hint: Text("Force Dark"),
          onChanged: (value) async {
            currentWebViewModel.options?.android.forceDark = value;
            _webViewController?.setOptions(options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
            currentWebViewModel.options = await _webViewController?.getOptions();
            browserModel.save();
            setState(() {});
          },
          value: currentWebViewModel.options?.android.forceDark,
          items: AndroidForceDark.values.map((forceDark) {
            return DropdownMenuItem<AndroidForceDark>(
              value: forceDark,
              child: Text(
                forceDark.toString(),
                style: TextStyle(fontSize: 12.5),
              ),
            );
          }).toList(),
        ),
      ),
      SwitchListTile(
        title: const Text("Geolocation Enabled"),
        subtitle: const Text("Sets whether Geolocation API is enabled."),
        value: currentWebViewModel.options?.android.geolocationEnabled ?? true,
        onChanged: (value) async {
          currentWebViewModel.options?.android.geolocationEnabled = value;
          _webViewController?.setOptions(options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
          currentWebViewModel.options = await _webViewController?.getOptions();
          browserModel.save();
          setState(() {});
        },
      ),
      ListTile(
        title: const Text("Layout Algorithm"),
        subtitle: const Text(
            "Sets the underlying layout algorithm. This will cause a re-layout of the WebView."),
        trailing: DropdownButton<AndroidLayoutAlgorithm>(
          hint: Text("Layout Algorithm"),
          onChanged: (value) async {
            currentWebViewModel.options?.android.layoutAlgorithm = value;
            _webViewController?.setOptions(options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
            currentWebViewModel.options = await _webViewController?.getOptions();
            browserModel.save();
            setState(() {});
          },
          value: currentWebViewModel.options?.android.layoutAlgorithm,
          items: AndroidLayoutAlgorithm.values.map((layoutAlgorithm) {
            return DropdownMenuItem<AndroidLayoutAlgorithm>(
              value: layoutAlgorithm,
              child: Text(
                layoutAlgorithm.toString(),
                style: TextStyle(fontSize: 12.5),
              ),
            );
          }).toList(),
        ),
      ),
      SwitchListTile(
        title: const Text("Load With Overview Mode"),
        subtitle: const Text(
            "Sets whether the WebView loads pages in overview mode, that is, zooms out the content to fit on screen by width."),
        value: currentWebViewModel.options?.android.loadWithOverviewMode ?? false,
        onChanged: (value) async {
          currentWebViewModel.options?.android.loadWithOverviewMode = value;
          _webViewController?.setOptions(options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
          currentWebViewModel.options = await _webViewController?.getOptions();
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Loads Images Automatically"),
        subtitle: const Text(
            "Sets whether the WebView should load image resources. Note that this method controls loading of all images, including those embedded using the data URI scheme."),
        value: currentWebViewModel.options?.android.loadsImagesAutomatically ?? true,
        onChanged: (value) async {
          currentWebViewModel.options?.android.loadsImagesAutomatically = value;
          _webViewController?.setOptions(options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
          currentWebViewModel.options = await _webViewController?.getOptions();
          browserModel.save();
          setState(() {});
        },
      ),
      ListTile(
        title: const Text("Minimum Logical Font Size"),
        subtitle: const Text("Sets the minimum logical font size."),
        trailing: Container(
          width: 50.0,
          child: TextFormField(
            initialValue: currentWebViewModel
                .options?.android.minimumLogicalFontSize
                .toString(),
            keyboardType: TextInputType.numberWithOptions(),
            onFieldSubmitted: (value) async {
              currentWebViewModel.options?.android.minimumLogicalFontSize =
                  int.parse(value);
              _webViewController?.setOptions(
                  options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
              currentWebViewModel.options =
                  await _webViewController?.getOptions();
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
        trailing: Container(
          width: 50.0,
          child: TextFormField(
            initialValue:
                currentWebViewModel.options?.android.initialScale.toString(),
            keyboardType: TextInputType.numberWithOptions(),
            onFieldSubmitted: (value) async {
              currentWebViewModel.options?.android.initialScale =
                  int.parse(value);
              _webViewController?.setOptions(
                  options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
              currentWebViewModel.options =
                  await _webViewController?.getOptions();
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
        value: currentWebViewModel.options?.android.needInitialFocus ?? true,
        onChanged: (value) async {
          currentWebViewModel.options?.android.needInitialFocus = value;
          _webViewController?.setOptions(options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
          currentWebViewModel.options = await _webViewController?.getOptions();
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Offscreen Pre Raster"),
        subtitle: const Text(
            "Sets whether this WebView should raster tiles when it is offscreen but attached to a window."),
        value: currentWebViewModel.options?.android.offscreenPreRaster ?? false,
        onChanged: (value) async {
          currentWebViewModel.options?.android.offscreenPreRaster = value;
          _webViewController?.setOptions(options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
          currentWebViewModel.options = await _webViewController?.getOptions();
          browserModel.save();
          setState(() {});
        },
      ),
      ListTile(
        title: const Text("Sans-Serif Font Family"),
        subtitle: const Text("Sets the sans-serif font family name."),
        trailing: Container(
          width: MediaQuery.of(context).size.width / 3,
          child: TextFormField(
            initialValue:
                currentWebViewModel.options?.android.sansSerifFontFamily,
            keyboardType: TextInputType.text,
            onFieldSubmitted: (value) async {
              currentWebViewModel.options?.android.sansSerifFontFamily = value;
              _webViewController?.setOptions(
                  options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
              currentWebViewModel.options =
                  await _webViewController?.getOptions();
              browserModel.save();
              setState(() {});
            },
          ),
        ),
      ),
      ListTile(
        title: const Text("Serif Font Family"),
        subtitle: const Text("Sets the serif font family name."),
        trailing: Container(
          width: MediaQuery.of(context).size.width / 3,
          child: TextFormField(
            initialValue: currentWebViewModel.options?.android.serifFontFamily,
            keyboardType: TextInputType.text,
            onFieldSubmitted: (value) async {
              currentWebViewModel.options?.android.serifFontFamily = value;
              _webViewController?.setOptions(
                  options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
              currentWebViewModel.options =
                  await _webViewController?.getOptions();
              browserModel.save();
              setState(() {});
            },
          ),
        ),
      ),
      ListTile(
        title: const Text("Standard Font Family"),
        subtitle: const Text("Sets the standard font family name."),
        trailing: Container(
          width: MediaQuery.of(context).size.width / 3,
          child: TextFormField(
            initialValue:
                currentWebViewModel.options?.android.standardFontFamily,
            keyboardType: TextInputType.text,
            onFieldSubmitted: (value) async {
              currentWebViewModel.options?.android.standardFontFamily = value;
              _webViewController?.setOptions(
                  options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
              currentWebViewModel.options =
                  await _webViewController?.getOptions();
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
        value: currentWebViewModel.options?.android.saveFormData ?? true,
        onChanged: (value) async {
          currentWebViewModel.options?.android.saveFormData = value;
          _webViewController?.setOptions(options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
          currentWebViewModel.options = await _webViewController?.getOptions();
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Third Party Cookies Enabled"),
        subtitle: const Text(
            "Sets whether the Webview should enable third party cookies."),
        value: currentWebViewModel.options?.android.thirdPartyCookiesEnabled ?? true,
        onChanged: (value) async {
          currentWebViewModel.options?.android.thirdPartyCookiesEnabled = value;
          _webViewController?.setOptions(options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
          currentWebViewModel.options = await _webViewController?.getOptions();
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Hardware Acceleration"),
        subtitle: const Text(
            "Sets whether the Webview should enable Hardware Acceleration."),
        value: currentWebViewModel.options?.android.hardwareAcceleration ?? true,
        onChanged: (value) async {
          currentWebViewModel.options?.android.hardwareAcceleration = value;
          _webViewController?.setOptions(options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
          currentWebViewModel.options = await _webViewController?.getOptions();
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Support Multiple Windows"),
        subtitle: const Text(
            "Sets whether the WebView whether supports multiple windows."),
        value: currentWebViewModel.options?.android.supportMultipleWindows ?? false,
        onChanged: (value) async {
          currentWebViewModel.options?.android.supportMultipleWindows = value;
          _webViewController?.setOptions(options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
          currentWebViewModel.options = await _webViewController?.getOptions();
          browserModel.save();
          setState(() {});
        },
      ),
      ListTile(
        title: const Text("Over Scroll Mode"),
        subtitle: const Text("Sets the WebView's over-scroll mode."),
      ),
      Container(
        padding: EdgeInsets.only(left: 20.0, top: 0.0, right: 20.0, bottom: 10.0),
        alignment: Alignment.center,
        child: DropdownButton<AndroidOverScrollMode>(
          hint: Text("Over Scroll Mode"),
          onChanged: (value) async {
            currentWebViewModel.options?.android.overScrollMode = value;
            _webViewController?.setOptions(options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
            currentWebViewModel.options = await _webViewController?.getOptions();
            browserModel.save();
            setState(() {});
          },
          value: currentWebViewModel.options?.android.overScrollMode,
          items: AndroidOverScrollMode.values.map((overScrollMode) {
            return DropdownMenuItem<AndroidOverScrollMode>(
              value: overScrollMode,
              child: Text(
                overScrollMode.toString(),
                style: TextStyle(fontSize: 12.5),
              ),
            );
          }).toList(),
        ),
      ),
      SwitchListTile(
        title: const Text("Network Available"),
        subtitle: const Text("Informs WebView of the network state."),
        value: currentWebViewModel.options?.android.networkAvailable ?? true,
        onChanged: (value) async {
          currentWebViewModel.options?.android.networkAvailable = value;
          _webViewController?.setOptions(options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
          currentWebViewModel.options = await _webViewController?.getOptions();
          browserModel.save();
          setState(() {});
        },
      ),
      ListTile(
        title: const Text("Scroll Bar Style"),
        subtitle: const Text("Specify the style of the scrollbars."),
      ),
      Container(
        padding: EdgeInsets.only(left: 20.0, top: 0.0, right: 20.0, bottom: 10.0),
        alignment: Alignment.center,
        child: DropdownButton<AndroidScrollBarStyle>(
          hint: Text("Scroll Bar Style"),
          onChanged: (value) async {
            currentWebViewModel.options?.android.scrollBarStyle = value;
            _webViewController?.setOptions(options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
            currentWebViewModel.options = await _webViewController?.getOptions();
            browserModel.save();
            setState(() {});
          },
          value: currentWebViewModel.options?.android.scrollBarStyle,
          items: AndroidScrollBarStyle.values.map((scrollBarStyle) {
            return DropdownMenuItem<AndroidScrollBarStyle>(
              value: scrollBarStyle,
              child: Text(
                scrollBarStyle.toString(),
                style: TextStyle(fontSize: 12.5),
              ),
            );
          }).toList(),
        ),
      ),
      ListTile(
        title: const Text("Vertical Scrollbar Position"),
        subtitle: const Text("Set the position of the vertical scroll bar."),
      ),
      Container(
        padding: EdgeInsets.only(left: 20.0, top: 0.0, right: 20.0, bottom: 10.0),
        alignment: Alignment.center,
        child: DropdownButton<AndroidVerticalScrollbarPosition>(
          hint: Text("Vertical Scrollbar Position"),
          onChanged: (value) async {
            currentWebViewModel.options?.android.verticalScrollbarPosition =
                value;
            _webViewController?.setOptions(options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
            currentWebViewModel.options = await _webViewController?.getOptions();
            browserModel.save();
            setState(() {});
          },
          value: currentWebViewModel.options?.android.verticalScrollbarPosition,
          items: AndroidVerticalScrollbarPosition.values
              .map((verticalScrollbarPosition) {
            return DropdownMenuItem<AndroidVerticalScrollbarPosition>(
              value: verticalScrollbarPosition,
              child: Text(
                verticalScrollbarPosition.toString(),
                style: TextStyle(fontSize: 12.5),
              ),
            );
          }).toList(),
        ),
      ),
      ListTile(
        title: const Text("Scroll Bar Default Delay Before Fade"),
        subtitle: const Text(
            "Defines the delay in milliseconds that a scrollbar waits before fade out."),
        trailing: Container(
          width: 50.0,
          child: TextFormField(
            initialValue: currentWebViewModel.options?.android.scrollBarDefaultDelayBeforeFade?.toString() ?? "0",
            keyboardType: TextInputType.numberWithOptions(),
            onFieldSubmitted: (value) async {
              currentWebViewModel.options?.android
                  .scrollBarDefaultDelayBeforeFade = int.parse(value);
              _webViewController?.setOptions(
                  options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
              currentWebViewModel.options =
                  await _webViewController?.getOptions();
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
        value: currentWebViewModel.options?.android.scrollbarFadingEnabled ?? true,
        onChanged: (value) async {
          currentWebViewModel.options?.android.scrollbarFadingEnabled = value;
          _webViewController?.setOptions(options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
          currentWebViewModel.options = await _webViewController?.getOptions();
          browserModel.save();
          setState(() {});
        },
      ),
      ListTile(
        title: const Text("Scroll Bar Fade Duration"),
        subtitle:
            const Text("Define the scrollbar fade duration in milliseconds."),
        trailing: Container(
          width: 50.0,
          child: TextFormField(
            initialValue: currentWebViewModel.options?.android.scrollBarFadeDuration?.toString() ?? "0",
            keyboardType: TextInputType.numberWithOptions(),
            onFieldSubmitted: (value) async {
              currentWebViewModel.options?.android.scrollBarFadeDuration =
                  int.parse(value);
              _webViewController?.setOptions(
                  options: currentWebViewModel.options ?? InAppWebViewGroupOptions());
              currentWebViewModel.options =
                  await _webViewController?.getOptions();
              browserModel.save();
              setState(() {});
            },
          ),
        ),
      ),
    ];

    return widgets;
  }
}