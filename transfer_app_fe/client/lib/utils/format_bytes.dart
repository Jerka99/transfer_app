String formatBytes(int bytes) {
  const kb = 1024;
  const mb = kb * 1024;
  const gb = mb * 1024;
  const tb = gb * 1024;

  if (bytes >= tb) {
    return '${(bytes / tb).toStringAsFixed(2)} TB';
  } else if (bytes >= gb) {
    return '${(bytes / gb).toStringAsFixed(2)} GB';
  } else {
    return '${(bytes / mb).toStringAsFixed(2)} MB';
  }
}
