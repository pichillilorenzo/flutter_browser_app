import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_browser/models/webview_model.dart';
import 'package:flutter_browser/util.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

class StorageManager extends StatefulWidget {
  const StorageManager({super.key});

  @override
  State<StorageManager> createState() => _StorageManagerState();
}

class _StorageManagerState extends State<StorageManager> {
  final CookieManager _cookieManager = CookieManager.instance();
  final WebStorageManager _webStorageManager = WebStorageManager.instance();
  final HttpAuthCredentialDatabase _httpAuthCredentialDatabase =
      HttpAuthCredentialDatabase.instance();

  var cookieNameTrackingEdit = <bool>[];
  var cookieValueTrackingEdit = <bool>[];
  var localStorageKeyTrackingEdit = <bool>[];
  var localStorageValueTrackingEdit = <bool>[];
  var sessionStorageKeyTrackingEdit = <bool>[];
  var sessionStorageValueTrackingEdit = <bool>[];

  final TextEditingController _newCookieNameController =
      TextEditingController();
  final TextEditingController _newCookieValueController =
      TextEditingController();
  final TextEditingController _newCookiePathController =
      TextEditingController();
  final TextEditingController _newCookieDomainController =
      TextEditingController();

  final TextEditingController _newLocalStorageKeyController =
      TextEditingController();
  final TextEditingController _newLocalStorageValueController =
      TextEditingController();

  final TextEditingController _newSessionStorageKeyController =
      TextEditingController();
  final TextEditingController _newSessionStorageValueController =
      TextEditingController();

  bool _newCookieIsSecure = false;
  DateTime? _newCookieExpiresDate;

  final _newCookieFormKey = GlobalKey<FormState>();
  final _newLocalStorageItemFormKey = GlobalKey<FormState>();
  final _newSessionStorageItemFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    cookieNameTrackingEdit = [];
    cookieValueTrackingEdit = [];
    localStorageKeyTrackingEdit = [];
    localStorageValueTrackingEdit = [];
    sessionStorageKeyTrackingEdit = [];
    sessionStorageValueTrackingEdit = [];

    _newCookiePathController.text = "/";
  }

  @override
  void dispose() {
    _newCookieNameController.dispose();
    _newCookieValueController.dispose();
    _newCookiePathController.dispose();
    _newCookieDomainController.dispose();
    _newLocalStorageKeyController.dispose();
    _newLocalStorageValueController.dispose();
    _newSessionStorageKeyController.dispose();
    _newSessionStorageValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildStorageManager();
  }

  Widget _buildStorageManager() {
    return LayoutBuilder(
      builder: (context, constraints) {
        var entryItems = <Widget>[
          _buildCookiesExpansionTile(constraints),
          _buildWebLocalStorageExpansionTile(constraints),
          _buildWebSessionStorageExpansionTile(constraints),
          _buildHttpAuthCredentialDatabaseExpansionTile(constraints),
        ];

        if (Util.isAndroid()) {
          entryItems.add(_buildAndroidWebStorageExpansionTile(constraints));
        } else if (Util.isIOS()) {
          entryItems.add(_buildIOSWebStorageExpansionTile(constraints));
        }

        return ListView.builder(
          itemCount: entryItems.length,
          itemBuilder: (context, index) {
            return entryItems[index];
          },
        );
      },
    );
  }

  Widget _buildCookiesExpansionTile(BoxConstraints constraints) {
    return Selector<WebViewModel, WebUri>(
      selector: (context, webViewModel) => webViewModel.url!,
      builder: (context, url, child) {
        return FutureBuilder(
          future: _cookieManager.getCookies(url: url),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container();
            }

            List<Cookie> cookies = snapshot.data ?? <Cookie>[];

            var rows = <DataRow>[];
            if (cookieValueTrackingEdit.length != cookies.length) {
              cookieNameTrackingEdit = List.filled(cookies.length, false);
              cookieValueTrackingEdit = List.filled(cookies.length, false);
            }

            rows.addAll(cookies.map((cookie) {
              var index = cookies.indexOf(cookie);
              return DataRow(cells: <DataCell>[
                _buildDataCellEditable(
                    width: constraints.maxWidth / 3,
                    onFieldSubmitted: (newValue) async {
                      var updateCookie = await _cookieManager.getCookie(
                          url: url, name: cookie.name);
                      await _cookieManager.deleteCookie(
                          url: url, name: cookie.name);
                      await _cookieManager.setCookie(
                          url: url,
                          name: cookie.name,
                          value: updateCookie?.value ?? "");
                    },
                    initialValue: cookie.name,
                    index: index,
                    trackingEditStatus: cookieNameTrackingEdit),
                _buildDataCellEditable(
                    width: constraints.maxWidth / 3,
                    onFieldSubmitted: (newValue) async {
                      await _cookieManager.setCookie(
                          url: url, name: cookie.name, value: newValue);
                    },
                    initialValue: cookie.value,
                    index: index,
                    trackingEditStatus: cookieValueTrackingEdit),
                DataCell(IconButton(
                  icon: const Icon(Icons.cancel),
                  onPressed: () async {
                    await _cookieManager.deleteCookie(url: url, name: cookie.name);
                    setState(() { });
                  },
                ))
              ]);
            }).toList());

            return ExpansionTile(
              onExpansionChanged: (value) {
                FocusScope.of(context).unfocus();
              },
              title: const Text(
                "Cookies",
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              children: <Widget>[
                SizedBox(
                  width: constraints.minWidth,
                  child: DataTable(
                    columnSpacing: 0.0,
                    columns: const <DataColumn>[
                      DataColumn(
                        label: Text(
                          "Name",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16.0),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Value",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16.0),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Delete",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16.0),
                        ),
                      ),
                    ],
                    rows: rows,
                  ),
                ),
                Form(
                  key: _newCookieFormKey,
                  child: Container(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.only(right: 10.0),
                                child: TextFormField(
                                  controller: _newCookieNameController,
                                  decoration: const InputDecoration(
                                      labelText: "Cookie Name"),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter some text';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: _newCookieValueController,
                                decoration: const InputDecoration(
                                    labelText: "Cookie Value"),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter some text';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.only(right: 10.0),
                                child: TextFormField(
                                  controller: _newCookieDomainController,
                                  decoration: const InputDecoration(
                                      labelText: "Cookie Domain"),
                                ),
                              ),
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: _newCookiePathController,
                                decoration: const InputDecoration(
                                    labelText: "Cookie Path"),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter some text';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: ListTile(
                                      title: const Text("Expires in:"),
                                      subtitle: Text(
                                          _newCookieExpiresDate != null
                                              ? _newCookieExpiresDate!
                                                  .toIso8601String()
                                              : "Select a date ..."),
                                      onTap: () async {
                                        FocusScope.of(context).unfocus();
                                        _newCookieExpiresDate = await showDatePicker(
                                            context: context,
                                            initialDate: _newCookieExpiresDate,
                                            firstDate: DateTime.now(),
                                            lastDate: DateTime(9999),
                                        );
                                        setState(() { });
                                      },
                                    ),
                                  ),
                                  Center(
                                    child: IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          _newCookieExpiresDate = null;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                                child: CheckboxListTile(
                              title: const Text("Is Secure?"),
                              value: _newCookieIsSecure,
                              onChanged: (newValue) {
                                setState(() {
                                  _newCookieIsSecure = newValue!;
                                });
                              }, //  <-- leading Checkbox
                            )),
                          ],
                        ),
                        SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: TextButton(
                              child: const Text("Add Cookie"),
                              onPressed: () async {
                                if (_newCookieFormKey.currentState != null &&
                                    _newCookieFormKey.currentState!
                                        .validate()) {
                                  final expiresDate = _newCookieExpiresDate?.millisecondsSinceEpoch;

                                  await _cookieManager.setCookie(
                                      url: url,
                                      name: _newCookieNameController.text,
                                      value: _newCookieValueController.text,
                                      domain: _newCookieDomainController
                                              .text.isEmpty
                                          ? null
                                          : _newCookieDomainController.text,
                                      isSecure: _newCookieIsSecure,
                                      path: _newCookiePathController.text,
                                      expiresDate: expiresDate);

                                  setState(() {
                                    _newCookieFormKey.currentState!.reset();
                                  });
                                }
                              },
                            ))
                      ],
                    ),
                  ),
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextButton(
                        child: const Text("Clear cookies"),
                        onPressed: () async {
                          await _cookieManager.deleteCookies(url: url);
                          setState(() {});
                        },
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        child: const Text("Clear all"),
                        onPressed: () async {
                          await _cookieManager.deleteAllCookies();
                          setState(() {});
                        },
                      ),
                    )
                  ],
                )
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildWebLocalStorageExpansionTile(BoxConstraints constraints) {
    return Consumer<WebViewModel>(
      builder: (context, webViewModel, child) {
        var webViewController = webViewModel.webViewController;

        return FutureBuilder(
          future: webViewController?.webStorage.localStorage.getItems(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container();
            }

            List<WebStorageItem> webStorageItems =
                snapshot.data ?? <WebStorageItem>[];

            var rows = <DataRow>[];
            if (localStorageValueTrackingEdit.length !=
                webStorageItems.length) {
              localStorageKeyTrackingEdit =
                  List.filled(webStorageItems.length, false);
              localStorageValueTrackingEdit =
                  List.filled(webStorageItems.length, false);
            }

            rows.addAll(webStorageItems.map((webStorageItem) {
              var index = webStorageItems.indexOf(webStorageItem);
              return DataRow(cells: <DataCell>[
                _buildDataCellEditable(
                    width: constraints.maxWidth / 3,
                    onFieldSubmitted: (newValue) async {
                      var updateItemValue = await webViewController
                          ?.webStorage.localStorage
                          .getItem(key: webStorageItem.key!);
                      await webViewController?.webStorage.localStorage
                          .removeItem(key: webStorageItem.key!);
                      await webViewController?.webStorage.localStorage
                          .setItem(key: newValue, value: updateItemValue);
                    },
                    initialValue: webStorageItem.key!,
                    index: index,
                    trackingEditStatus: localStorageKeyTrackingEdit),
                _buildDataCellEditable(
                    width: constraints.maxWidth / 3,
                    onFieldSubmitted: (newValue) async {
                      await webViewController?.webStorage.localStorage
                          .setItem(key: webStorageItem.key!, value: newValue);
                    },
                    initialValue: webStorageItem.value,
                    index: index,
                    trackingEditStatus: localStorageValueTrackingEdit),
                DataCell(IconButton(
                  icon: const Icon(Icons.cancel),
                  onPressed: () async {
                    await webViewController?.webStorage.localStorage
                        .removeItem(key: webStorageItem.key!);
                    setState(() {});
                  },
                ))
              ]);
            }).toList());

            return ExpansionTile(
              onExpansionChanged: (value) {
                FocusScope.of(context).unfocus();
              },
              title: const Text(
                "Local Storage",
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              children: <Widget>[
                SizedBox(
                  width: constraints.minWidth,
                  child: DataTable(
                    columnSpacing: 0.0,
                    columns: const <DataColumn>[
                      DataColumn(
                        label: Text(
                          "Key",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16.0),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Value",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16.0),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Delete",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16.0),
                        ),
                      ),
                    ],
                    rows: rows,
                  ),
                ),
                _buildAddNewWebStorageItem(
                  formKey: _newLocalStorageItemFormKey,
                  nameController: _newLocalStorageKeyController,
                  valueController: _newLocalStorageValueController,
                  labelName: "Local Item Key",
                  labelValue: "Local Item Value",
                  onAdded: (name, value) {
                    webViewController?.webStorage.localStorage
                        .setItem(key: name, value: value);
                  },
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: TextButton(
                    child: const Text("Clear items"),
                    onPressed: () async {
                      await webViewController?.webStorage.localStorage.clear();
                      setState(() {});
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildWebSessionStorageExpansionTile(BoxConstraints constraints) {
    return Consumer<WebViewModel>(
      builder: (context, webViewModel, child) {
        var webViewController = webViewModel.webViewController;

        return FutureBuilder(
          future: webViewController?.webStorage.sessionStorage.getItems(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container();
            }

            List<WebStorageItem> webStorageItems =
                snapshot.data ?? <WebStorageItem>[];

            var rows = <DataRow>[];

            if (sessionStorageValueTrackingEdit.length !=
                webStorageItems.length) {
              sessionStorageKeyTrackingEdit =
                  List.filled(webStorageItems.length, false);
              sessionStorageValueTrackingEdit =
                  List.filled(webStorageItems.length, false);
            }

            rows.addAll(webStorageItems.map((webStorageItem) {
              var index = webStorageItems.indexOf(webStorageItem);

              return DataRow(cells: <DataCell>[
                _buildDataCellEditable(
                    width: constraints.maxWidth / 3,
                    onFieldSubmitted: (newValue) async {
                      var updateItemValue = await webViewController
                          ?.webStorage.sessionStorage
                          .getItem(key: webStorageItem.key!);
                      await webViewController?.webStorage.sessionStorage
                          .removeItem(key: webStorageItem.key!);
                      await webViewController?.webStorage.sessionStorage
                          .setItem(key: newValue, value: updateItemValue);
                    },
                    initialValue: webStorageItem.key!,
                    index: index,
                    trackingEditStatus: sessionStorageKeyTrackingEdit),
                _buildDataCellEditable(
                    width: constraints.maxWidth / 3,
                    onFieldSubmitted: (newValue) async {
                      await webViewController?.webStorage.sessionStorage
                          .setItem(key: webStorageItem.key!, value: newValue);
                    },
                    initialValue: webStorageItem.value,
                    index: index,
                    trackingEditStatus: sessionStorageValueTrackingEdit),
                DataCell(IconButton(
                  icon: const Icon(Icons.cancel),
                  onPressed: () async {
                    await webViewController?.webStorage.sessionStorage
                        .removeItem(key: webStorageItem.key!);
                    setState(() {});
                  },
                ))
              ]);
            }).toList());

            return ExpansionTile(
              onExpansionChanged: (value) {
                FocusScope.of(context).unfocus();
              },
              title: const Text(
                "Session Storage",
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              children: <Widget>[
                SizedBox(
                  width: constraints.minWidth,
                  child: DataTable(
                    columnSpacing: 0.0,
                    columns: const <DataColumn>[
                      DataColumn(
                        label: Text(
                          "Key",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16.0),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Value",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16.0),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Delete",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16.0),
                        ),
                      ),
                    ],
                    rows: rows,
                  ),
                ),
                _buildAddNewWebStorageItem(
                  formKey: _newSessionStorageItemFormKey,
                  nameController: _newSessionStorageKeyController,
                  valueController: _newSessionStorageValueController,
                  labelName: "Session Item Key",
                  labelValue: "Session Item Value",
                  onAdded: (name, value) async {
                    await webViewController?.webStorage.sessionStorage
                        .setItem(key: name, value: value);
                    setState(() {});
                  },
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: TextButton(
                    child: const Text("Clear items"),
                    onPressed: () async {
                      await webViewController?.webStorage.sessionStorage
                          .clear();
                      setState(() {});
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAndroidWebStorageExpansionTile(BoxConstraints constraints) {
    var children = <Widget>[
      ListTile(
        title: const Text("Quota"),
        subtitle: Selector<WebViewModel, Uri>(
          selector: (context, webViewModel) => webViewModel.url!,
          builder: (context, url, child) {
            return FutureBuilder(
              future: _webStorageManager
                  .getQuotaForOrigin(origin: url.origin),
              builder: (context, snapshot) {
                return Text(snapshot.hasData ? snapshot.data.toString() : "");
              },
            );
          },
        ),
      ),
      Selector<WebViewModel, Uri>(
          selector: (context, webViewModel) => webViewModel.url!,
          builder: (context, url, child) {
            return ListTile(
              title: const Text("Usage"),
              subtitle: FutureBuilder(
                future: _webStorageManager
                    .getUsageForOrigin(origin: url.origin),
                builder: (context, snapshot) {
                  return Text(snapshot.hasData ? snapshot.data.toString() : "");
                },
              ),
              trailing: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () async {
                  await _webStorageManager
                      .deleteOrigin(origin: url.origin);
                  setState(() {});
                },
              ),
            );
          }),
    ];

    return ExpansionTile(
      onExpansionChanged: (value) {
        FocusScope.of(context).unfocus();
      },
      title: const Text(
        "Web Storage Android",
        style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
      ),
      children: children,
    );
  }

  Widget _buildIOSWebStorageExpansionTile(BoxConstraints constraints) {
    return FutureBuilder(
      future: _webStorageManager
          .fetchDataRecords(dataTypes: WebsiteDataType.ALL),
      builder: (context, snapshot) {
        List<WebsiteDataRecord> dataRecords = snapshot.hasData
            ? (snapshot.data as List<WebsiteDataRecord>)
            : <WebsiteDataRecord>[];

        var rows = <DataRow>[];

        rows.addAll(dataRecords.map((dataRecord) {
          var textStyle = const TextStyle(fontSize: 12.0);

          return DataRow(cells: <DataCell>[
            DataCell(
              SizedBox(
                width: constraints.maxWidth / 3,
                child: Text(dataRecord.displayName ?? "",
                    style: textStyle, softWrap: true),
              ),
              onTap: () {
                Clipboard.setData(ClipboardData(text: dataRecord.displayName ?? ''));
              },
            ),
            DataCell(
              SizedBox(
                width: constraints.maxWidth / 3,
                child: Text(dataRecord.dataTypes?.join(", ") ?? "",
                    style: textStyle, softWrap: true),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      content: Text(dataRecord.dataTypes?.join(",\n") ?? "",
                          style: textStyle, softWrap: true),
                    );
                  },
                );
              },
            ),
            DataCell(IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () async {
                if (dataRecord.dataTypes != null) {
                  await _webStorageManager.removeDataFor(
                      dataTypes: dataRecord.dataTypes!,
                      dataRecords: [dataRecord]);
                }
                setState(() {});
              },
            ))
          ]);
        }).toList());

        return ExpansionTile(
          onExpansionChanged: (value) {
            FocusScope.of(context).unfocus();
          },
          title: const Text(
            "Web Storage iOS",
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
          ),
          children: <Widget>[
            SizedBox(
              width: constraints.minWidth,
              child: DataTable(
                columnSpacing: 0.0,
                columns: const <DataColumn>[
                  DataColumn(
                    label: Text(
                      "Display Name",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16.0),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Data Types",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16.0),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Delete",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16.0),
                    ),
                  ),
                ],
                rows: rows,
              ),
            ),
            SizedBox(
                width: MediaQuery.of(context).size.width,
                child: TextButton(
                  child: const Text("Clear all"),
                  onPressed: () async {
                    await _webStorageManager.removeDataModifiedSince(
                        dataTypes: WebsiteDataType.ALL,
                        date: DateTime.fromMillisecondsSinceEpoch(0));
                    setState(() {});
                  },
                ))
          ],
        );
      },
    );
  }

  Widget _buildHttpAuthCredentialDatabaseExpansionTile(
      BoxConstraints constraints) {
    return FutureBuilder(
      future: _httpAuthCredentialDatabase.getAllAuthCredentials(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container();
        }

        List<URLProtectionSpaceHttpAuthCredentials>
            protectionSpaceHttpAuthCredentials =
            snapshot.data ?? <URLProtectionSpaceHttpAuthCredentials>[];

        var textStyle = const TextStyle(fontSize: 16.0);

        var dataTables = <Widget>[];

        for (var protectionSpaceHttpAuthCredential
            in protectionSpaceHttpAuthCredentials) {
          var protectionSpace =
              protectionSpaceHttpAuthCredential.protectionSpace;
          var rows = <DataRow>[];

          if (protectionSpaceHttpAuthCredential.credentials != null) {
            rows.addAll(protectionSpaceHttpAuthCredential.credentials!
                .map((httpAuthCredential) {
              return DataRow(cells: <DataCell>[
                DataCell(
                  SizedBox(
                    width: constraints.maxWidth / 3,
                    child: Text(httpAuthCredential.username ?? "",
                        style: textStyle, softWrap: true),
                  ),
                  onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: httpAuthCredential.username ?? ''));
                  },
                ),
                DataCell(
                  SizedBox(
                    width: constraints.maxWidth / 3,
                    child: Text(httpAuthCredential.password ?? "",
                        style: textStyle, softWrap: true),
                  ),
                  onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: httpAuthCredential.password ?? ''));
                  },
                ),
                DataCell(IconButton(
                  icon: const Icon(Icons.cancel),
                  onPressed: () async {
                    if (protectionSpace != null) {
                      await _httpAuthCredentialDatabase
                          .removeHttpAuthCredential(
                              protectionSpace: protectionSpace,
                              credential: httpAuthCredential);
                    }
                    setState(() {});
                  },
                ))
              ]);
            }).toList());
          }

          dataTables.add(Column(
            children: <Widget>[
              const Text(
                "Protection Space",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
              ),
              const SizedBox(
                height: 10.0,
              ),
              Text(
                  "Protocol: ${protectionSpace?.protocol ?? ""}, Host: ${protectionSpace?.host ?? ""}, Port: ${protectionSpace?.port != null && protectionSpace!.port! > 0 ? protectionSpace.port.toString() : ""}, Realm: ${protectionSpace?.realm ?? ""}"),
              SizedBox(
                  width: constraints.minWidth,
                  child: DataTable(
                    columnSpacing: 0.0,
                    columns: const <DataColumn>[
                      DataColumn(
                        label: Text(
                          "Username",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16.0),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Password",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16.0),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Delete",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16.0),
                        ),
                      ),
                    ],
                    rows: rows,
                  ))
            ],
          ));
        }

        var children = <Widget>[];
        children.addAll(dataTables);
        children.addAll(<Widget>[
          TextButton(
            child: const Text("Clear all"),
            onPressed: () async {
              await _httpAuthCredentialDatabase.clearAllAuthCredentials();
              setState(() {});
            },
          ),
        ]);

        return ExpansionTile(
          onExpansionChanged: (value) {
            FocusScope.of(context).unfocus();
          },
          title: const Text(
            "Http Auth Credentials Database",
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
          ),
          children: children,
        );
      },
    );
  }

  DataCell _buildDataCellEditable(
      {required double width,
      required int index,
      required List<bool> trackingEditStatus,
      String? initialValue,
      Future<void> Function(String newValue)? onFieldSubmitted}) {
    return DataCell(
      SizedBox(
          width: width,
          child: Builder(
            builder: (context) {
              return !trackingEditStatus[index]
                  ? Text(
                      initialValue ?? "",
                      style: const TextStyle(fontSize: 16.0),
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                    )
                  : TextFormField(
                      initialValue: initialValue,
                      autofocus: false,
                      onFieldSubmitted: (newValue) async {
                        if (newValue != initialValue &&
                            onFieldSubmitted != null) {
                          await onFieldSubmitted(newValue);
                        }
                        setState(() {
                          trackingEditStatus[index] = false;
                        });
                      },
                    );
            },
          )),
      onTap: () {
        setState(() {
          trackingEditStatus[index] = !trackingEditStatus[index];
        });
      },
    );
  }

  Widget _buildAddNewWebStorageItem(
      {required GlobalKey<FormState> formKey,
      required TextEditingController nameController,
      required TextEditingController valueController,
      required String labelName,
      required String labelValue,
      Function(String name, String value)? onAdded}) {
    return Form(
      key: formKey,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: labelName),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                },
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(right: 10.0),
              child: TextFormField(
                controller: valueController,
                decoration: InputDecoration(labelText: labelValue),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                },
              ),
            ),
          ),
          TextButton(
            child: const Text("Add Item"),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                setState(() {
                  if (onAdded != null) {
                    onAdded(nameController.text, valueController.text);
                    formKey.currentState!.reset();
                  }
                });
              }
            },
          ),
        ],
      ),
    );
  }
}
