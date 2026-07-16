enum DocumentFilter {
  all('All'),
  images('Images'),
  voice('Voice'),
  files('Files');

  const DocumentFilter(this.label);

  final String label;
}
