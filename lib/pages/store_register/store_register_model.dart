import 'package:flutter/material.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_model.dart';
import 'package:baul_pandora/pages/store_register/store_register_widget.dart';

class StoreRegisterModel extends FlutterFlowModel<StoreRegisterWidget> {
  // Step 0: User Account (when not logged in)
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Step 1: Store Info
  final storeNameController = TextEditingController();
  final slugController = TextEditingController();
  final phoneController = TextEditingController();

  // Step 2: Visual Identity
  String primaryColorHex = '#6366F1';
  String secondaryColorHex = '#4F46E5';
  String? logoPublicUrl;
  String? bannerPublicUrl;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    storeNameController.dispose();
    slugController.dispose();
    phoneController.dispose();
  }
}
