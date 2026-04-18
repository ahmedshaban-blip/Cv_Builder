class PersonalInfo {
  final String fullName;
  final String email;
  final String phone;
  final String? address;
  final String? linkedIn;
  final String? github;
  final String? portfolio;
  final String? jobTitle;

  PersonalInfo({
    required this.fullName,
    required this.email,
    required this.phone,
    this.address,
    this.linkedIn,
    this.github,
    this.portfolio,
    this.jobTitle,
  });

  Map<String, dynamic> toMap() => {
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'address': address,
    'linkedIn': linkedIn,
    'github': github,
    'portfolio': portfolio,
    'jobTitle': jobTitle,
  };

  factory PersonalInfo.fromMap(Map<String, dynamic> map) {
    return PersonalInfo(
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'],
      linkedIn: map['linkedIn'],
      github: map['github'],
      portfolio: map['portfolio'],
      jobTitle: map['jobTitle'],
    );
  }
}