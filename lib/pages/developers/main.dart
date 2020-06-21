import 'package:flutter/material.dart';
import 'package:flutter_browser/pages/developers/javascript_console.dart';
import 'package:flutter_browser/pages/developers/network_info.dart';
import 'package:flutter_browser/pages/developers/storage_manager.dart';

class DevelopersPage extends StatefulWidget {
  DevelopersPage({Key key}) : super(key: key);

  @override
  _DevelopersPageState createState() => _DevelopersPageState();
}

class _DevelopersPageState extends State<DevelopersPage> {

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          bottom: TabBar(
            onTap: (value) {
              FocusScope.of(context).unfocus();
            },
            tabs: [
              Tab(
                icon: Icon(Icons.code),
                text: "JavaScript Console",
              ),
              Tab(
                icon: Icon(Icons.network_check),
                text: "Network Info",
              ),
              Tab(
                icon: Icon(Icons.storage),
                text: "Storage Manager",
              ),
            ],
          ),
          title: Text('Developers'),
        ),
        body: TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            JavaScriptConsole(),
            NetworkInfo(),
            StorageManager(),
          ],
        ),
      ),
    );
  }
}
