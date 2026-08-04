enum CommissionFilter { all, paid, rejected }

extension CommissionFilterLabel on CommissionFilter {
  String get label => switch (this) {
    CommissionFilter.all => 'All',
    CommissionFilter.paid => 'Paid',
    CommissionFilter.rejected => 'Rejected',
  };
}

extension CommissionFilterApiStatus on CommissionFilter {
  /// API `status` query value. `null` means no status filter (All).
  String? get apiStatus => switch (this) {
    CommissionFilter.all => null,
    CommissionFilter.paid => 'PAID',
    CommissionFilter.rejected => 'REJECTED',
  };
}
