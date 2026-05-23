// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

void removeWebLoaderSafely() {
  try {
    final loader = html.document.getElementById('loader');
    if (loader == null) return;
    loader.style.opacity = '0';
    Future<void>.delayed(const Duration(milliseconds: 240), () {
      loader.remove();
    });
  } catch (_) {
    // Fail-safe: never block app if loader removal fails.
  }
}
