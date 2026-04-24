class Validators {
  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return "L'email est requis.";
    final regex = RegExp(r'^[\w.\-+]+@[\w\-]+\.[\w\-.]+$');
    if (!regex.hasMatch(v)) return "Format d'email invalide.";
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return "Le mot de passe est requis.";
    if (v.length < 6) return "6 caractères minimum.";
    return null;
  }

  static String? displayName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return "Le pseudo est requis.";
    if (v.length < 2) return "2 caractères minimum.";
    if (v.length > 30) return "30 caractères maximum.";
    return null;
  }

  static String? required(String? value, [String fieldName = 'Ce champ']) {
    if ((value ?? '').trim().isEmpty) return "$fieldName est requis.";
    return null;
  }
}
