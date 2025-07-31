import 'package:example_flutter/pages/overview.dart';
import 'package:example_flutter/util/logging.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';

class Routes {
  static String overviewPage = 'overview';
  static String registrationPage = 'registration';

  static void configureRoutes(Router router) {
    router.notFoundHandler = Handler(
        handlerFunc: (BuildContext context, Map<String, List<String>> params) {
      log('Route was not found $params');
      return null;
    });

    router.define(overviewPage, handler: Handler(
        handlerFunc: (BuildContext context, Map<String, List<String>> params) {
      return OverviewPage();
    }));
  }
}
