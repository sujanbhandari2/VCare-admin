/// W-9 upload eligibility matching the web agent documents flow.
bool canUploadW9Document({
  required bool isStatsFetching,
  required bool? isAgencyAssociated,
  required bool hasAgencyGroup,
}) {
  if (isStatsFetching) return false;
  if (hasAgencyGroup) return false;
  return !(isAgencyAssociated ?? false);
}
