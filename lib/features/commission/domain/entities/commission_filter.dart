enum CommissionFilter {
  all,
  paid,
  earned,
  failed,
}

extension CommissionFilterLabel on CommissionFilter {
  String get label => switch (this) {
        CommissionFilter.all => 'All',
        CommissionFilter.paid => 'Paid',
        CommissionFilter.earned => 'Earned',
        CommissionFilter.failed => 'Failed',
      };
}
