import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provides the active locale — defaults to English, loads from SharedPreferences
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en', '')) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('app_locale') ?? 'en';
    state = Locale(code, '');
  }

  Future<void> setLocale(String languageCode) async {
    if (state.languageCode == languageCode) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_locale', languageCode);
    state = Locale(languageCode, '');
  }
}

// Provides the compiled translations for the current locale
final localizationProvider = Provider<AppLocalizations>((ref) {
  final locale = ref.watch(localeProvider);
  return AppLocalizations(locale);
});

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Splash screen
      'splash_starting': 'Starting Mars…',
      'splash_loading_engine': 'Loading AI engine…',
      'splash_error_load': 'Failed to load model.',

      // Profile creation
      'setup_title': 'Setup Profile',
      'setup_subtitle': 'Tell us a bit about yourself so Mars AI can personalize your experience.',
      'setup_native_country': 'Native Country',
      'setup_host_country': 'Host Country',
      'setup_native_lang': 'Native Language',
      'setup_status': 'Status',
      'setup_continue': 'Continue',
      'setup_err_enter': 'Please enter',
      'setup_status_immigrant': 'Immigrant',
      'setup_status_student': 'International Student',
      'setup_status_expat': 'Expat / Professional',
      'setup_status_other': 'Other',

      // Model download screen
      'download_title_setup': 'One-time Setup',
      'download_subtitle_setup': 'Mars needs to download the AI model (~2 GB).\nThis happens once. The model runs fully offline after this.',
      'download_title_active': 'Downloading AI Model',
      'download_subtitle_active': 'Please connect to Wi-Fi. Downloading your smart assistant to work offline.',
      'download_title_complete': 'Download Complete',
      'download_subtitle_complete': 'Initializing the AI engine…',
      'download_title_error': 'Download Failed',
      'download_subtitle_error': 'Check your connection and try again.',
      'download_btn_start': 'Download Model (~2 GB)',
      'download_btn_active': 'Downloading...',
      'download_btn_retry': 'Retry Download',
      'download_title_prep_engine': 'Preparing AI Engine',
      'download_subtitle_prep_engine': 'Loading model into memory…',

      // Navigation tabs
      'nav_home': 'Home',
      'nav_history': 'History',
      'nav_settings': 'Settings',

      // Home Screen
      'home_title': 'Mars',
      'home_subtitle': 'Your offline AI companion for migration',

      // Agent selection cards
      'agent_psychology_name': 'Psychology',
      'agent_psychology_sub': 'Anxiety & Withdrawal',
      'agent_psychology_prompt':
          'You are a grounded, empathetic psychological AI assistant for immigrants. '
          'The user is experiencing anxiety, homesickness, or withdrawal. '
          'Use grounding techniques, validate their emotions, and provide calming, '
          'bite-sized coping mechanisms. Do not give medical diagnoses. Respond in English only.',

      'agent_social_name': 'Social',
      'agent_social_sub': 'Isolation & Cultural Conflict',
      'agent_social_prompt':
          'You are a cultural integration AI. '
          'The user is facing social isolation or a cultural misunderstanding. '
          'Explain the host country\'s social norms logically without judging the '
          'user\'s native culture. Provide actionable icebreakers and polite ways '
          'to handle conflict. Respond in English only.',

      'agent_language_name': 'Language',
      'agent_language_sub': 'Communication Avoidance',
      'agent_language_prompt':
          'You are a supportive linguistic AI. '
          'The user is afraid to speak due to a language barrier. '
          'Provide phonetic pronunciations, simple sentence structures, and '
          'confidence-building phrases. Keep explanations brief and focused on '
          'practical communication. Respond in English only.',

      'agent_biological_name': 'Biological',
      'agent_biological_sub': 'Fatigue & Chronic Stress',
      'agent_biological_prompt':
          'You are a wellness AI assistant. '
          'The user is suffering from physical symptoms of migration stress like '
          'fatigue or sleep disruption. Suggest actionable, non-medical daily '
          'routines, sleep hygiene tips, and stress-reduction habits. Respond in English only.',

      // Chat screen
      'chat_thinking': 'Thinking…',
      'chat_online': 'Online',
      'chat_reset_title': 'Reset Conversation',
      'chat_reset_confirm': 'Are you sure you want to reset this chat history?',
      'chat_cancel': 'Cancel',
      'chat_reset': 'Reset',
      'chat_type_msg': 'Type a message...',
      'chat_empty_prompt': 'How can I help you?',

      // Settings screen
      'settings_title': 'Settings',
      'settings_app_lang': 'App Language',
      'settings_your_profile': 'Your Profile',
      'settings_edit': 'Edit',
      'settings_no_profile': 'No profile data',
      'settings_clear_history': 'Clear Chat History',
      'settings_clear_history_sub': 'Delete all conversations from this device',
      'settings_check_updates': 'Check for Model Updates',
      'settings_check_updates_sub': 'Download the latest version of Mars AI',
      'settings_reset_profile': 'Reset App Profile',
      'settings_reset_profile_sub': 'Clear setup data to start over',
      'settings_updates_latest': 'You are on the latest model version.',
      'settings_history_cleared': 'Chat history cleared.',
      'settings_accessibility': 'Accessibility',
      'settings_accessibility_sub': 'Change font sizes, colors, and brightness',
      'settings_font_size': 'Font Size',
      'settings_color_theme': 'Color Theme',
      'settings_brightness': 'Theme & Contrast',
      'font_small': 'Small',
      'font_medium': 'Medium',
      'font_large': 'Large',
      'font_xlarge': 'Extra Large',
      'theme_purple': 'Deep Purple',
      'theme_teal': 'Teal Accent',
      'theme_blue': 'Ocean Blue',
      'theme_green': 'Emerald Green',
      'bright_dark': 'Classic Dark',
      'bright_amoled': 'Amoled Black',
      'bright_light': 'Clean Light',

      // History & Bookmarks Screen
      'history_title': 'History & Bookmarks',
      'history_bookmarks': 'Bookmarks',
      'history_conversations': 'Recent Conversations',
      'history_mock_bookmark_1': 'Job Interview Tips (Psychology)',
      'history_mock_bookmark_1_sub': 'Saved yesterday',
      'history_mock_bookmark_2': 'Grocery Shopping Phrases',
      'history_mock_bookmark_2_sub': 'Saved 3 days ago',
      'history_mock_chat_1': 'Visa Application Help',
      'history_mock_chat_1_sub': 'Social Agent • Today',
      'history_mock_chat_2': 'Local Cultural Etiquette',
      'history_mock_chat_2_sub': 'Social Agent • Yesterday',
      'history_mock_chat_3': 'Healthcare System Info',
      'history_mock_chat_3_sub': 'Biological Agent • Last week',
    },
    'ar': {
      // Splash screen
      'splash_starting': 'جاري تشغيل مارس…',
      'splash_loading_engine': 'جاري تحميل محرك الذكاء الاصطناعي…',
      'splash_error_load': 'فشل في تحميل النموذج.',

      // Profile creation
      'setup_title': 'إعداد الملف الشخصي',
      'setup_subtitle': 'أخبرنا قليلاً عن نفسك حتى يتمكن مارس من تخصيص تجربتك وتحسين جودة الدعم اللغوي والنفسي.',
      'setup_native_country': 'البلد الأصلي',
      'setup_host_country': 'البلد المضيف',
      'setup_native_lang': 'اللغة الأم',
      'setup_status': 'الحالة',
      'setup_continue': 'استمرار',
      'setup_err_enter': 'يرجى إدخال',
      'setup_status_immigrant': 'مهاجر',
      'setup_status_student': 'طالب دولي',
      'setup_status_expat': 'مغترب / مهني',
      'setup_status_other': 'آخر',

      // Model download screen
      'download_title_setup': 'إعداد لمرة واحدة',
      'download_subtitle_setup': 'يحتاج مارس إلى تنزيل نموذج الذكاء الاصطناعي الخاص بالهاتف (~2 جيجابايت).\nيحدث هذا لمرة واحدة فقط. بعد ذلك، سيعمل النموذج بالكامل دون اتصال بالإنترنت.',
      'download_title_active': 'جاري تنزيل نموذج الذكاء الاصطناعي',
      'download_subtitle_active': 'يرجى الاتصال بشبكة Wi-Fi. يتم حالياً تنزيل مساعدك الذكي ليعمل بدون اتصال بالإنترنت.',
      'download_title_complete': 'اكتمل التنزيل',
      'download_subtitle_complete': 'جاري بدء تشغيل محرك الذكاء الاصطناعي المحلي…',
      'download_title_error': 'فشل التنزيل',
      'download_subtitle_error': 'تحقق من اتصالك بالإنترنت ثم حاول مرة أخرى.',
      'download_btn_start': 'تنزيل النموذج (~2 جيجابايت)',
      'download_btn_active': 'جاري التنزيل...',
      'download_btn_retry': 'إعادة محاولة التنزيل',
      'download_title_prep_engine': 'جاري تحضير محرك الذكاء الاصطناعي',
      'download_subtitle_prep_engine': 'جاري تحميل النموذج في الذاكرة لتشغيل آمن وسريع…',

      // Navigation tabs
      'nav_home': 'الرئيسية',
      'nav_history': 'السجل',
      'nav_settings': 'الإعدادات',

      // Home Screen
      'home_title': 'مارس',
      'home_subtitle': 'مساعدك الذكي غير المتصل بالإنترنت للتكيف مع الهجرة والتكامل الاجتماعي',

      // Agent selection cards
      'agent_psychology_name': 'الدعم النفسي',
      'agent_psychology_sub': 'القلق والانسحاب والضغوطات',
      'agent_psychology_prompt':
          'أنت مساعد ذكاء اصطناعي نفسي متعاطف ورصين للمهاجرين. '
          'المستخدم يعاني من القلق، الحنين إلى الوطن، أو الانسحاب والضيق. '
          'استخدم تقنيات التهدئة والتثبيت البدني والذهني، وتفهّم مشاعرهم تماماً، وقدم آليات عملية مبسطة وموجزة للتكيف والتعامل مع الضغوط. '
          'لا تقدم أي تشخيصات طبية أو علاجية. أجب باللغة العربية الفصحى وبصيغة لطيفة ومريحة حصرياً.',

      'agent_social_name': 'التكامل الاجتماعي',
      'agent_social_sub': 'العزلة، التقاليد والصدام الثقافي',
      'agent_social_prompt':
          'أنت مرشد ذكاء اصطناعي متميز للتكامل الثقافي والاجتماعي للمغتربين والمهاجرين. '
          'المستخدم يواجه عزلة اجتماعية، صعوبة في التأقلم أو سوء فهم ثقافي في البلد المضيف. '
          'اشرح الأعراف الاجتماعية، العادات والتقاليد في البلد المضيف بأسلوب منطقي وموضوعي دون التقليل من شأن ثقافة المستخدم الأصلية. '
          'قدم أفكاراً عملية لكسر الجليد وتكوين صداقات وطرقاً مهذبة ولائقة لحل النزاعات. أجب باللغة العربية الفصحى حصرياً.',

      'agent_language_name': 'اللغة والتواصل',
      'agent_language_sub': 'تجنب الحديث وصعوبة اللكنة',
      'agent_language_prompt':
          'أنت معلم لغوي وداعم تواصل ذكي للمهاجرين والطلاب المغتربين. '
          'المستخدم يشعر بالخوف، الحرج أو التردد في التحدث والتعبير بسبب حواجز اللغة واللكنة. '
          'قدم إرشادات واضحة وسهلة للنطق اللغوي، وتراكيب جمل بسيطة، وعبارات عملية لبناء الثقة بالنفس. '
          'اجعل الشروحات مقتضبة للغاية ومركزة على التواصل العملي اليومي. أجب باللغة العربية الفصحى حصرياً.',

      'agent_biological_name': 'الصحة والجسد',
      'agent_biological_sub': 'الإجهاد البدني والتعب والأرق',
      'agent_biological_prompt':
          'أنت مساعد عافية وصحة عامة ذكي وداعم. '
          'المستخدم يعاني من أعراض جسدية ناتجة عن ضغوط الهجرة وتغيير البيئة مثل الإرهاق المستمر، الصداع البدني أو اضطرابات النوم واليقظة. '
          'اقترح روتين عافية يومي عملي غير طبي، ونصائح لتحسين جودة ونظافة النوم، وعادات يومية لتقليل الإجهاد البدني والذهني. أجب باللغة العربية الفصحى حصرياً.',

      // Chat screen
      'chat_thinking': 'يفكر الآن…',
      'chat_online': 'متصل بالإنترنت',
      'chat_reset_title': 'إعادة تعيين المحادثة',
      'chat_reset_confirm': 'هل أنت متأكد أنك تريد مسح سجل هذه المحادثة بالكامل لضمان سرية خصوصيتك؟',
      'chat_cancel': 'إلغاء',
      'chat_reset': 'إعادة تعيين',
      'chat_type_msg': 'اكتب رسالتك هنا...',
      'chat_empty_prompt': 'كيف يمكنني مساعدتك اليوم؟',

      // Settings screen
      'settings_title': 'الإعدادات',
      'settings_app_lang': 'لغة التطبيق',
      'settings_your_profile': 'ملفك الشخصي',
      'settings_edit': 'تعديل',
      'settings_no_profile': 'لا توجد بيانات للملف الشخصي',
      'settings_clear_history': 'مسح سجل المحادثات',
      'settings_clear_history_sub': 'حذف جميع المحادثات المخزنة محلياً على هذا الجهاز',
      'settings_check_updates': 'التحقق من تحديثات النموذج',
      'settings_check_updates_sub': 'تنزيل أحدث إصدار لمارس والتحقق من التحديثات',
      'settings_reset_profile': 'إعادة تعيين ملف التطبيق',
      'settings_reset_profile_sub': 'مسح جميع بيانات الإعداد والبدء من جديد',
      'settings_updates_latest': 'أنت تستخدم أحدث إصدار للنموذج بالفعل.',
      'settings_history_cleared': 'تم مسح سجل المحادثات بنجاح.',
      'settings_accessibility': 'إمكانية الوصول والخطوط',
      'settings_accessibility_sub': 'تعديل أحجام الخطوط، الألوان، وتباين الشاشة',
      'settings_font_size': 'حجم الخط',
      'settings_color_theme': 'مظهر الألوان',
      'settings_brightness': 'التباين والسطوع',
      'font_small': 'صغير',
      'font_medium': 'متوسط',
      'font_large': 'كبير',
      'font_xlarge': 'كبير جداً',
      'theme_purple': 'بنفسجي داكن',
      'theme_teal': 'أزرق مخضر (تيل)',
      'theme_blue': 'أزرق محيطي',
      'theme_green': 'أخضر زمردي',
      'bright_dark': 'داكن كلاسيكي',
      'bright_amoled': 'أسود مطفأ (أموليد)',
      'bright_light': 'فاتح ناصع',

      // History & Bookmarks Screen
      'history_title': 'السجل والمحفوظات',
      'history_bookmarks': 'المحفوظات والوسوم',
      'history_conversations': 'المحادثات الأخيرة',
      'history_mock_bookmark_1': 'نصائح المقابلات الوظيفية (الدعم النفسي)',
      'history_mock_bookmark_1_sub': 'حُفظ بالأمس',
      'history_mock_bookmark_2': 'عبارات التسوق والاحتياجات اليومية',
      'history_mock_bookmark_2_sub': 'حُفظ قبل ٣ أيام',
      'history_mock_chat_1': 'مساعدة في طلب تأشيرة الإقامة',
      'history_mock_chat_1_sub': 'مساعد الدمج • اليوم',
      'history_mock_chat_2': 'آداب السلوك والعادات المحلية',
      'history_mock_chat_2_sub': 'مساعد الدمج • بالأمس',
      'history_mock_chat_3': 'نظام الرعاية الطبية والتأمين',
      'history_mock_chat_3_sub': 'مساعد العافية والصحة • الأسبوع الماضي',
    },
    'fr': {
      // Splash screen
      'splash_starting': 'Démarrage de Mars…',
      'splash_loading_engine': 'Chargement du moteur IA…',
      'splash_error_load': 'Échec du chargement du modèle.',

      // Profile creation
      'setup_title': 'Configurer le profil',
      'setup_subtitle': 'Parlez-nous un peu de vous afin que Mars IA puisse personnaliser votre expérience.',
      'setup_native_country': 'Pays d\'origine',
      'setup_host_country': 'Pays d\'accueil',
      'setup_native_lang': 'Langue maternelle',
      'setup_status': 'Statut',
      'setup_continue': 'Continuer',
      'setup_err_enter': 'Veuillez entrer',
      'setup_status_immigrant': 'Immigrant',
      'setup_status_student': 'Étudiant international',
      'setup_status_expat': 'Expatrié / Professionnel',
      'setup_status_other': 'Autre',

      // Model download screen
      'download_title_setup': 'Configuration initiale',
      'download_subtitle_setup': 'Mars doit télécharger le modèle IA (~2 Go).\nCela se produit une seule fois. Le modèle fonctionne entièrement hors ligne après cela.',
      'download_title_active': 'Téléchargement du modèle IA',
      'download_subtitle_active': 'Veuillez vous connecter au Wi-Fi. Téléchargement de votre assistant intelligent pour une utilisation hors ligne.',
      'download_title_complete': 'Téléchargement terminé',
      'download_subtitle_complete': 'Initialisation du moteur IA…',
      'download_title_error': 'Échec du téléchargement',
      'download_subtitle_error': 'Vérifiez votre connexion et réessayez.',
      'download_btn_start': 'Télécharger le modèle (~2 Go)',
      'download_btn_active': 'Téléchargement...',
      'download_btn_retry': 'Réessayer le téléchargement',
      'download_title_prep_engine': 'Préparation du moteur IA',
      'download_subtitle_prep_engine': 'Chargement du modèle en mémoire…',

      // Navigation tabs
      'nav_home': 'Accueil',
      'nav_history': 'Historique',
      'nav_settings': 'Paramètres',

      // Home Screen
      'home_title': 'Mars',
      'home_subtitle': 'Votre compagnon IA hors ligne pour l\'immigration',

      // Agent selection cards
      'agent_psychology_name': 'Psychologie',
      'agent_psychology_sub': 'Anxiété et repli sur soi',
      'agent_psychology_prompt':
          'Vous êtes un assistant psychologique IA ancré et empathique pour les immigrants. '
          'L\'utilisateur ressent de l\'anxiété, le mal du pays ou du repli sur soi. '
          'Utilisez des techniques d\'ancrage, validez ses émotions et proposez des '
          'mécanismes d\'adaptation apaisants et concrets. Ne donnez pas de diagnostics médicaux. '
          'Répondez en français uniquement.',

      'agent_social_name': 'Intégration Sociale',
      'agent_social_sub': 'Isolement et conflits culturels',
      'agent_social_prompt':
          'Vous êtes une IA d\'intégration culturelle. '
          'L\'utilisateur est confronté à l\'isolement social ou à un malentendu culturel. '
          'Expliquez logiquement les normes sociales du pays d\'accueil sans juger la '
          'culture d\'origine de l\'utilisateur. Proposez des brise-glaces concrets et '
          'des moyens polis de gérer les conflits. Répondez en français uniquement.',

      'agent_language_name': 'Langue et communication',
      'agent_language_sub': 'Évitement de communication',
      'agent_language_prompt':
          'Vous êtes une IA linguistique de soutien. '
          'L\'utilisateur a peur de parler en raison d\'une barrière linguistique. '
          'Proposez des prononciations phonétiques, des structures de phrases simples et '
          'des expressions de confiance en soi. Gardez les explications brèves et axées sur '
          'la communication pratique. Répondez en français uniquement.',

      'agent_biological_name': 'Santé et corps',
      'agent_biological_sub': 'Fatigue et stress chronique',
      'agent_biological_prompt':
          'Vous êtes un assistant IA de bien-être. '
          'L\'utilisateur souffre de symptômes physiques liés au stress de l\'immigration, '
          'comme la fatigue ou des troubles du sommeil. Suggérez des routines quotidiennes '
          'concrètes non médicales, des conseils d\'hygiène du sommeil et des habitudes de '
          'réduction du stress. Répondez en français uniquement.',

      // Chat screen
      'chat_thinking': 'Réflexion…',
      'chat_online': 'En ligne',
      'chat_reset_title': 'Réinitialiser la conversation',
      'chat_reset_confirm': 'Êtes-vous sûr de vouloir effacer l\'historique de cette discussion ?',
      'chat_cancel': 'Annuler',
      'chat_reset': 'Réinitialiser',
      'chat_type_msg': 'Écrivez un message...',
      'chat_empty_prompt': 'Comment puis-je vous aider aujourd\'hui ?',

      // Settings screen
      'settings_title': 'Paramètres',
      'settings_app_lang': 'Langue de l\'application',
      'settings_your_profile': 'Votre profil',
      'settings_edit': 'Modifier',
      'settings_no_profile': 'Aucune donnée de profil',
      'settings_clear_history': 'Effacer l\'historique des discussions',
      'settings_clear_history_sub': 'Supprimer toutes les conversations de cet appareil',
      'settings_check_updates': 'Vérifier les mises à jour du modèle',
      'settings_check_updates_sub': 'Télécharger la dernière version de Mars IA',
      'settings_reset_profile': 'Réinitialiser le profil de l\'application',
      'settings_reset_profile_sub': 'Effacer les données de configuration pour recommencer',
      'settings_updates_latest': 'Vous utilisez déjà la dernière version du modèle.',
      'settings_history_cleared': 'Historique des discussions effacé.',
      'settings_accessibility': 'Accessibilité et polices',
      'settings_accessibility_sub': 'Modifier la taille du texte, les couleurs et le contraste',
      'settings_font_size': 'Taille de police',
      'settings_color_theme': 'Thème de couleur',
      'settings_brightness': 'Thème et contraste',
      'font_small': 'Petit',
      'font_medium': 'Moyen',
      'font_large': 'Grand',
      'font_xlarge': 'Très grand',
      'theme_purple': 'Violet profond',
      'theme_teal': 'Sarcelle',
      'theme_blue': 'Bleu océan',
      'theme_green': 'Vert émeraude',
      'bright_dark': 'Sombre classique',
      'bright_amoled': 'Noir Amoled',
      'bright_light': 'Clair épuré',

      // History & Bookmarks Screen
      'history_title': 'Historique et favoris',
      'history_bookmarks': 'Favoris',
      'history_conversations': 'Conversations récentes',
      'history_mock_bookmark_1': 'Conseils d\'entretien d\'embauche (Psychologie)',
      'history_mock_bookmark_1_sub': 'Enregistré hier',
      'history_mock_bookmark_2': 'Expressions pour faire les courses',
      'history_mock_bookmark_2_sub': 'Enregistré il y a 3 jours',
      'history_mock_chat_1': 'Aide pour la demande de visa',
      'history_mock_chat_1_sub': 'Agent social • Aujourd\'hui',
      'history_mock_chat_2': 'Étiquette culturelle locale',
      'history_mock_chat_2_sub': 'Agent social • Hier',
      'history_mock_chat_3': 'Infos sur le système de santé',
      'history_mock_chat_3_sub': 'Agent biologique • La semaine dernière',
    }
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  bool get isRtl => locale.languageCode == 'ar';
  TextDirection get textDirection => isRtl ? TextDirection.rtl : TextDirection.ltr;
}
