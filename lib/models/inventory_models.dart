// lib/models/inventory_models.dart

// We need to avoid exporting both at the same time to prevent ambiguity.
// Instead of complex conditional exports, we will have a specific file for each target
// and use conditional imports in the files that need them.

// For now, let's just make this file export the Web version,
// and we will rely on IO-specific files to import the Isar version directly.

export 'web_inventory_models.dart';
