class ContactInfo {
  final String? email;
  final String? phone;
  final bool isContactUnlocked;

  ContactInfo({
    this.email,
    this.phone,
    this.isContactUnlocked = false,
  });

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      isContactUnlocked: json['is_contact_unlocked'] == true || json['is_contact_unlocked'] == 1,
    );
  }
}

class User {
  final int? id;
  final String? matrimonyId;
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
  final List<ProfilePhoto>? profilePhotos;
  final UserVerification? verification;
  final double? distance;
  final String? referenceCode;
  final ContactInfo? contactInfo;
  final List<dynamic>? personalities;
  final List<dynamic>? interests;

  User({
    this.id,
    this.matrimonyId,
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
    this.profilePhotos,
    this.verification,
    this.distance,
    this.referenceCode,
    this.contactInfo,
    this.personalities,
    this.interests,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Parse contact_info block if present (returned when viewing other profiles)
    final contactInfoJson = json['contact_info'] as Map<String, dynamic>?;
    final contactInfo = contactInfoJson != null ? ContactInfo.fromJson(contactInfoJson) : null;

    return User(
      id: json['id'],
      matrimonyId: json['matrimony_id']?.toString(),
      // Prefer contact_info email/phone, fall back to top-level fields (own profile)
      email: contactInfoJson?['email']?.toString() ?? json['email']?.toString() ?? '',
      phone: contactInfoJson?['phone']?.toString() ?? json['phone']?.toString(),
      role: json['role']?.toString(),
      status: json['status']?.toString(),
      emailVerified: json['email_verified'] == 1 || json['email_verified'] == true,
      phoneVerified: json['phone_verified'] == 1 || json['phone_verified'] == true,
      lastLogin: json['last_login'] != null ? DateTime.parse(json['last_login']) : null,
      userProfile: json['user_profile'] != null ? UserProfile.fromJson(json['user_profile']) : null,
      familyDetails: json['family_details'] != null ? FamilyDetail.fromJson(json['family_details']) : null,
      preferences: json['preferences'] != null ? Preference.fromJson(json['preferences']) : null,
      profilePhotos: json['profile_photos'] != null 
          ? (json['profile_photos'] as List).map((i) => ProfilePhoto.fromJson(i)).toList()
          : null,
      verification: json['verification'] != null ? UserVerification.fromJson(json['verification']) : null,
      distance: json['distance'] != null ? double.tryParse(json['distance'].toString()) : null,
      referenceCode: json['reference_code']?.toString(),
      contactInfo: contactInfo,
      personalities: json['personalities'] != null ? List<dynamic>.from(json['personalities']) : null,
      interests: json['interests'] != null ? List<dynamic>.from(json['interests']) : null,
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

  /// Get the best image to display for this user
  String? get displayImage {
    if (profilePhotos != null && profilePhotos!.isNotEmpty) {
      try {
        final primary = profilePhotos!.firstWhere(
          (p) => p.isPrimary == true,
          orElse: () => profilePhotos!.first,
        );
        return primary.photoUrl;
      } catch (e) {
        return profilePhotos!.first.photoUrl;
      }
    }
    return userProfile?.profilePicture;
  }
}

class UserVerification {
  final int? id;
  final int? userId;
  final String? status;
  final String? rejectionReason;
  final DateTime? verifiedAt;

  UserVerification({
    this.id,
    this.userId,
    this.status,
    this.rejectionReason,
    this.verifiedAt,
  });

  factory UserVerification.fromJson(Map<String, dynamic> json) {
    return UserVerification(
      id: json['id'],
      userId: json['user_id'],
      status: json['status']?.toString(),
      rejectionReason: json['rejection_reason']?.toString(),
      verifiedAt: json['verified_at'] != null ? DateTime.parse(json['verified_at']) : null,
    );
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
  final int? religionId;
  final String? caste;
  final int? casteId;
  final String? subCaste;
  final int? subCasteId;
  final String? motherTongue;
  final String? profilePicture;
  final String? bio;
  final String? education;
  final int? educationId;
  final String? occupation;
  final int? occupationId;
  final double? annualIncome;
  final String? city;
  final String? district;
  final String? county;
  final String? state;
  final String? country;
  final String? postalCode;
  final double? latitude;
  final double? longitude;
  final bool? drugAddiction;
  final String? smoke;
  final String? alcohol;
  final bool? isActiveVerified;
  final DateTime? createdAt;

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
    this.religionId,
    this.caste,
    this.casteId,
    this.subCaste,
    this.subCasteId,
    this.motherTongue,
    this.profilePicture,
    this.bio,
    this.education,
    this.educationId,
    this.occupation,
    this.occupationId,
    this.annualIncome,
    this.city,
    this.district,
    this.county,
    this.state,
    this.country,
    this.postalCode,
    this.latitude,
    this.longitude,
    this.drugAddiction,
    this.smoke,
    this.alcohol,
    this.isActiveVerified,
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      userId: json['user_id'],
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      dateOfBirth: json['date_of_birth'] != null ? DateTime.parse(json['date_of_birth']) : null,
      gender: json['gender']?.toString(),
      height: json['height'],
      weight: json['weight'],
      maritalStatus: json['marital_status']?.toString(),
      religion: json['religion']?.toString() ?? json['religion_model']?['name']?.toString(),
      religionId: json['religion_id'],
      caste: json['caste']?.toString() ?? json['caste_model']?['name']?.toString(),
      casteId: json['caste_id'],
      subCaste: json['sub_caste']?.toString() ?? json['sub_caste_model']?['name']?.toString(),
      subCasteId: json['sub_caste_id'],
      motherTongue: json['mother_tongue']?.toString(),
      profilePicture: json['profile_picture']?.toString(),
      bio: json['bio']?.toString(),
      education: json['education']?.toString() ?? json['education_model']?['name']?.toString(),
      educationId: json['education_id'],
      occupation: json['occupation']?.toString() ?? json['occupation_model']?['name']?.toString(),
      occupationId: json['occupation_id'],
      annualIncome: json['annual_income'] != null ? double.tryParse(json['annual_income'].toString()) : null,
      city: json['city']?.toString(),
      district: json['district']?.toString(),
      county: json['county']?.toString(),
      state: json['state']?.toString(),
      country: json['country']?.toString(),
      postalCode: json['postal_code']?.toString(),
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      drugAddiction: json['drug_addiction'] == 1 || json['drug_addiction'] == true,
      smoke: json['smoke']?.toString(),
      alcohol: json['alcohol']?.toString(),
      isActiveVerified: json['is_active_verified'] == 1 || json['is_active_verified'] == true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
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
      'religion_id': religionId,
      'caste_id': casteId,
      'sub_caste_id': subCasteId,
      'mother_tongue': motherTongue,
      'profile_picture': profilePicture,
      'bio': bio,
      'education_id': educationId,
      'occupation_id': occupationId,
      'annual_income': annualIncome,
      'city': city,
      'district': district,
      'county': county,
      'state': state,
      'country': country,
      'postal_code': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      'drug_addiction': drugAddiction,
      'smoke': smoke,
      'alcohol': alcohol,
      'is_active_verified': isActiveVerified,
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
  final int? elderSister;
  final int? elderBrother;
  final int? youngerSister;
  final int? youngerBrother;
  final bool? fatherAlive;
  final bool? motherAlive;
  final bool? isDisabled;
  final String? guardian;

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
    this.elderSister,
    this.elderBrother,
    this.youngerSister,
    this.youngerBrother,
    this.fatherAlive,
    this.motherAlive,
    this.isDisabled,
    this.guardian,
  });

  factory FamilyDetail.fromJson(Map<String, dynamic> json) {
    return FamilyDetail(
      id: json['id'],
      userId: json['user_id'],
      fatherName: json['father_name']?.toString(),
      fatherOccupation: json['father_occupation']?.toString(),
      motherName: json['mother_name']?.toString(),
      motherOccupation: json['mother_occupation']?.toString(),
      siblings: json['siblings'],
      familyType: json['family_type']?.toString(),
      familyStatus: json['family_status']?.toString(),
      familyLocation: json['family_location']?.toString(),
      elderSister: json['elder_sister'],
      elderBrother: json['elder_brother'],
      youngerSister: json['younger_sister'],
      youngerBrother: json['younger_brother'],
      fatherAlive: json['father_alive'] == 1 || json['father_alive'] == true,
      motherAlive: json['mother_alive'] == 1 || json['mother_alive'] == true,
      isDisabled: json['is_disabled'] == 1 || json['is_disabled'] == true,
      guardian: json['guardian']?.toString(),
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
      'elder_sister': elderSister,
      'elder_brother': elderBrother,
      'younger_sister': youngerSister,
      'younger_brother': youngerBrother,
      'father_alive': fatherAlive,
      'mother_alive': motherAlive,
      'is_disabled': isDisabled,
      'guardian': guardian,
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
  final int? religionId;
  final String? religionName;
  final List<String>? caste;
  final List<int>? casteIds;
  final List<String>? casteNames;
  final List<int>? subCasteIds;
  final List<String>? subCasteNames;
  final dynamic education;
  final List<int>? educationIds;
  final List<String>? educationNames;
  final dynamic occupation;
  final List<int>? occupationIds;
  final List<String>? occupationNames;
  final double? minIncome;
  final double? maxIncome;
  final int? maxDistance;
  final List<String>? preferredLocations;
  final String? drugAddiction;
  final List<String>? smoke;
  final List<String>? alcohol;

  Preference({
    this.id,
    this.userId,
    this.minAge,
    this.maxAge,
    this.minHeight,
    this.maxHeight,
    this.maritalStatus,
    this.religion,
    this.religionId,
    this.religionName,
    this.caste,
    this.casteIds,
    this.casteNames,
    this.subCasteIds,
    this.subCasteNames,
    this.education,
    this.educationIds,
    this.educationNames,
    this.occupation,
    this.occupationIds,
    this.occupationNames,
    this.minIncome,
    this.maxIncome,
    this.maxDistance,
    this.preferredLocations,
    this.drugAddiction,
    this.smoke,
    this.alcohol,
  });

  factory Preference.fromJson(Map<String, dynamic> json) {
    List<String>? casteList;
    if (json['caste'] != null) {
      if (json['caste'] is List) {
        casteList = List<String>.from(json['caste'].map((e) => e.toString()));
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
      maritalStatus: json['marital_status']?.toString(),
      religion: json['religion']?.toString(),
      religionId: json['religion_id'],
      religionName: json['religion_name']?.toString(),
      caste: casteList,
      casteIds: json['caste_ids'] != null ? List<int>.from(json['caste_ids']) : null,
      casteNames: json['caste_names'] != null ? List<String>.from(json['caste_names']) : null,
      subCasteIds: json['sub_caste_ids'] != null ? List<int>.from(json['sub_caste_ids']) : null,
      subCasteNames: json['sub_caste_names'] != null ? List<String>.from(json['sub_caste_names']) : null,
      education: json['education'],
      educationIds: json['education_ids'] != null ? List<int>.from(json['education_ids']) : null,
      educationNames: json['education_names'] != null ? List<String>.from(json['education_names']) : null,
      occupation: json['occupation'],
      occupationIds: json['occupation_ids'] != null ? List<int>.from(json['occupation_ids']) : null,
      occupationNames: json['occupation_names'] != null ? List<String>.from(json['occupation_names']) : null,
      minIncome: json['min_income'] != null ? double.tryParse(json['min_income'].toString()) : null,
      maxIncome: json['max_income'] != null ? double.tryParse(json['max_income'].toString()) : null,
      maxDistance: json['max_distance'],
      preferredLocations: json['preferred_locations'] != null 
          ? List<String>.from(json['preferred_locations'].map((e) => e.toString())) 
          : null,
      drugAddiction: json['drug_addiction']?.toString(),
      smoke: json['smoke'] != null 
          ? (json['smoke'] is List 
              ? List<String>.from(json['smoke'].map((e) => e.toString())) 
              : [json['smoke'].toString()]) 
          : null,
      alcohol: json['alcohol'] != null 
          ? (json['alcohol'] is List 
              ? List<String>.from(json['alcohol'].map((e) => e.toString())) 
              : [json['alcohol'].toString()]) 
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
      'religion_id': religionId,
      'caste_ids': casteIds,
      'sub_caste_ids': subCasteIds,
      'education_ids': educationIds,
      'occupation_ids': occupationIds,
      'min_income': minIncome,
      'max_income': maxIncome,
      'max_distance': maxDistance,
      'preferred_locations': preferredLocations,
      'drug_addiction': drugAddiction,
      'smoke': smoke,
      'alcohol': alcohol,
    };
  }
}

class ProfilePhoto {
  final int? id;
  final int? userId;
  final String? photoUrl;
  final String? fullPhotoUrl;
  final bool? isPrimary;

  ProfilePhoto({
    this.id,
    this.userId,
    this.photoUrl,
    this.fullPhotoUrl,
    this.isPrimary,
  });

  factory ProfilePhoto.fromJson(Map<String, dynamic> json) {
    return ProfilePhoto(
      id: json['id'],
      userId: json['user_id'],
      photoUrl: json['photo_url']?.toString(),
      fullPhotoUrl: json['full_photo_url']?.toString(),
      isPrimary: json['is_primary'] == 1 || json['is_primary'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'photo_url': photoUrl,
      'full_photo_url': fullPhotoUrl,
      'is_primary': isPrimary,
    };
  }
}