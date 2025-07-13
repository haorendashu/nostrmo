class NwcTransaction {
  String? type;
  String? invoice;
  String? description;
  String? descriptionHash;
  String? preimage;
  String? paymentHash;
  int? amount;
  int? feesPaid;
  int? createdAt;
  int? expiresAt;
  int? settledAt;

  NwcTransaction(
      {this.type,
      this.invoice,
      this.description,
      this.descriptionHash,
      this.preimage,
      this.paymentHash,
      this.amount,
      this.feesPaid,
      this.createdAt,
      this.expiresAt,
      this.settledAt});

  NwcTransaction.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    invoice = json['invoice'];
    description = json['description'];
    descriptionHash = json['description_hash'];
    preimage = json['preimage'];
    paymentHash = json['payment_hash'];
    amount = json['amount'];
    feesPaid = json['fees_paid'];
    createdAt = json['created_at'];
    expiresAt = json['expires_at'];
    settledAt = json['settled_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    data['invoice'] = this.invoice;
    data['description'] = this.description;
    data['description_hash'] = this.descriptionHash;
    data['preimage'] = this.preimage;
    data['payment_hash'] = this.paymentHash;
    data['amount'] = this.amount;
    data['fees_paid'] = this.feesPaid;
    data['created_at'] = this.createdAt;
    data['expires_at'] = this.expiresAt;
    data['settled_at'] = this.settledAt;
    return data;
  }
}
