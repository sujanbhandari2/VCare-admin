/// File upload categories matching the web agent app.
abstract final class DocumentUploadCategories {
  static const String agent = 'AGENT';
  static const String client = 'CLIENT';
  static const String careTeam = 'CARE_TEAM';
}

/// Key from `GET /files/document-types` for the W-9 option.
const String documentTypeW9Key = 'W9_FORM';

/// Blank IRS W-9 PDF for agents to download, sign, and upload.
const String w9BlankFormUrl = 'https://www.irs.gov/pub/irs-pdf/fw9.pdf';

/// Fallback document type label when the API list is empty or OTHER is missing.
const String defaultDocumentTypeLabel = 'Other';

/// Fallback W-9 document type label when API `details.code` / types list is empty.
const String defaultW9DocumentTypeLabel = 'W-9 Form';
