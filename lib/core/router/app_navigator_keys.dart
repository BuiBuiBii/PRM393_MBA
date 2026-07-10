import 'package:flutter/material.dart';

/// Root navigator — full-screen routes (login, OAuth callback).
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Navigator bên trong MainShell (drawer + app bar).
final mainShellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'mainShell');

/// Navigator bên trong AdminShell.
final adminShellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'adminShell');
