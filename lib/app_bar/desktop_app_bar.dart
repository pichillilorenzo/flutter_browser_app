import 'package:collection/collection.dart';
import 'package:context_menus/context_menus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

import '../custom_image.dart';
import '../models/browser_model.dart';
import '../models/webview_model.dart';
import '../models/window_model.dart';
import '../util.dart';
import '../webview_tab.dart';

class DesktopAppBar extends StatefulWidget {
  final bool showTabs;

  const DesktopAppBar({super.key, this.showTabs = true});

  @override
  State<DesktopAppBar> createState() => _DesktopAppBarState();
}

class _DesktopAppBarState extends State<DesktopAppBar> {
  @override
  Widget build(BuildContext context) {
    final windowModel = Provider.of<WindowModel>(context, listen: true);

    final tabSelectors = !widget.showTabs
        ? <Widget>[]
        : windowModel.webViewTabs.map((webViewTab) {
            final index = windowModel.webViewTabs.indexOf(webViewTab);
            final currentIndex = windowModel.getCurrentTabIndex();

            return Flexible(
                flex: 1,
                fit: FlexFit.loose,
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                          child: WebViewTabSelector(
                              tab: webViewTab, index: index)),
                      SizedBox(
                        height: 15,
                        child: VerticalDivider(
                            thickness: 1,
                            width: 1,
                            color: index == currentIndex - 1 ||
                                    index == currentIndex
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
              WindowManagerPlus.current.close();
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
              if (!(await  WindowManagerPlus.current.isFullScreen())) {
                 WindowManagerPlus.current.minimize();
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
                backgroundColor: const WidgetStatePropertyAll(Colors.amber),
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
               WindowManagerPlus.current
                  .setFullScreen(!(await  WindowManagerPlus.current.isFullScreen()));
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
                backgroundColor: const WidgetStatePropertyAll(Colors.green),
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
              !widget.showTabs
                  ? null
                  : IconButton(
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
                      icon: const Icon(
                        Icons.add,
                        size: 15,
                        color: Colors.white,
                      )),
            ].whereNotNull().toList().cast<Widget>(),
          ),
        ),
      ),
      Flexible(
          child: MouseRegion(
              hitTestBehavior: HitTestBehavior.opaque,
              onEnter: (details) {
                if (!Util.isWindows()) {
                   WindowManagerPlus.current.setMovable(true);
                }
                setState(() {});
              },
              onExit: (details) {
                if (!Util.isWindows()) {
                   WindowManagerPlus.current.setMovable(false);
                }
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onDoubleTap: () async {
                  await  WindowManagerPlus.current.maximize();
                },
                child: !widget.showTabs
                    ? const SizedBox(
                        height: 30,
                        width: double.infinity,
                      )
                    : ContextMenuRegion(
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
                                windowModel.closeAllTabs();
                              },
                            ),
                          ],
                        ),
                        child: const SizedBox(
                          height: 30,
                          width: double.infinity,
                        )),
              ))),
      !widget.showTabs
          ? null
          : OpenTabsViewer(
              webViewTabs: windowModel.webViewTabs,
            ),
    ].whereNotNull().toList();

    return Container(
      color: Theme.of(context).colorScheme.primary,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: children,
      ),
    );
  }

  void _addNewTab() {
    final browserModel = Provider.of<BrowserModel>(context, listen: false);
    final windowModel = Provider.of<WindowModel>(context, listen: false);
    final settings = browserModel.getSettings();
    windowModel.addTab(WebViewTab(
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
    final windowModel = Provider.of<WindowModel>(context, listen: true);
    final isCurrentTab = windowModel.getCurrentTabIndex() == widget.index;

    final tab = widget.tab;
    final url = tab.webViewModel.url;
    var tabName = tab.webViewModel.title ?? url?.toString() ?? '';
    if (tabName.isEmpty) {
      tabName = 'New Tab';
    }
    final tooltipText =
        '$tabName\n${(url?.host ?? '').isEmpty ? url?.toString() : url?.host}'
            .trim();
    final faviconUrl = tab.webViewModel.favicon != null
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
          windowModel.showTab(widget.index);
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
                    if (tab.webViewModel.url != null) {
                      windowModel.addTab(WebViewTab(
                        key: GlobalKey(),
                        webViewModel: WebViewModel(url: tab.webViewModel.url),
                      ));
                    }
                  },
                ),
                ContextMenuButtonConfig(
                  "Close",
                  onPressed: () {
                    windowModel.closeTab(widget.index);
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
                  : BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(5))),
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
                        tooltipText,
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
                                        !isCurrentTab ? Colors.white : null))),
                      ],
                    )),
                    IconButton(
                        onPressed: () {
                          windowModel.closeTab(widget.index);
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
                          color: !isCurrentTab ? Colors.white : null,
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

class OpenTabsViewer extends StatefulWidget {
  final List<WebViewTab> webViewTabs;

  const OpenTabsViewer({super.key, required this.webViewTabs});

  @override
  State<OpenTabsViewer> createState() => _OpenTabsViewerState();
}

class _OpenTabsViewerState extends State<OpenTabsViewer> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(4.0),
        child: MenuAnchor(
          builder: (context, controller, child) {
            return IconButton(
                onPressed: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
                constraints: const BoxConstraints(
                  maxWidth: 25,
                  minWidth: 25,
                  maxHeight: 25,
                  minHeight: 25,
                ),
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  size: 15,
                  color: Colors.white,
                ));
          },
          menuChildren: [
            ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 200,
              ),
              child: TextFormField(
                controller: _controller,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelLarge,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search open tabs',
                  contentPadding: EdgeInsets.only(top: 15),
                  isDense: true,
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
            MenuItemButton(
              onPressed: null,
              child: Text(
                widget.webViewTabs.isEmpty ? 'No tabs open' : 'Tabs open',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            ...(widget.webViewTabs.where(
              (element) {
                final search = _controller.text.toLowerCase().trim();
                final containsInTitle = element.webViewModel.title
                        ?.toLowerCase()
                        .contains(search) ??
                    false;
                final containsInUrl = element.webViewModel.url
                        ?.toString()
                        .toLowerCase()
                        .contains(search) ??
                    false;
                return search.isEmpty || containsInTitle || containsInUrl;
              },
            ).map((w) {
              final url = w.webViewModel.url;
              final title = (w.webViewModel.title ?? '').isNotEmpty
                  ? w.webViewModel.title!
                  : 'New Tab';
              var subtitle =
                  (url?.host ?? '').isEmpty ? url?.toString() : url?.host;
              final diffTime =
                  DateTime.now().difference(w.webViewModel.lastOpenedTime);
              var diffTimeSubtitle = 'now';
              if (diffTime.inDays > 0) {
                diffTimeSubtitle =
                    '${diffTime.inDays} ${diffTime.inDays == 1 ? 'day' : 'days'} ago';
              } else if (diffTime.inMinutes > 0) {
                diffTimeSubtitle = '${diffTime.inMinutes} min ago';
              } else if (diffTime.inSeconds > 0) {
                diffTimeSubtitle = '${diffTime.inSeconds} sec ago';
              }

              final faviconUrl = w.webViewModel.favicon != null
                  ? w.webViewModel.favicon!.url
                  : (url != null && ["http", "https"].contains(url.scheme)
                      ? Uri.parse("${url.origin}/favicon.ico")
                      : null);

              return MenuItemButton(
                onPressed: () {
                  final windowModel =
                      Provider.of<WindowModel>(context, listen: false);
                  windowModel.showTab(windowModel.webViewTabs.indexOf(w));
                },
                leadingIcon: Container(
                  padding: const EdgeInsets.all(8),
                  child: CustomImage(url: faviconUrl, maxWidth: 15, height: 15),
                ),
                trailingIcon: IconButton(
                    onPressed: () {
                      final windowModel =
                          Provider.of<WindowModel>(context, listen: false);
                      windowModel.closeTab(widget.webViewTabs.indexOf(w));
                    },
                    constraints: const BoxConstraints(
                      maxWidth: 25,
                      minWidth: 25,
                      maxHeight: 25,
                      minHeight: 25,
                    ),
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.cancel,
                      size: 15,
                    )),
                child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 250,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        Row(
                          children: [
                            Flexible(
                                child: Text(
                              subtitle ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall,
                            )),
                            Text(
                              " - $diffTimeSubtitle",
                              style: Theme.of(context).textTheme.labelSmall,
                            )
                          ],
                        )
                      ].whereNotNull().toList(),
                    )),
              );
            }).toList())
          ].whereNotNull().toList(),
        ));
  }
}
