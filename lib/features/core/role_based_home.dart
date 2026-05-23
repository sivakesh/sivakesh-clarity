import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../navigation/main_navigation.dart';

class RoleBasedHome extends StatelessWidget {
  final UserModel user;

  const RoleBasedHome({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return MainNavigation(user: user);
  }
}
