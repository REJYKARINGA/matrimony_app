class User {
  final int? id;
  final String email;
  final String? phone;
  final String? role;
  final String? status;
  final bool? emailVerified;
  final bool? phoneVerified;
  final DateTime? lastLogin;
  final UserProfile? userProfile;
  final FamilyDetail? familyDetails;
  final Preference? preferences;

  User({
    this.id,
    required this.email,
    this.phone,
    this.role,
    this.status,
    this.emailVerified,
    this.phoneVerified,
    this.lastLogin,
    this.userProfile,
    this.familyDetails,
    this.preferences,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      phone: json['phone'],
      role: json['role'],
      status: json['status'],
      emailVerified: json['email_verified'],
      phoneVerified: json['phone_verified'],
      lastLogin: json['last_login'] != null ? DateTime.parse(json['last_login']) : null,
      userProfile: json['user_profile'] != null ? UserProfile.fromJson(json['user_profile']) : null,
      familyDetails: json['family_details'] != null ? FamilyDetail.fromJson(json['family_details']) : null,
      preferences: json['preferences'] != null ? Preference.fromJson(json['preferences']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'role': role,
      'status': status,
      'email_verified': emailVerified,
      'phone_verified': phoneVerified,
      'last_login': lastLogin?.toIso8601String(),
    };
  }
}

class UserProfile {
  final int? id;
  final int? userId;
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String? gender;
  final int? height;
  final int? weight;
  final String? maritalStatus;
  final String? religion;
  final String? caste;
  final String? subCaste;
  final String? motherTongue;
  final String? profilePicture;
  final String? bio;
  final String? education;
  final String? occupation;
  final double? annualIncome;
  final String? city;
  final String? district;
  final String? county;
  final String? state;
  final String? country;
  final String? postalCode;

  UserProfile({
    this.id,
    this.userId,
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    this.gender,
    this.height,
    this.weight,
    this.maritalStatus,
    this.religion,
    this.caste,
    this.subCaste,
    this.motherTongue,
    this.profilePicture,
    this.bio,
    this.education,
    this.occupation,
    this.annualIncome,
    this.city,
    this.district,
    this.county,
    this.state,
    this.country,
    this.postalCode,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      userId: json['user_id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      dateOfBirth: json['date_of_birth'] != null ? DateTime.parse(json['date_of_birth']) : null,
      gender: json['gender'],
      height: json['height'],
      weight: json['weight'],
      maritalStatus: json['marital_status'],
      religion: json['religion'],
      caste: json['caste'],
      subCaste: json['sub_caste'],
      motherTongue: json['mother_tongue'],
      profilePicture: json['profile_picture'],
      bio: json['bio'],
      education: json['education'],
      occupation: json['occupation'],
      annualIncome: json['annual_income'] != null ? double.tryParse(json['annual_income'].toString()) : null,
      city: json['city'],
      district: json['district'],
      county: json['county'],
      state: json['state'],
      country: json['country'],
      postalCode: json['postal_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'height': height,
      'weight': weight,
      'marital_status': maritalStatus,
      'religion': religion,
      'caste': caste,
      'sub_caste': subCaste,
      'mother_tongue': motherTongue,
      'profile_picture': profilePicture,
      'bio': bio,
      'education': education,
      'occupation': occupation,
      'annual_income': annualIncome,
      'city': city,
      'district': district,
      'county': county,
      'state': state,
      'country': country,
      'postal_code': postalCode,
    };
  }

  int? get age {
    if (dateOfBirth != null) {
      var today = DateTime.now();
      var age = today.year - dateOfBirth!.year;
      if (today.month < dateOfBirth!.month ||
          (today.month == dateOfBirth!.month && today.day < dateOfBirth!.day)) {
        age--;
      }
      return age;
    }
    return null;
  }
}

class FamilyDetail {
  final int? id;
  final int? userId;
  final String? fatherName;
  final String? fatherOccupation;
  final String? motherName;
  final String? motherOccupation;
  final int? siblings;
  final String? familyType;
  final String? familyStatus;
  final String? familyLocation;

  FamilyDetail({
    this.id,
    this.userId,
    this.fatherName,
    this.fatherOccupation,
    this.motherName,
    this.motherOccupation,
    this.siblings,
    this.familyType,
    this.familyStatus,
    this.familyLocation,
  });

  factory FamilyDetail.fromJson(Map<String, dynamic> json) {
    return FamilyDetail(
      id: json['id'],
      userId: json['user_id'],
      fatherName: json['father_name'],
      fatherOccupation: json['father_occupation'],
      motherName: json['mother_name'],
      motherOccupation: json['mother_occupation'],
      siblings: json['siblings'],
      familyType: json['family_type'],
      familyStatus: json['family_status'],
      familyLocation: json['family_location'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'father_name': fatherName,
      'father_occupation': fatherOccupation,
      'mother_name': motherName,
      'mother_occupation': motherOccupation,
      'siblings': siblings,
      'family_type': familyType,
      'family_status': familyStatus,
      'family_location': familyLocation,
    };
  }
}

class Preference {
  final int? id;
  final int? userId;
  final int? minAge;
  final int? maxAge;
  final int? minHeight;
  final int? maxHeight;
  final String? maritalStatus;
  final String? religion;
  final List<String>? caste;
  final String? education;
  final String? occupation;
  final double? minIncome;
  final double? maxIncome;
  final int? maxDistance;
  final List<String>? preferredLocations;

  Preference({
    this.id,
    this.userId,
    this.minAge,
    this.maxAge,
    this.minHeight,
    this.maxHeight,
    this.maritalStatus,
    this.religion,
    this.caste,
    this.education,
    this.occupation,
    this.minIncome,
    this.maxIncome,
    this.maxDistance,
    this.preferredLocations,
  });

  factory Preference.fromJson(Map<String, dynamic> json) {
    List<String>? casteList;
    if (json['caste'] != null) {
      if (json['caste'] is List) {
        casteList = List<String>.from(json['caste']);
      } else {
        casteList = [json['caste'].toString()];
      }
    }

    return Preference(
      id: json['id'],
      userId: json['user_id'],
      minAge: json['min_age'],
      maxAge: json['max_age'],
      minHeight: json['min_height'],
      maxHeight: json['max_height'],
      maritalStatus: json['marital_status'],
      religion: json['religion'],
      caste: casteList,
      education: json['education'],
      occupation: json['occupation'],
      minIncome: json['min_income'] != null ? double.tryParse(json['min_income'].toString()) : null,
      maxIncome: json['max_income'] != null ? double.tryParse(json['max_income'].toString()) : null,
      maxDistance: json['max_distance'],
      preferredLocations: json['preferred_locations'] != null 
          ? List<String>.from(json['preferred_locations']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'min_age': minAge,
      'max_age': maxAge,
      'min_height': minHeight,
      'max_height': maxHeight,
      'marital_status': maritalStatus,
      'religion': religion,
      'caste': caste,
      'education': education,
      'occupation': occupation,
      'min_income': minIncome,
      'max_income': maxIncome,
      'max_distance': maxDistance,
      'preferred_locations': preferredLocations,
    };
  }
}