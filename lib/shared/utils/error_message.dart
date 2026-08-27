String readableError(Object error) {
  return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
}
