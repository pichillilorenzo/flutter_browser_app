import 'package:flutter/material.dart';
import 'package:flutter_browser/models/browser_model.dart';
import 'package:flutter_browser/models/webview_model.dart';
import 'package:flutter_browser/multiselect_dialog.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

class IOSSettings extends StatefulWidget {
  IOSSettings({Key key}) : super(key: key);

  @override
  _IOSSettingsState createState() => _IOSSettingsState();
}

class _IOSSettingsState extends State<IOSSettings> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: _buildIOSWebViewSettings(),
    );
  }

  List<Widget> _buildIOSWebViewSettings() {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    if (browserModel.webViewTabs.length == 0) {
      return [];
    }
    var currentWebViewModel = Provider.of<WebViewModel>(context, listen: true);
    var _webViewController = currentWebViewModel.webViewController;

    var widgets = <Widget>[
      ListTile(
        title: const Text("Current WebView iOS Settings"),
        enabled: false,
      ),
      SwitchListTile(
        title: const Text("Disallow Over Scroll"),
        subtitle: const Text(
            "Sets whether the WebView should bounce when the scrolling has reached an edge of the content"),
        value: currentWebViewModel.options.ios.disallowOverScroll,
        onChanged: (value) {
          currentWebViewModel.options.ios.disallowOverScroll = value;
          _webViewController.setOptions(options: currentWebViewModel.options);
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Enable Viewport Scale"),
        subtitle: const Text(
            "Enable to allow a viewport meta tag to either disable or restrict the range of user scaling."),
        value: currentWebViewModel.options.ios.enableViewportScale,
        onChanged: (value) {
          currentWebViewModel.options.ios.enableViewportScale = value;
          _webViewController.setOptions(options: currentWebViewModel.options);
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Suppresses Incremental Rendering"),
        subtitle: const Text(
            "Sets wheter the WebView should suppresses content rendering until it is fully loaded into memory."),
        value: currentWebViewModel.options.ios.suppressesIncrementalRendering,
        onChanged: (value) {
          currentWebViewModel.options.ios.suppressesIncrementalRendering =
              value;
          _webViewController.setOptions(options: currentWebViewModel.options);
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Allows Air Play For Media Playback"),
        subtitle: const Text("Enable AirPlay."),
        value: currentWebViewModel.options.ios.allowsAirPlayForMediaPlayback,
        onChanged: (value) {
          currentWebViewModel.options.ios.allowsAirPlayForMediaPlayback = value;
          _webViewController.setOptions(options: currentWebViewModel.options);
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Allows Back Forward Navigation Gestures"),
        subtitle: const Text(
            "Enable to allow the horizontal swipe gestures trigger back-forward list navigations."),
        value:
            currentWebViewModel.options.ios.allowsBackForwardNavigationGestures,
        onChanged: (value) {
          currentWebViewModel.options.ios.allowsBackForwardNavigationGestures =
              value;
          _webViewController.setOptions(options: currentWebViewModel.options);
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Ignores Viewport Scale Limits"),
        subtitle: const Text(
            "Sets whether the WebView should always allow scaling of the webpage, regardless of the author's intent."),
        value: currentWebViewModel.options.ios.ignoresViewportScaleLimits,
        onChanged: (value) {
          currentWebViewModel.options.ios.ignoresViewportScaleLimits = value;
          _webViewController.setOptions(options: currentWebViewModel.options);
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Allows Inline Media Playback"),
        subtitle: const Text(
            "Enable to allow HTML5 media playback to appear inline within the screen layout, using browser-supplied controls rather than native controls."),
        value: currentWebViewModel.options.ios.allowsInlineMediaPlayback,
        onChanged: (value) {
          currentWebViewModel.options.ios.allowsInlineMediaPlayback = value;
          _webViewController.setOptions(options: currentWebViewModel.options);
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Allows Picture In Picture Media Playback"),
        subtitle:
            const Text("Enable to allow HTML5 videos play picture-in-picture."),
        value:
            currentWebViewModel.options.ios.allowsPictureInPictureMediaPlayback,
        onChanged: (value) {
          currentWebViewModel.options.ios.allowsPictureInPictureMediaPlayback =
              value;
          _webViewController.setOptions(options: currentWebViewModel.options);
          browserModel.save();
          setState(() {});
        },
      ),
      ListTile(
        title: const Text("Selection Granularity"),
        subtitle: const Text(
            "Sets the level of granularity with which the user can interactively select content in the web view."),
        trailing: DropdownButton<IOSWKSelectionGranularity>(
          hint: Text("Granularity"),
          onChanged: (value) {
            currentWebViewModel.options.ios.selectionGranularity = value;
            _webViewController.setOptions(options: currentWebViewModel.options);
            browserModel.save();
            setState(() {});
          },
          value: currentWebViewModel.options.ios.selectionGranularity,
          items: IOSWKSelectionGranularity.values.map((selectionGranularity) {
            return DropdownMenuItem<IOSWKSelectionGranularity>(
              value: selectionGranularity,
              child: Text(
                selectionGranularity.toString(),
                style: TextStyle(fontSize: 12.5),
              ),
            );
          }).toList(),
        ),
      ),
      ListTile(
        title: const Text("Data Detector Types"),
        subtitle: Text("Specifying a dataDetectoryTypes value adds interactivity to web content that matches the value."),
        trailing: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width / 2),
          child: Text(currentWebViewModel.options.ios.dataDetectorTypes.map((e) => e.toString()).join(", ")),
        ),
        onTap: () async {
          final dataDetectoryTypesSelected = await showDialog<Set<IOSWKDataDetectorTypes>>(
            context: context,
            builder: (BuildContext context) {
              return MultiSelectDialog(
                title: const Text("Data Detector Types"),
                items: IOSWKDataDetectorTypes.values.map((dataDetectoryType) {
                  return MultiSelectDialogItem<IOSWKDataDetectorTypes>(
                    value: dataDetectoryType,
                    label: dataDetectoryType.toString()
                  );
                }).toList(),
                initialSelectedValues: currentWebViewModel.options.ios.dataDetectorTypes.toSet(),
              );
            },
          );
          if (dataDetectoryTypesSelected != null) {
            currentWebViewModel.options.ios.dataDetectorTypes = dataDetectoryTypesSelected.toList();
            _webViewController.setOptions(options: currentWebViewModel.options);
            browserModel.save();
            setState(() {});
          }
        },
      ),
      SwitchListTile(
        title: const Text("Shared Cookies Enabled"),
        subtitle: const Text(
            "Sets if shared cookies from \"HTTPCookieStorage.shared\" should used for every load request in the WebView."),
        value: currentWebViewModel.options.ios.sharedCookiesEnabled,
        onChanged: (value) {
          currentWebViewModel.options.ios.sharedCookiesEnabled =
              value;
          _webViewController.setOptions(options: currentWebViewModel.options);
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Automatically Adjusts Scroll Indicator Insets"),
        subtitle: const Text(
            "Configures whether the scroll indicator insets are automatically adjusted by the system."),
        value: currentWebViewModel.options.ios.automaticallyAdjustsScrollIndicatorInsets,
        onChanged: (value) {
          currentWebViewModel.options.ios.automaticallyAdjustsScrollIndicatorInsets =
              value;
          _webViewController.setOptions(options: currentWebViewModel.options);
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Accessibility Ignores Invert Colors"),
        subtitle: const Text(
            "Sets whether the WebView ignores an accessibility request to invert its colors."),
        value: currentWebViewModel.options.ios.accessibilityIgnoresInvertColors,
        onChanged: (value) {
          currentWebViewModel.options.ios.accessibilityIgnoresInvertColors =
              value;
          _webViewController.setOptions(options: currentWebViewModel.options);
          browserModel.save();
          setState(() {});
        },
      ),
      ListTile(
        title: const Text("Deceleration Rate"),
        subtitle: const Text(
            "Determines the rate of deceleration after the user lifts their finger."),
        trailing: DropdownButton<IOSUIScrollViewDecelerationRate>(
          hint: Text("Deceleration"),
          onChanged: (value) {
            currentWebViewModel.options.ios.decelerationRate = value;
            _webViewController.setOptions(options: currentWebViewModel.options);
            browserModel.save();
            setState(() {});
          },
          value: currentWebViewModel.options.ios.decelerationRate,
          items: IOSUIScrollViewDecelerationRate.values.map((decelerationRate) {
            return DropdownMenuItem<IOSUIScrollViewDecelerationRate>(
              value: decelerationRate,
              child: Text(
                decelerationRate.toString(),
                style: TextStyle(fontSize: 12.5),
              ),
            );
          }).toList(),
        ),
      ),
      SwitchListTile(
        title: const Text("Always Bounce Vertical"),
        subtitle: const Text(
            "Determines whether bouncing always occurs when vertical scrolling reaches the end of the content."),
        value: currentWebViewModel.options.ios.alwaysBounceVertical,
        onChanged: (value) {
          currentWebViewModel.options.ios.alwaysBounceVertical =
              value;
          _webViewController.setOptions(options: currentWebViewModel.options);
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Always Bounce Horizontal"),
        subtitle: const Text(
            "Determines whether bouncing always occurs when horizontal scrolling reaches the end of the content view."),
        value: currentWebViewModel.options.ios.alwaysBounceHorizontal,
        onChanged: (value) {
          currentWebViewModel.options.ios.alwaysBounceHorizontal =
              value;
          _webViewController.setOptions(options: currentWebViewModel.options);
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Scrolls To Top"),
        subtitle: const Text(
            "Sets whether the scroll-to-top gesture is enabled."),
        value: currentWebViewModel.options.ios.scrollsToTop,
        onChanged: (value) {
          currentWebViewModel.options.ios.scrollsToTop =
              value;
          _webViewController.setOptions(options: currentWebViewModel.options);
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Is Paging Enabled"),
        subtitle: const Text(
            "Determines whether paging is enabled for the scroll view."),
        value: currentWebViewModel.options.ios.isPagingEnabled,
        onChanged: (value) {
          currentWebViewModel.options.ios.isPagingEnabled =
              value;
          _webViewController.setOptions(options: currentWebViewModel.options);
          browserModel.save();
          setState(() {});
        },
      ),
      ListTile(
        title: const Text("Maximum Zoom Scale"),
        subtitle: const Text("A floating-point value that specifies the maximum scale factor that can be applied to the scroll view's content."),
        trailing: Container(
          width: 50.0,
          child: TextFormField(
            initialValue: currentWebViewModel
                .options.ios.maximumZoomScale
                .toString(),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            onFieldSubmitted: (value) {
              currentWebViewModel.options.ios.maximumZoomScale =
                  double.parse(value);
              _webViewController.setOptions(
                  options: currentWebViewModel.options);
              browserModel.save();
              setState(() {});
            },
          ),
        ),
      ),
      ListTile(
        title: const Text("Minimum Zoom Scale"),
        subtitle: const Text("A floating-point value that specifies the minimum scale factor that can be applied to the scroll view's content."),
        trailing: Container(
          width: 50.0,
          child: TextFormField(
            initialValue: currentWebViewModel
                .options.ios.minimumZoomScale
                .toString(),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            onFieldSubmitted: (value) {
              currentWebViewModel.options.ios.minimumZoomScale =
                  double.parse(value);
              _webViewController.setOptions(
                  options: currentWebViewModel.options);
              browserModel.save();
              setState(() {});
            },
          ),
        ),
      ),
      ListTile(
        title: const Text("Content Inset Adjustment Behavior"),
        subtitle: const Text(
            "Configures how safe area insets are added to the adjusted content inset."),
        trailing: DropdownButton<IOSUIScrollViewContentInsetAdjustmentBehavior>(
          onChanged: (value) {
            currentWebViewModel.options.ios.contentInsetAdjustmentBehavior = value;
            _webViewController.setOptions(options: currentWebViewModel.options);
            browserModel.save();
            setState(() {});
          },
          value: currentWebViewModel.options.ios.contentInsetAdjustmentBehavior,
          items: IOSUIScrollViewContentInsetAdjustmentBehavior.values.map((decelerationRate) {
            return DropdownMenuItem<IOSUIScrollViewContentInsetAdjustmentBehavior>(
              value: decelerationRate,
              child: Text(
                decelerationRate.toString(),
                style: TextStyle(fontSize: 12.5),
              ),
            );
          }).toList(),
        ),
      ),
    ];

    return widgets;
  }
}
