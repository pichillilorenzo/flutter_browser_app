import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_browser/models/webview_model.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

class StorageManager extends StatefulWidget {
  StorageManager({Key key}) : super(key: key);

  @override
  _StorageManagerState createState() => _StorageManagerState();
}

class _StorageManagerState extends State<StorageManager> {
  CookieManager _cookieManager = CookieManager.instance();
  WebStorageManager _webStorageManager = WebStorageManager.instance();
  HttpAuthCredentialDatabase _httpAuthCredentialDatabase =
      HttpAuthCredentialDatabase.instance();

  var cookieNameTrackingEdit = <bool>[];
  var cookieValueTrackingEdit = <bool>[];
  var localStorageKeyTrackingEdit = <bool>[];
  var localStorageValueTrackingEdit = <bool>[];
  var sessionStorageKeyTrackingEdit = <bool>[];
  var sessionStorageValueTrackingEdit = <bool>[];

  TextEditingController _newCookieNameController = TextEditingController();
  TextEditingController _newCookieValueController = TextEditingController();
  TextEditingController _newCookiePathController = TextEditingController();
  TextEditingController _newCookieDomainController = TextEditingController();

  TextEditingController _newLocalStorageKeyController = TextEditingController();
  TextEditingController _newLocalStorageValueController =
      TextEditingController();

  TextEditingController _newSessionStorageKeyController =
      TextEditingController();
  TextEditingController _newSessionStorageValueController =
      TextEditingController();

  bool _newCookieIsSecure = false;
  DateTime _newCookieExpiresDate;

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

        if (Platform.isAndroid) {
          entryItems.add(_buildAndroidWebStorageExpansionTile(constraints));
        } else if (Platform.isIOS) {
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
    return Selector<WebViewModel, String>(
      selector: (context, webViewModel) => webViewModel.url,
      builder: (context, url, child) {
        return FutureBuilder(
          future: _cookieManager.getCookies(url: url),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container();
            }

            List<Cookie> cookies = snapshot.data;

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
                          value: updateCookie.value);
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
                  icon: Icon(Icons.cancel),
                  onPressed: () {
                    setState(() {
                      _cookieManager.deleteCookie(url: url, name: cookie.name);
                    });
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
                Container(
                  width: constraints.minWidth,
                  child: DataTable(
                    columnSpacing: 0.0,
                    columns: const <DataColumn>[
                      DataColumn(
                        label: const Text(
                          "Name",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16.0),
                        ),
                      ),
                      DataColumn(
                        label: const Text(
                          "Value",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16.0),
                        ),
                      ),
                      DataColumn(
                        label: const Text(
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
                    padding: EdgeInsets.all(10.0),
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.only(right: 10.0),
                                child: TextFormField(
                                  controller: _newCookieNameController,
                                  decoration:
                                      InputDecoration(labelText: "Cookie Name"),
                                  validator: (value) {
                                    if (value.isEmpty) {
                                      return 'Please enter some text';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                child: TextFormField(
                                  controller: _newCookieValueController,
                                  decoration: InputDecoration(
                                      labelText: "Cookie Value"),
                                  validator: (value) {
                                    if (value.isEmpty) {
                                      return 'Please enter some text';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.only(right: 10.0),
                                child: TextFormField(
                                  controller: _newCookieDomainController,
                                  decoration: InputDecoration(
                                      labelText: "Cookie Domain"),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                child: TextFormField(
                                  controller: _newCookiePathController,
                                  decoration:
                                      InputDecoration(labelText: "Cookie Path"),
                                  validator: (value) {
                                    if (value.isEmpty) {
                                      return 'Please enter some text';
                                    }
                                    return null;
                                  },
                                ),
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
                                    child: Container(
                                      child: ListTile(
                                        title: Text("Expires in:"),
                                        subtitle: Text(
                                            _newCookieExpiresDate != null
                                                ? _newCookieExpiresDate
                                                    .toIso8601String()
                                                : "Select a date ..."),
                                        onTap: () async {
                                          FocusScope.of(context).unfocus();
                                          DatePicker.showDateTimePicker(context,
                                              showTitleActions: true,
                                              minTime: DateTime.now(),
                                              maxTime: DateTime(9999),
                                              onConfirm: (expiresDate) {
                                            setState(() {
                                              _newCookieExpiresDate =
                                                  expiresDate;
                                            });
                                          },
                                              currentTime:
                                                  _newCookieExpiresDate);
                                        },
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: IconButton(
                                      icon: Icon(Icons.clear),
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
                              title: Text("Is Secure?"),
                              value: _newCookieIsSecure,
                              onChanged: (newValue) {
                                setState(() {
                                  _newCookieIsSecure = newValue;
                                });
                              }, //  <-- leading Checkbox
                            )),
                          ],
                        ),
                        Container(
                            width: MediaQuery.of(context).size.width,
                            child: FlatButton(
                              padding: EdgeInsets.all(15.0),
                              child: Text("Add Cookie"),
                              onPressed: () async {
                                if (_newCookieFormKey.currentState.validate()) {
                                  final expiresDate =
                                      _newCookieExpiresDate != null
                                          ? _newCookieExpiresDate
                                              .millisecondsSinceEpoch
                                          : _newCookieExpiresDate;

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
                                    _newCookieFormKey.currentState.reset();
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
                      child: FlatButton(
                        padding: EdgeInsets.all(15.0),
                        child: Text("Clear cookies"),
                        onPressed: () async {
                          await _cookieManager.deleteCookies(url: url);
                          setState(() {});
                        },
                      ),
                    ),
                    Expanded(
                      child: FlatButton(
                        padding: EdgeInsets.all(15.0),
                        child: Text("Clear all"),
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
        var _webViewController = webViewModel.webViewController;

        return FutureBuilder(
          future: _webViewController.webStorage.localStorage.getItems(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container();
            }

            List<WebStorageItem> webStorageItems = snapshot.data;

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
                      var updateItemValue = await _webViewController
                          .webStorage.localStorage
                          .getItem(key: webStorageItem.key);
                      await _webViewController.webStorage.localStorage
                          .removeItem(key: webStorageItem.key);
                      await _webViewController.webStorage.localStorage
                          .setItem(key: newValue, value: updateItemValue);
                    },
                    initialValue: webStorageItem.key,
                    index: index,
                    trackingEditStatus: localStorageKeyTrackingEdit),
                _buildDataCellEditable(
                    width: constraints.maxWidth / 3,
                    onFieldSubmitted: (newValue) async {
                      await _webViewController.webStorage.localStorage
                          .setItem(key: webStorageItem.key, value: newValue);
                    },
                    initialValue: webStorageItem.value,
                    index: index,
                    trackingEditStatus: localStorageValueTrackingEdit),
                DataCell(IconButton(
                  icon: Icon(Icons.cancel),
                  onPressed: () async {
                    await _webViewController.webStorage.localStorage
                        .removeItem(key: webStorageItem.key);
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
                Container(
                  width: constraints.minWidth,
                  child: DataTable(
                    columnSpacing: 0.0,
                    columns: const <DataColumn>[
                      DataColumn(
                        label: const Text(
                          "Key",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16.0),
                        ),
                      ),
                      DataColumn(
                        label: const Text(
                          "Value",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16.0),
                        ),
                      ),
                      DataColumn(
                        label: const Text(
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
                    _webViewController.webStorage.localStorage
                        .setItem(key: name, value: value);
                  },
                ),
                Container(
                  width: MediaQuery.of(context).size.width,
                  child: FlatButton(
                    padding: EdgeInsets.all(15.0),
                    child: Text("Clear items"),
                    onPressed: () async {
                      await _webViewController.webStorage.localStorage.clear();
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
        var _webViewController = webViewModel.webViewController;

        return FutureBuilder(
          future: _webViewController.webStorage.sessionStorage.getItems(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container();
            }

            List<WebStorageItem> webStorageItems = snapshot.data;

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
                      var updateItemValue = await _webViewController
                          .webStorage.sessionStorage
                          .getItem(key: webStorageItem.key);
                      await _webViewController.webStorage.sessionStorage
                          .removeItem(key: webStorageItem.key);
                      await _webViewController.webStorage.sessionStorage
                          .setItem(key: newValue, value: updateItemValue);
                    },
                    initialValue: webStorageItem.key,
                    index: index,
                    trackingEditStatus: sessionStorageKeyTrackingEdit),
                _buildDataCellEditable(
                    width: constraints.maxWidth / 3,
                    onFieldSubmitted: (newValue) async {
                      await _webViewController.webStorage.sessionStorage
                          .setItem(key: webStorageItem.key, value: newValue);
                    },
                    initialValue: webStorageItem.value,
                    index: index,
                    trackingEditStatus: sessionStorageValueTrackingEdit),
                DataCell(IconButton(
                  icon: Icon(Icons.cancel),
                  onPressed: () async {
                    await _webViewController.webStorage.sessionStorage
                        .removeItem(key: webStorageItem.key);
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
                Container(
                  width: constraints.minWidth,
                  child: DataTable(
                    columnSpacing: 0.0,
                    columns: const <DataColumn>[
                      DataColumn(
                        label: const Text(
                          "Key",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16.0),
                        ),
                      ),
                      DataColumn(
                        label: const Text(
                          "Value",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16.0),
                        ),
                      ),
                      DataColumn(
                        label: const Text(
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
                    await _webViewController.webStorage.sessionStorage
                        .setItem(key: name, value: value);
                    setState(() {});
                  },
                ),
                Container(
                  width: MediaQuery.of(context).size.width,
                  child: FlatButton(
                    padding: EdgeInsets.all(15.0),
                    child: Text("Clear items"),
                    onPressed: () async {
                      await _webViewController.webStorage.sessionStorage
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
        subtitle: Selector<WebViewModel, String>(
          selector: (context, webViewModel) => webViewModel.url,
          builder: (context, url, child) {
            var uri = Uri.parse(url);

            return FutureBuilder(
              future: _webStorageManager.android
                  .getQuotaForOrigin(origin: uri.origin),
              builder: (context, snapshot) {
                return Text(snapshot.hasData ? snapshot.data.toString() : "");
              },
            );
          },
        ),
      ),
      Selector<WebViewModel, String>(
          selector: (context, webViewModel) => webViewModel.url,
          builder: (context, url, child) {
            var uri = Uri.parse(url);

            return ListTile(
              title: const Text("Usage"),
              subtitle: FutureBuilder(
                future: _webStorageManager.android
                    .getUsageForOrigin(origin: uri.origin),
                builder: (context, snapshot) {
                  return Text(snapshot.hasData ? snapshot.data.toString() : "");
                },
              ),
              trailing: IconButton(
                icon: Icon(Icons.clear),
                onPressed: () async {
                  await _webStorageManager.android
                      .deleteOrigin(origin: uri.origin);
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
      future: _webStorageManager.ios
          .fetchDataRecords(dataTypes: IOSWKWebsiteDataType.ALL),
      builder: (context, snapshot) {
        List<IOSWKWebsiteDataRecord> dataRecords =
            snapshot.hasData ? snapshot.data : [];

        var rows = <DataRow>[];

        rows.addAll(dataRecords.map((dataRecord) {
          var textStyle = TextStyle(fontSize: 12.0);

          return DataRow(cells: <DataCell>[
            DataCell(
              Container(
                width: constraints.maxWidth / 3,
                child: Text(dataRecord.displayName,
                    style: textStyle, softWrap: true),
              ),
              onTap: () {
                Clipboard.setData(ClipboardData(text: dataRecord.displayName));
              },
            ),
            DataCell(
              Container(
                width: constraints.maxWidth / 3,
                child: Text(dataRecord.dataTypes.join(", "),
                    style: textStyle, softWrap: true),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      content: Container(
                        child: Text(dataRecord.dataTypes.join(",\n"),
                            style: textStyle, softWrap: true),
                      ),
                    );
                  },
                );
              },
            ),
            DataCell(IconButton(
              icon: Icon(Icons.cancel),
              onPressed: () async {
                await _webStorageManager.ios.removeDataFor(
                    dataTypes: dataRecord.dataTypes, dataRecords: [dataRecord]);
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
            Container(
              width: constraints.minWidth,
              child: DataTable(
                columnSpacing: 0.0,
                columns: const <DataColumn>[
                  DataColumn(
                    label: const Text(
                      "Display Name",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16.0),
                    ),
                  ),
                  DataColumn(
                    label: const Text(
                      "Data Types",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16.0),
                    ),
                  ),
                  DataColumn(
                    label: const Text(
                      "Delete",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16.0),
                    ),
                  ),
                ],
                rows: rows,
              ),
            ),
            Container(
                width: MediaQuery.of(context).size.width,
                child: FlatButton(
                  padding: EdgeInsets.all(15.0),
                  child: Text("Clear all"),
                  onPressed: () async {
                    await _webStorageManager.ios.removeDataModifiedSince(
                        dataTypes: IOSWKWebsiteDataType.ALL,
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

        List<ProtectionSpaceHttpAuthCredentials>
            protectionSpaceHttpAuthCredentials = snapshot.data;

        var textStyle = TextStyle(fontSize: 16.0);

        var dataTables = <Widget>[];

        protectionSpaceHttpAuthCredentials
            .forEach((protectionSpaceHttpAuthCredential) {
          var protectionSpace =
              protectionSpaceHttpAuthCredential.protectionSpace;
          var rows = <DataRow>[];

          rows.addAll(protectionSpaceHttpAuthCredential.credentials
              .map((httpAuthCredential) {
            return DataRow(cells: <DataCell>[
              DataCell(
                Container(
                  width: constraints.maxWidth / 3,
                  child: Text(httpAuthCredential.username,
                      style: textStyle, softWrap: true),
                ),
                onTap: () {
                  Clipboard.setData(
                      ClipboardData(text: httpAuthCredential.username));
                },
              ),
              DataCell(
                Container(
                  width: constraints.maxWidth / 3,
                  child: Text(httpAuthCredential.password,
                      style: textStyle, softWrap: true),
                ),
                onTap: () {
                  Clipboard.setData(
                      ClipboardData(text: httpAuthCredential.password));
                },
              ),
              DataCell(IconButton(
                icon: Icon(Icons.cancel),
                onPressed: () async {
                  await _httpAuthCredentialDatabase.removeHttpAuthCredential(
                      protectionSpace: protectionSpace,
                      credential: httpAuthCredential);
                  setState(() {});
                },
              ))
            ]);
          }).toList());

          dataTables.add(Column(
            children: <Widget>[
              Text("Protection Space", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),),
              SizedBox(height: 10.0,),
              Text(
                  "Protocol: ${protectionSpace.protocol ?? ""}, Host: ${protectionSpace.host ?? ""}, " +
                  "Port: ${protectionSpace.port != null && protectionSpace.port > 0 ? protectionSpace.port.toString() : ""}, " +
                  "Realm: ${protectionSpace.realm ?? ""}"),
              Container(
                  width: constraints.minWidth,
                  child: DataTable(
                    columnSpacing: 0.0,
                    columns: const <DataColumn>[
                      DataColumn(
                        label: const Text(
                          "Username",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16.0),
                        ),
                      ),
                      DataColumn(
                        label: const Text(
                          "Password",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16.0),
                        ),
                      ),
                      DataColumn(
                        label: const Text(
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
        });

        var children = <Widget>[];
        children.addAll(dataTables);
        children.addAll(<Widget>[
          FlatButton(
              padding: EdgeInsets.all(15.0),
              child: Text("Clear all"),
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
      {double width,
      int index,
      List<bool> trackingEditStatus,
      String initialValue,
      Future<void> Function(String newValue) onFieldSubmitted}) {
    return DataCell(
      Container(
          width: width,
          child: Builder(
            builder: (context) {
              return !trackingEditStatus[index]
                  ? Text(
                      initialValue,
                      style: TextStyle(fontSize: 16.0),
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                    )
                  : TextFormField(
                      initialValue: initialValue,
                      autofocus: false,
                      onFieldSubmitted: (newValue) async {
                        if (newValue != initialValue) {
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
      {@required GlobalKey<FormState> formKey,
      @required TextEditingController nameController,
      @required TextEditingController valueController,
      @required String labelName,
      @required String labelValue,
      Function(String name, String value) onAdded}) {
    return Form(
      key: formKey,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.0),
              child: TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: labelName),
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                },
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.only(right: 10.0),
              child: TextFormField(
                controller: valueController,
                decoration: InputDecoration(labelText: labelValue),
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                },
              ),
            ),
          ),
          Container(
              child: FlatButton(
            padding: EdgeInsets.all(15.0),
            child: Text("Add Item"),
            onPressed: () {
              if (formKey.currentState.validate()) {
                setState(() {
                  onAdded(nameController.text, valueController.text);
                  formKey.currentState.reset();
                });
              }
            },
          )),
        ],
      ),
    );
  }
}
