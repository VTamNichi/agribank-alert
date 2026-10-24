import 'dart:convert';

class TransactionAlert {
  final String eventId;
  final String deviceId;
  final double amount;
  final String currency;
  final String direction; // 'credit' (tiền vào) or 'debit' (tiền ra)
  final DateTime occurredAt;
  final String? senderName;
  final String? accountNumber;
  final String? referenceCode;
  final String rawTitle;
  final String rawContent;
  final String bank;
  final String? spokenText;
  final bool isRead;
  final bool isDuplicate;

  TransactionAlert({
    required this.eventId,
    required this.deviceId,
    required this.amount,
    this.currency = 'VND',
    this.direction = 'credit',
    required this.occurredAt,
    this.senderName,
    this.accountNumber,
    this.referenceCode,
    required this.rawTitle,
    required this.rawContent,
    this.bank = 'Agribank',
    this.spokenText,
    this.isRead = false,
    this.isDuplicate = false,
  });

  bool get isCredit => direction.toLowerCase() == 'credit';

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'deviceId': deviceId,
      'amount': amount,
      'currency': currency,
      'direction': direction,
      'occurredAt': occurredAt.toIso8601String(),
      'senderName': senderName,
      'accountNumber': accountNumber,
      'referenceCode': referenceCode,
      'rawTitle': rawTitle,
      'rawContent': rawContent,
      'bank': bank,
      'spokenText': spokenText,
      'isRead': isRead,
      'isDuplicate': isDuplicate,
    };
  }

  factory TransactionAlert.fromMap(Map<String, dynamic> map) {
    return TransactionAlert(
      eventId: map['eventId']?.toString() ?? '',
      deviceId: map['deviceId']?.toString() ?? '',
      amount: (map['amount'] is num) ? (map['amount'] as num).toDouble() : double.tryParse(map['amount']?.toString() ?? '0') ?? 0.0,
      currency: map['currency']?.toString() ?? 'VND',
      direction: map['direction']?.toString() ?? 'credit',
      occurredAt: map['occurredAt'] != null
          ? (DateTime.tryParse(map['occurredAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      senderName: map['senderName']?.toString(),
      accountNumber: map['accountNumber']?.toString(),
      referenceCode: map['referenceCode']?.toString(),
      rawTitle: map['rawTitle']?.toString() ?? '',
      rawContent: map['rawContent']?.toString() ?? '',
      bank: map['bank']?.toString() ?? 'Agribank',
      spokenText: map['spokenText']?.toString(),
      isRead: map['isRead'] == true,
      isDuplicate: map['isDuplicate'] == true,
    );
  }

  String toJson() => json.encode(toMap());

  factory TransactionAlert.fromJson(String source) =>
      TransactionAlert.fromMap(json.decode(source) as Map<String, dynamic>);

  TransactionAlert copyWith({
    String? eventId,
    String? deviceId,
    double? amount,
    String? currency,
    String? direction,
    DateTime? occurredAt,
    String? senderName,
    String? accountNumber,
    String? referenceCode,
    String? rawTitle,
    String? rawContent,
    String? bank,
    String? spokenText,
    bool? isRead,
    bool? isDuplicate,
  }) {
    return TransactionAlert(
      eventId: eventId ?? this.eventId,
      deviceId: deviceId ?? this.deviceId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      direction: direction ?? this.direction,
      occurredAt: occurredAt ?? this.occurredAt,
      senderName: senderName ?? this.senderName,
      accountNumber: accountNumber ?? this.accountNumber,
      referenceCode: referenceCode ?? this.referenceCode,
      rawTitle: rawTitle ?? this.rawTitle,
      rawContent: rawContent ?? this.rawContent,
      bank: bank ?? this.bank,
      spokenText: spokenText ?? this.spokenText,
      isRead: isRead ?? this.isRead,
      isDuplicate: isDuplicate ?? this.isDuplicate,
    );
  }
}
