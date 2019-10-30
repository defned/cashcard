import 'package:auto_size_text/auto_size_text.dart';
import 'package:example_flutter/db/datasource.dart';
import 'package:example_flutter/pages/pay.dart';
import 'package:example_flutter/pages/registration.dart';
import 'package:example_flutter/pages/topup.dart';
import 'package:example_flutter/util/extensions.dart';
import 'package:flutter/material.dart';

class OverviewPage extends StatefulWidget {
  /// Constructor
  const OverviewPage({Key key}) : super(key: key);

  @override

  /// State creator
  _OverviewPageState createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage>
    with StateWithLocalization<OverviewPage> {
  AutoSizeGroup group = AutoSizeGroup();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr('title'),
          style: TextStyle(fontSize: 20),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {},
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: Column(
              children: <Widget>[
                createButton(tr('registration'),
                    onTap: jumpTo(RegistrationPage())),
                createButton(tr('topUp'), onTap: jumpTo(TopUpPage())),
                createButton(tr('pay'), onTap: jumpTo(PayPage())),
                createButton(tr('entries'), onTap: jumpTo(DataTableDemo())),
                // createButton(tr('delete'), onTap: jumpTo(DeletePage())),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget createButton(String s, {Null Function() onTap}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: RawMaterialButton(
          fillColor: Colors.lightBlue.shade100,
          onPressed: onTap,
          child: Container(
            height: 250,
            child: Center(
              child: AutoSizeText(s,
                  style: TextStyle(fontSize: 40), maxLines: 1, group: group),
            ),
          ),
        ),
      ),
    );
  }
}
