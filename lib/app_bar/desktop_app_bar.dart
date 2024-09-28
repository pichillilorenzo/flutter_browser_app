import 'package:context_menus/context_menus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../custom_image.dart';
import '../models/browser_model.dart';
import '../models/webview_model.dart';
import '../util.dart';
import '../webview_tab.dart';

class DesktopAppBar extends StatefulWidget {
  const DesktopAppBar({super.key});

  @override
  State<DesktopAppBar> createState() => _DesktopAppBarState();
}

class _DesktopAppBarState extends State<DesktopAppBar> {
  @override
  Widget build(BuildContext context) {
    final browserModel = Provider.of<BrowserModel>(context, listen: true);

    final tabSelectors = browserModel.webViewTabs.map((webViewTab) {
      final index = browserModel.webViewTabs.indexOf(webViewTab);
      final currentIndex = browserModel.getCurrentTabIndex();

      return Flexible(
          flex: 1,
          fit: FlexFit.loose,
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                    child: WebViewTabSelector(tab: webViewTab, index: index)),
                SizedBox(
                  height: 15,
                  child: VerticalDivider(
                      thickness: 1,
                      width: 1,
                      color: index == currentIndex - 1 || index == currentIndex
                          ? Colors.transparent
                          : Colors.black45),
                )
              ],
            ),
          ));
    }).toList();

    final windowActions = [];
    if (!Util.isWindows()) {
      windowActions.addAll([
        const SizedBox(
          width: 8,
        ),
        IconButton(
            onPressed: () {
              windowManager.close();
            },
            constraints: const BoxConstraints(
              maxWidth: 13,
              minWidth: 13,
              maxHeight: 13,
              minHeight: 13,
            ),
            padding: EdgeInsets.zero,
            style: ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: const WidgetStatePropertyAll(Colors.red),
                iconColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.hovered)
                      ? Colors.black45
                      : Colors.red,
                )),
            color: Colors.red,
            icon: const Icon(
              Icons.close,
              size: 10,
            )),
        const SizedBox(
          width: 8,
        ),
        IconButton(
            onPressed: () async {
              if (!(await windowManager.isFullScreen())) {
                windowManager.minimize();
              }
            },
            constraints: const BoxConstraints(
              maxWidth: 13,
              minWidth: 13,
              maxHeight: 13,
              minHeight: 13,
            ),
            padding: EdgeInsets.zero,
            style: ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor:
                const WidgetStatePropertyAll(Colors.amber),
                iconColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.hovered)
                      ? Colors.black45
                      : Colors.amber,
                )),
            color: Colors.amber,
            icon: const Icon(
              Icons.remove,
              size: 10,
            )),
        const SizedBox(
          width: 8,
        ),
        IconButton(
            onPressed: () async {
              windowManager
                  .setFullScreen(!(await windowManager.isFullScreen()));
            },
            constraints: const BoxConstraints(
              maxWidth: 13,
              minWidth: 13,
              maxHeight: 13,
              minHeight: 13,
            ),
            padding: EdgeInsets.zero,
            style: ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor:
                const WidgetStatePropertyAll(Colors.green),
                iconColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.hovered)
                      ? Colors.black45
                      : Colors.green,
                )),
            color: Colors.green,
            icon: const Icon(
              Icons.open_in_full,
              size: 10,
            )),
        const SizedBox(
          width: 8,
        ),
      ]);
    }

    final children = [
      Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 100),
        child: IntrinsicWidth(
          child: Row(
            children: [
              ...windowActions,
              Flexible(
                  child: Container(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: tabSelectors.isNotEmpty
                      ? tabSelectors
                      : [
                          const SizedBox(
                            height: 30,
                          )
                        ],
                ),
              )),
              const SizedBox(
                width: 5,
              ),
              IconButton(
                  onPressed: () {
                    _addNewTab();
                  },
                  constraints: const BoxConstraints(
                    maxWidth: 25,
                    minWidth: 25,
                    maxHeight: 25,
                    minHeight: 25,
                  ),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.add, size: 15)),
            ],
          ),
        ),
      ),
      Flexible(
          child: MouseRegion(
              hitTestBehavior: HitTestBehavior.opaque,
              onEnter: (details) {
                if (!Util.isWindows()) {
                  windowManager.setMovable(true);
                }
              },
              onExit: (details) {
                if (!Util.isWindows()) {
                  windowManager.setMovable(false);
                }
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onDoubleTap: () async {
                  windowManager.maximize();
                },
                child: ContextMenuRegion(
                    behavior: const [ContextMenuShowBehavior.secondaryTap],
                    contextMenu: GenericContextMenu(
                      buttonConfigs: [
                        ContextMenuButtonConfig(
                          "New Tab",
                          onPressed: () {
                            _addNewTab();
                          },
                        ),
                        ContextMenuButtonConfig(
                          "Close All",
                          onPressed: () {
                            browserModel.closeAllTabs();
                          },
                        ),
                      ],
                    ),
                    child: const SizedBox(
                      height: 30,
                      width: double.infinity,
                    )),
              ))),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: children,
    );
  }

  void _addNewTab() {
    final browserModel = Provider.of<BrowserModel>(context, listen: false);
    final settings = browserModel.getSettings();
    browserModel.addTab(WebViewTab(
      key: GlobalKey(),
      webViewModel: WebViewModel(url: WebUri(settings.searchEngine.url)),
    ));
  }
}

class WebViewTabSelector extends StatefulWidget {
  final WebViewTab tab;
  final int index;

  const WebViewTabSelector({super.key, required this.tab, required this.index});

  @override
  State<WebViewTabSelector> createState() => _WebViewTabSelectorState();
}

class _WebViewTabSelectorState extends State<WebViewTabSelector> {
  bool isHover = false;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final browserModel = Provider.of<BrowserModel>(context, listen: true);
    final isCurrentTab = browserModel.getCurrentTabIndex() == widget.index;

    final tab = widget.tab;
    final url = tab.webViewModel.url;
    final tabName =
        tab.webViewModel.title ?? tab.webViewModel.url.toString() ?? 'New Tab';
    var faviconUrl = tab.webViewModel.favicon != null
        ? tab.webViewModel.favicon!.url
        : (url != null && ["http", "https"].contains(url.scheme)
            ? Uri.parse("${url.origin}/favicon.ico")
            : null);

    return MouseRegion(
      onEnter: (event) {
        setState(() {
          isHover = true;
        });
      },
      onExit: (event) {
        setState(() {
          isHover = false;
        });
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          browserModel.showTab(widget.index);
        },
        child: ContextMenuRegion(
            contextMenu: GenericContextMenu(
              buttonConfigs: [
                ContextMenuButtonConfig(
                  "Reload",
                  onPressed: () {
                    tab.webViewModel.webViewController?.reload();
                  },
                ),
                ContextMenuButtonConfig(
                  "Duplicate",
                  onPressed: () {
                    final browserModel =
                        Provider.of<BrowserModel>(context, listen: false);
                    if (tab.webViewModel.url != null) {
                      browserModel.addTab(WebViewTab(
                        key: GlobalKey(),
                        webViewModel: WebViewModel(url: tab.webViewModel.url),
                      ));
                    }
                  },
                ),
                ContextMenuButtonConfig(
                  "Close",
                  onPressed: () {
                    browserModel.closeTab(widget.index);
                  },
                ),
              ],
            ),
            child: Container(
              height: 30,
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 250),
              padding: const EdgeInsets.only(right: 5.0),
              decoration: !isCurrentTab
                  ? null
                  : const BoxDecoration(
                      color: Colors.black45,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(5))),
              child: Tooltip(
                decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.all(Radius.circular(5))),
                richMessage: WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Text(
                        '$tabName\n${url?.host}',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white),
                      ),
                    )),
                waitDuration: const Duration(milliseconds: 500),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                        child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          child: CustomImage(
                              url: faviconUrl, maxWidth: 20.0, height: 20.0),
                        ),
                        Flexible(
                            child: Text(tabName,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                softWrap: false,
                                style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        isCurrentTab ? Colors.white : null))),
                      ],
                    )),
                    IconButton(
                        onPressed: () {
                          browserModel.closeTab(widget.index);
                        },
                        constraints: const BoxConstraints(
                          maxWidth: 20,
                          minWidth: 20,
                          maxHeight: 20,
                          minHeight: 20,
                        ),
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.cancel,
                          color: isCurrentTab ? Colors.white : null,
                          size: 15,
                        )),
                  ],
                ),
              ),
            )),
      ),
    );
  }
}
