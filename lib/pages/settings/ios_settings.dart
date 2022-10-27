import 'package:flutter/material.dart';
import 'package:flutter_browser/models/browser_model.dart';
import 'package:flutter_browser/models/webview_model.dart';
import 'package:flutter_browser/multiselect_dialog.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
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
        value: currentWebViewModel.settings?.disallowOverScroll ?? false,
        onChanged: (value) {
          currentWebViewModel.settings?.disallowOverScroll = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Enable Viewport Scale"),
        subtitle: const Text(
            "Enable to allow a viewport meta tag to either disable or restrict the range of user scaling."),
        value: currentWebViewModel.settings?.enableViewportScale ?? false,
        onChanged: (value) {
          currentWebViewModel.settings?.enableViewportScale = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Suppresses Incremental Rendering"),
        subtitle: const Text(
            "Sets wheter the WebView should suppresses content rendering until it is fully loaded into memory."),
        value: currentWebViewModel.settings?.suppressesIncrementalRendering ??
            false,
        onChanged: (value) {
          currentWebViewModel.settings?.suppressesIncrementalRendering = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Allows Air Play For Media Playback"),
        subtitle: const Text("Enable AirPlay."),
        value:
            currentWebViewModel.settings?.allowsAirPlayForMediaPlayback ?? true,
        onChanged: (value) {
          currentWebViewModel.settings?.allowsAirPlayForMediaPlayback = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Allows Back Forward Navigation Gestures"),
        subtitle: const Text(
            "Enable to allow the horizontal swipe gestures trigger back-forward list navigations."),
        value:
            currentWebViewModel.settings?.allowsBackForwardNavigationGestures ??
                true,
        onChanged: (value) {
          currentWebViewModel.settings?.allowsBackForwardNavigationGestures =
              value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Ignores Viewport Scale Limits"),
        subtitle: const Text(
            "Sets whether the WebView should always allow scaling of the webpage, regardless of the author's intent."),
        value:
            currentWebViewModel.settings?.ignoresViewportScaleLimits ?? false,
        onChanged: (value) {
          currentWebViewModel.settings?.ignoresViewportScaleLimits = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Allows Inline Media Playback"),
        subtitle: const Text(
            "Enable to allow HTML5 media playback to appear inline within the screen layout, using browser-supplied controls rather than native controls."),
        value: currentWebViewModel.settings?.allowsInlineMediaPlayback ?? false,
        onChanged: (value) {
          currentWebViewModel.settings?.allowsInlineMediaPlayback = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Allows Picture In Picture Media Playback"),
        subtitle:
            const Text("Enable to allow HTML5 videos play picture-in-picture."),
        value:
            currentWebViewModel.settings?.allowsPictureInPictureMediaPlayback ??
                true,
        onChanged: (value) {
          currentWebViewModel.settings?.allowsPictureInPictureMediaPlayback =
              value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          browserModel.save();
          setState(() {});
        },
      ),
      ListTile(
        title: const Text("Selection Granularity"),
        subtitle: const Text(
            "Sets the level of granularity with which the user can interactively select content in the web view."),
        trailing: DropdownButton<SelectionGranularity>(
          hint: const Text("Granularity"),
          onChanged: (value) {
            currentWebViewModel.settings?.selectionGranularity = value!;
            webViewController?.setSettings(
                settings:
                    currentWebViewModel.settings ?? InAppWebViewSettings());
            browserModel.save();
            setState(() {});
          },
          value: currentWebViewModel.settings?.selectionGranularity,
          items: SelectionGranularity.values.map((selectionGranularity) {
            return DropdownMenuItem<SelectionGranularity>(
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
          child: Text(currentWebViewModel.settings?.dataDetectorTypes
                  ?.map((e) => e.toString())
                  .join(", ") ??
              ""),
        ),
        onTap: () async {
          final dataDetectoryTypesSelected =
              await showDialog<Set<DataDetectorTypes>>(
            context: context,
            builder: (BuildContext context) {
              return MultiSelectDialog(
                title: const Text("Data Detector Types"),
                items: DataDetectorTypes.values.map((dataDetectorType) {
                  return MultiSelectDialogItem<DataDetectorTypes>(
                      value: dataDetectorType,
                      label: dataDetectorType.toString());
                }).toList(),
                initialSelectedValues:
                    currentWebViewModel.settings?.dataDetectorTypes?.toSet(),
              );
            },
          );
          if (dataDetectoryTypesSelected != null) {
            currentWebViewModel.settings?.dataDetectorTypes =
                dataDetectoryTypesSelected.toList();
            webViewController?.setSettings(
                settings:
                    currentWebViewModel.settings ?? InAppWebViewSettings());
            browserModel.save();
            setState(() {});
          }
        },
      ),
      SwitchListTile(
        title: const Text("Shared Cookies Enabled"),
        subtitle: const Text(
            "Sets if shared cookies from \"HTTPCookieStorage.shared\" should used for every load request in the WebView."),
        value: currentWebViewModel.settings?.sharedCookiesEnabled ?? false,
        onChanged: (value) {
          currentWebViewModel.settings?.sharedCookiesEnabled = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Automatically Adjusts Scroll Indicator Insets"),
        subtitle: const Text(
            "Configures whether the scroll indicator insets are automatically adjusted by the system."),
        value: currentWebViewModel
                .settings?.automaticallyAdjustsScrollIndicatorInsets ??
            false,
        onChanged: (value) {
          currentWebViewModel
              .settings?.automaticallyAdjustsScrollIndicatorInsets = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Accessibility Ignores Invert Colors"),
        subtitle: const Text(
            "Sets whether the WebView ignores an accessibility request to invert its colors."),
        value: currentWebViewModel.settings?.accessibilityIgnoresInvertColors ??
            false,
        onChanged: (value) {
          currentWebViewModel.settings?.accessibilityIgnoresInvertColors =
              value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          browserModel.save();
          setState(() {});
        },
      ),
      ListTile(
        title: const Text("Deceleration Rate"),
        subtitle: const Text(
            "Determines the rate of deceleration after the user lifts their finger."),
        trailing: DropdownButton<ScrollViewDecelerationRate>(
          hint: const Text("Deceleration"),
          onChanged: (value) {
            currentWebViewModel.settings?.decelerationRate = value!;
            webViewController?.setSettings(
                settings:
                    currentWebViewModel.settings ?? InAppWebViewSettings());
            browserModel.save();
            setState(() {});
          },
          value: currentWebViewModel.settings?.decelerationRate,
          items: ScrollViewDecelerationRate.values.map((decelerationRate) {
            return DropdownMenuItem<ScrollViewDecelerationRate>(
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
        value: currentWebViewModel.settings?.alwaysBounceVertical ?? false,
        onChanged: (value) {
          currentWebViewModel.settings?.alwaysBounceVertical = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Always Bounce Horizontal"),
        subtitle: const Text(
            "Determines whether bouncing always occurs when horizontal scrolling reaches the end of the content view."),
        value: currentWebViewModel.settings?.alwaysBounceHorizontal ?? false,
        onChanged: (value) {
          currentWebViewModel.settings?.alwaysBounceHorizontal = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Scrolls To Top"),
        subtitle:
            const Text("Sets whether the scroll-to-top gesture is enabled."),
        value: currentWebViewModel.settings?.scrollsToTop ?? true,
        onChanged: (value) {
          currentWebViewModel.settings?.scrollsToTop = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Is Paging Enabled"),
        subtitle: const Text(
            "Determines whether paging is enabled for the scroll view."),
        value: currentWebViewModel.settings?.isPagingEnabled ?? false,
        onChanged: (value) {
          currentWebViewModel.settings?.isPagingEnabled = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
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
                currentWebViewModel.settings?.maximumZoomScale.toString(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onFieldSubmitted: (value) {
              currentWebViewModel.settings?.maximumZoomScale =
                  double.parse(value);
              webViewController?.setSettings(
                  settings:
                      currentWebViewModel.settings ?? InAppWebViewSettings());
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
                currentWebViewModel.settings?.minimumZoomScale.toString(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onFieldSubmitted: (value) {
              currentWebViewModel.settings?.minimumZoomScale =
                  double.parse(value);
              webViewController?.setSettings(
                  settings:
                      currentWebViewModel.settings ?? InAppWebViewSettings());
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
        trailing: DropdownButton<ScrollViewContentInsetAdjustmentBehavior>(
          onChanged: (value) {
            currentWebViewModel.settings?.contentInsetAdjustmentBehavior =
                value!;
            webViewController?.setSettings(
                settings:
                    currentWebViewModel.settings ?? InAppWebViewSettings());
            browserModel.save();
            setState(() {});
          },
          value: currentWebViewModel.settings?.contentInsetAdjustmentBehavior,
          items: ScrollViewContentInsetAdjustmentBehavior.values
              .map((decelerationRate) {
            return DropdownMenuItem<ScrollViewContentInsetAdjustmentBehavior>(
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
        value: currentWebViewModel.settings?.isDirectionalLockEnabled ?? false,
        onChanged: (value) {
          currentWebViewModel.settings?.isDirectionalLockEnabled = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
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
            initialValue: currentWebViewModel.settings?.mediaType?.toString(),
            onFieldSubmitted: (value) {
              currentWebViewModel.settings?.mediaType =
                  value.isNotEmpty ? value : null;
              webViewController?.setSettings(
                  settings:
                      currentWebViewModel.settings ?? InAppWebViewSettings());
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
            initialValue: currentWebViewModel.settings?.pageZoom.toString(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onFieldSubmitted: (value) {
              currentWebViewModel.settings?.pageZoom = double.parse(value);
              webViewController?.setSettings(
                  settings:
                      currentWebViewModel.settings ?? InAppWebViewSettings());
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
        value: currentWebViewModel.settings?.applePayAPIEnabled ?? false,
        onChanged: (value) {
          currentWebViewModel.settings?.applePayAPIEnabled = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          browserModel.save();
          setState(() {});
        },
      ),
      ListTile(
        title: const Text("Under Page Background Color"),
        subtitle: const Text("Sets the color the web view displays behind the active page, visible when the user scrolls beyond the bounds of the page."),
        trailing: SizedBox(
            width: 140.0,
            child: ElevatedButton(
              child: Text(
                currentWebViewModel.settings?.underPageBackgroundColor
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
                                ?.underPageBackgroundColor = value;
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
      SwitchListTile(
        title: const Text("Text Interaction Enabled"),
        subtitle: const Text(
            "Indicates whether text interaction is enabled or not."),
        value: currentWebViewModel.settings?.isTextInteractionEnabled ?? false,
        onChanged: (value) {
          currentWebViewModel.settings?.isTextInteractionEnabled = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Site Specific Quirks Mode Enabled"),
        subtitle: const Text(
            "Indicates whether WebKit will apply built-in workarounds (quirks) to improve compatibility with certain known websites. You can disable site-specific quirks to help test your website without these workarounds."),
        value: currentWebViewModel.settings?.isSiteSpecificQuirksModeEnabled ?? false,
        onChanged: (value) {
          currentWebViewModel.settings?.isSiteSpecificQuirksModeEnabled = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Upgrade Known Hosts To HTTPS"),
        subtitle: const Text(
            "Indicates whether HTTP requests to servers known to support HTTPS should be automatically upgraded to HTTPS requests."),
        value: currentWebViewModel.settings?.upgradeKnownHostsToHTTPS ?? false,
        onChanged: (value) {
          currentWebViewModel.settings?.upgradeKnownHostsToHTTPS = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Element Fullscreen Enabled"),
        subtitle: const Text(
            "Indicates whether fullscreen API is enabled or not."),
        value: currentWebViewModel.settings?.isElementFullscreenEnabled ?? false,
        onChanged: (value) {
          currentWebViewModel.settings?.isElementFullscreenEnabled = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          browserModel.save();
          setState(() {});
        },
      ),
      SwitchListTile(
        title: const Text("Find Interaction Enabled"),
        subtitle: const Text(
            "Indicates whether the web view's built-in find interaction native UI is enabled or not."),
        value: currentWebViewModel.settings?.isFindInteractionEnabled ?? false,
        onChanged: (value) {
          currentWebViewModel.settings?.isFindInteractionEnabled = value;
          webViewController?.setSettings(
              settings: currentWebViewModel.settings ?? InAppWebViewSettings());
          browserModel.save();
          setState(() {});
        },
      ),
    ];

    return widgets;
  }
}
