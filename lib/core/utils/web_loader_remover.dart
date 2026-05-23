import 'web_loader_remover_stub.dart'
    if (dart.library.html) 'web_loader_remover_web.dart' as impl;

void removeWebLoaderSafely() {
  impl.removeWebLoaderSafely();
}
