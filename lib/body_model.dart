class Books {
  final List<String> library;
  final List<String> list;
  final int total;

  Books({
    required this.library,
    required this.list,
    required this.total,
  });

  Map<String, dynamic> toJson() {
    return {
      'books': list,
      'library': library,
      'total': total,
    };
  }

  factory Books.fromJson(Map<String, dynamic> json) {
    return Books(
        library: (json['library'] as List<dynamic>)
            .map((e) => e.toString())
            .toList(),
        list:
            (json['books'] as List<dynamic>).map((e) => e.toString()).toList(),
        total: json['total']);
  }
}
