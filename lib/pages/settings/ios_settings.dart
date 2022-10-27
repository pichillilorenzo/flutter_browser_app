import 'package:flutter/material.dart';
import 'package:flutter_browser/models/browser_model.dart';
import 'package:flutter_browser/models/webview_model.dart';
import 'package:flutter_browser/multiselect_dialog.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

class IOSSettings extends StatefulWidget {
  const IOSSettings({Key? key}) : super(key: key);

  @override
  State<IOSSettings> createState() => _IOSSettingsState();
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
    if (browserModel.webViewTabs.isEmpty) {
      return [];
    }
    var currentWebViewModel = Provider.of<WebViewModel>(context, listen: true);
    var webViewController = currentWebViewModel.webViewController;

    var widgets = <Widget>[
      const ListTile(
        title: Text("Current WebView iOS Settings"),
        enabled: false,
      ),
      SwitchListTile(
        title: const Text("Disallow Over Scroll"),
        subtitle: const Text(
            "Sets whether the WebView should bounce when the scrolling has reached an edge of the content"),
        value: currentWebViewModel.options?.ios.disallowOverScroll ?? false,
        onChanged: (value) {
          currentWebViewModel.options?.ios.disallowOverScroll = value;
          webViewController?.setOptions(
              options:
                  currentWebViewModel.options ?? InAppWebViewGroupOptions());
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Enable Viewport Scale"),
        subtitle: const Text(
            "Enable to allow a viewport meta tag to either disable or restrict the range of user scaling."),
        value: currentWebViewModel.options?.ios.enableViewportScale ?? false,
        onChanged: (value) {
          currentWebViewModel.options?.ios.enableViewportScale = value;
          webViewController?.setOptions(
              options:
                  currentWebViewModel.options ?? InAppWebViewGroupOptions());
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Suppresses Incremental Rendering"),
        subtitle: const Text(
            "Sets wheter the WebView should suppresses content rendering until it is fully loaded into memory."),
        value:
            currentWebViewModel.options?.ios.suppressesIncrementalRendering ??
                false,
        onChanged: (value) {
          currentWebViewModel.options?.ios.suppressesIncrementalRendering =
              value;
          webViewController?.setOptions(
              options:
                  currentWebViewModel.options ?? InAppWebViewGroupOptions());
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Allows Air Play For Media Playback"),
        subtitle: const Text("Enable AirPlay."),
        value: currentWebViewModel.options?.ios.allowsAirPlayForMediaPlayback ??
            true,
        onChanged: (value) {
          currentWebViewModel.options?.ios.allowsAirPlayForMediaPlayback =
              value;
          webViewController?.setOptions(
              options:
                  currentWebViewModel.options ?? InAppWebViewGroupOptions());
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Allows Back Forward Navigation Gestures"),
        subtitle: const Text(
            "Enable to allow the horizontal swipe gestures trigger back-forward list navigations."),
        value: currentWebViewModel
                .options?.ios.allowsBackForwardNavigationGestures ??
            true,
        onChanged: (value) {
          currentWebViewModel.options?.ios.allowsBackForwardNavigationGestures =
              value;
          webViewController?.setOptions(
              options:
                  currentWebViewModel.options ?? InAppWebViewGroupOptions());
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Ignores Viewport Scale Limits"),
        subtitle: const Text(
            "Sets whether the WebView should always allow scaling of the webpage, regardless of the author's intent."),
        value: currentWebViewModel.options?.ios.ignoresViewportScaleLimits ??
            false,
        onChanged: (value) {
          currentWebViewModel.options?.ios.ignoresViewportScaleLimits = value;
          webViewController?.setOptions(
              options:
                  currentWebViewModel.options ?? InAppWebViewGroupOptions());
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Allows Inline Media Playback"),
        subtitle: const Text(
            "Enable to allow HTML5 media playback to appear inline within the screen layout, using browser-supplied controls rather than native controls."),
        value:
            currentWebViewModel.options?.ios.allowsInlineMediaPlayback ?? false,
        onChanged: (value) {
          currentWebViewModel.options?.ios.allowsInlineMediaPlayback = value;
          webViewController?.setOptions(
              options:
                  currentWebViewModel.options ?? InAppWebViewGroupOptions());
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Allows Picture In Picture Media Playback"),
        subtitle:
            const Text("Enable to allow HTML5 videos play picture-in-picture."),
        value: currentWebViewModel
                .options?.ios.allowsPictureInPictureMediaPlayback ??
            true,
        onChanged: (value) {
          currentWebViewModel.options?.ios.allowsPictureInPictureMediaPlayback =
              value;
          webViewController?.setOptions(
              options:
                  currentWebViewModel.options ?? InAppWebViewGroupOptions());
          browserModel.save();
          setState(() {});
        },
      ),
      ListTile(
        title: const Text("Selection Granularity"),
        subtitle: const Text(
            "Sets the level of granularity with which the user can interactively select content in the web view."),
        trailing: DropdownButton<IOSWKSelectionGranularity>(
          hint: const Text("Granularity"),
          onChanged: (value) {
            currentWebViewModel.options?.ios.selectionGranularity = value!;
            webViewController?.setOptions(
                options:
                    currentWebViewModel.options ?? InAppWebViewGroupOptions());
            browserModel.save();
            setState(() {});
          },
          value: currentWebViewModel.options?.ios.selectionGranularity,
          items: IOSWKSelectionGranularity.values.map((selectionGranularity) {
            return DropdownMenuItem<IOSWKSelectionGranularity>(
              value: selectionGranularity,
              child: Text(
                selectionGranularity.toString(),
                style: const TextStyle(fontSize: 12.5),
              ),
            );
          }).toList(),
        ),
      ),
      ListTile(
        title: const Text("Data Detector Types"),
        subtitle: const Text(
            "Specifying a dataDetectoryTypes value adds interactivity to web content that matches the value."),
        trailing: Container(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width / 2),
          child: Text(currentWebViewModel.options?.ios.dataDetectorTypes
                  .map((e) => e.toString())
                  .join(", ") ??
              ""),
        ),
        onTap: () async {
          final dataDetectoryTypesSelected =
              await showDialog<Set<IOSWKDataDetectorTypes>>(
            context: context,
            builder: (BuildContext context) {
              return MultiSelectDialog(
                title: const Text("Data Detector Types"),
                items: IOSWKDataDetectorTypes.values.map((dataDetectorType) {
                  return MultiSelectDialogItem<IOSWKDataDetectorTypes>(
                      value: dataDetectorType,
                      label: dataDetectorType.toString());
                }).toList(),
                initialSelectedValues:
                    currentWebViewModel.options?.ios.dataDetectorTypes.toSet(),
              );
            },
          );
          if (dataDetectoryTypesSelected != null) {
            currentWebViewModel.options?.ios.dataDetectorTypes =
                dataDetectoryTypesSelected.toList();
            webViewController?.setOptions(
                options:
                    currentWebViewModel.options ?? InAppWebViewGroupOptions());
            browserModel.save();
            setState(() {});
          }
        },
      ),
      SwitchListTile(
        title: const Text("Shared Cookies Enabled"),
        subtitle: const Text(
            "Sets if shared cookies from \"HTTPCookieStorage.shared\" should used for every load request in the WebView."),
        value: currentWebViewModel.options?.ios.sharedCookiesEnabled ?? false,
        onChanged: (value) {
          currentWebViewModel.options?.ios.sharedCookiesEnabled = value;
          webViewController?.setOptions(
              options:
                  currentWebViewModel.options ?? InAppWebViewGroupOptions());
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Automatically Adjusts Scroll Indicator Insets"),
        subtitle: const Text(
            "Configures whether the scroll indicator insets are automatically adjusted by the system."),
        value: currentWebViewModel
                .options?.ios.automaticallyAdjustsScrollIndicatorInsets ??
            false,
        onChanged: (value) {
          currentWebViewModel
              .options?.ios.automaticallyAdjustsScrollIndicatorInsets = value;
          webViewController?.setOptions(
              options:
                  currentWebViewModel.options ?? InAppWebViewGroupOptions());
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Accessibility Ignores Invert Colors"),
        subtitle: const Text(
            "Sets whether the WebView ignores an accessibility request to invert its colors."),
        value:
            currentWebViewModel.options?.ios.accessibilityIgnoresInvertColors ??
                false,
        onChanged: (value) {
          currentWebViewModel.options?.ios.accessibilityIgnoresInvertColors =
              value;
          webViewController?.setOptions(
              options:
                  currentWebViewModel.options ?? InAppWebViewGroupOptions());
          browserModel.save();
          setState(() {});
        },
      ),
      ListTile(
        title: const Text("Deceleration Rate"),
        subtitle: const Text(
            "Determines the rate of deceleration after the user lifts their finger."),
        trailing: DropdownButton<IOSUIScrollViewDecelerationRate>(
          hint: const Text("Deceleration"),
          onChanged: (value) {
            currentWebViewModel.options?.ios.decelerationRate = value!;
            webViewController?.setOptions(
                options:
                    currentWebViewModel.options ?? InAppWebViewGroupOptions());
            browserModel.save();
            setState(() {});
          },
          value: currentWebViewModel.options?.ios.decelerationRate,
          items: IOSUIScrollViewDecelerationRate.values.map((decelerationRate) {
            return DropdownMenuItem<IOSUIScrollViewDecelerationRate>(
              value: decelerationRate,
              child: Text(
                decelerationRate.toString(),
                style: const TextStyle(fontSize: 12.5),
              ),
            );
          }).toList(),
        ),
      ),
      SwitchListTile(
        title: const Text("Always Bounce Vertical"),
        subtitle: const Text(
            "Determines whether bouncing always occurs when vertical scrolling reaches the end of the content."),
        value: currentWebViewModel.options?.ios.alwaysBounceVertical ?? false,
        onChanged: (value) {
          currentWebViewModel.options?.ios.alwaysBounceVertical = value;
          webViewController?.setOptions(
              options:
                  currentWebViewModel.options ?? InAppWebViewGroupOptions());
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Always Bounce Horizontal"),
        subtitle: const Text(
            "Determines whether bouncing always occurs when horizontal scrolling reaches the end of the content view."),
        value: currentWebViewModel.options?.ios.alwaysBounceHorizontal ?? false,
        onChanged: (value) {
          currentWebViewModel.options?.ios.alwaysBounceHorizontal = value;
          webViewController?.setOptions(
              options:
                  currentWebViewModel.options ?? InAppWebViewGroupOptions());
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Scrolls To Top"),
        subtitle:
            const Text("Sets whether the scroll-to-top gesture is enabled."),
        value: currentWebViewModel.options?.ios.scrollsToTop ?? true,
        onChanged: (value) {
          currentWebViewModel.options?.ios.scrollsToTop = value;
          webViewController?.setOptions(
              options:
                  currentWebViewModel.options ?? InAppWebViewGroupOptions());
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Is Paging Enabled"),
        subtitle: const Text(
            "Determines whether paging is enabled for the scroll view."),
        value: currentWebViewModel.options?.ios.isPagingEnabled ?? false,
        onChanged: (value) {
          currentWebViewModel.options?.ios.isPagingEnabled = value;
          webViewController?.setOptions(
              options:
                  currentWebViewModel.options ?? InAppWebViewGroupOptions());
          browserModel.save();
          setState(() {});
        },
      ),
      ListTile(
        title: const Text("Maximum Zoom Scale"),
        subtitle: const Text(
            "A floating-point value that specifies the maximum scale factor that can be applied to the scroll view's content."),
        trailing: SizedBox(
          width: 50.0,
          child: TextFormField(
            initialValue:
                currentWebViewModel.options?.ios.maximumZoomScale.toString(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onFieldSubmitted: (value) {
              currentWebViewModel.options?.ios.maximumZoomScale =
                  double.parse(value);
              webViewController?.setOptions(
                  options: currentWebViewModel.options ??
                      InAppWebViewGroupOptions());
              browserModel.save();
              setState(() {});
            },
          ),
        ),
      ),
      ListTile(
        title: const Text("Minimum Zoom Scale"),
        subtitle: const Text(
            "A floating-point value that specifies the minimum scale factor that can be applied to the scroll view's content."),
        trailing: SizedBox(
          width: 50.0,
          child: TextFormField(
            initialValue:
                currentWebViewModel.options?.ios.minimumZoomScale.toString(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onFieldSubmitted: (value) {
              currentWebViewModel.options?.ios.minimumZoomScale =
                  double.parse(value);
              webViewController?.setOptions(
                  options: currentWebViewModel.options ??
                      InAppWebViewGroupOptions());
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
            currentWebViewModel.options?.ios.contentInsetAdjustmentBehavior =
                value!;
            webViewController?.setOptions(
                options:
                    currentWebViewModel.options ?? InAppWebViewGroupOptions());
            browserModel.save();
            setState(() {});
          },
          value:
              currentWebViewModel.options?.ios.contentInsetAdjustmentBehavior,
          items: IOSUIScrollViewContentInsetAdjustmentBehavior.values
              .map((decelerationRate) {
            return DropdownMenuItem<
                IOSUIScrollViewContentInsetAdjustmentBehavior>(
              value: decelerationRate,
              child: Text(
                decelerationRate.toString(),
                style: const TextStyle(fontSize: 12.5),
              ),
            );
          }).toList(),
        ),
      ),
      SwitchListTile(
        title: const Text("Is Directional Lock Enabled"),
        subtitle: const Text(
            "A Boolean value that determines whether scrolling is disabled in a particular direction."),
        value:
            currentWebViewModel.options?.ios.isDirectionalLockEnabled ?? false,
        onChanged: (value) {
          currentWebViewModel.options?.ios.isDirectionalLockEnabled = value;
          webViewController?.setOptions(
              options:
                  currentWebViewModel.options ?? InAppWebViewGroupOptions());
          browserModel.save();
          setState(() {});
        },
      ),
      ListTile(
        title: const Text("Media Type"),
        subtitle:
            const Text("The media type for the contents of the web view."),
        trailing: SizedBox(
          width: 100.0,
          child: TextFormField(
            initialValue:
                currentWebViewModel.options?.ios.mediaType?.toString(),
            onFieldSubmitted: (value) {
              currentWebViewModel.options?.ios.mediaType =
                  value.isNotEmpty ? value : null;
              webViewController?.setOptions(
                  options: currentWebViewModel.options ??
                      InAppWebViewGroupOptions());
              browserModel.save();
              setState(() {});
            },
          ),
        ),
      ),
      ListTile(
        title: const Text("Page Zoom"),
        subtitle: const Text(
            "The scale factor by which the web view scales content relative to its bounds."),
        trailing: SizedBox(
          width: 50.0,
          child: TextFormField(
            initialValue: currentWebViewModel.options?.ios.pageZoom.toString(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onFieldSubmitted: (value) {
              currentWebViewModel.options?.ios.pageZoom = double.parse(value);
              webViewController?.setOptions(
                  options: currentWebViewModel.options ??
                      InAppWebViewGroupOptions());
              browserModel.save();
              setState(() {});
            },
          ),
        ),
      ),
      SwitchListTile(
        title: const Text("Apple Pay API Enabled"),
        subtitle: const Text(
            "Indicates if Apple Pay API should be enabled on the next page load (JavaScript won't work)."),
        value: currentWebViewModel.options?.ios.applePayAPIEnabled ?? false,
        onChanged: (value) {
          currentWebViewModel.options?.ios.applePayAPIEnabled = value;
          webViewController?.setOptions(
              options:
                  currentWebViewModel.options ?? InAppWebViewGroupOptions());
          browserModel.save();
          setState(() {});
        },
      ),
    ];

    return widgets;
  }
}
