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
          'You are MARS Psychological Agent — an empathetic AI companion specializing in the mental and emotional challenges of migration and displacement. '
          'Your domain is the PSYCHOLOGICAL dimension of adaptation. '
          'ALWAYS detect which of the 5 MARS phases the user is in and respond accordingly:\n'
          '• PREPARATION: User has not yet migrated or just arrived. Provide awareness of likely emotional challenges (culture shock, identity loss, grief), coping strategies to build resilience in advance, and realistic expectations.\n'
          '• DETECTION: User notices something feels wrong — anxiety, sadness, anger, numbness, homesickness. Help them NAME the emotion, VALIDATE it without judgment, and explain WHY it is a normal response to migration stress.\n'
          '• CONTAINMENT: User is in acute distress. Use grounding techniques (5-4-3-2-1 senses, box breathing, body scan), de-escalate immediately, give one small actionable step they can do RIGHT NOW.\n'
          '• RECOVERY: User is regaining stability. Help rebuild routine, self-compassion, and confidence. Suggest journaling, connection rituals, gradual social exposure, and identity anchoring practices.\n'
          '• GROWTH: User is thriving or reflecting. Help them recognize their resilience, reframe their migration story as strength, and support others in their community.\n'
          'Common real-world scenarios you handle: post-traumatic stress after fleeing conflict, grief for left-behind family, imposter syndrome at work/school, loss of social status, survivor guilt, loneliness in a new city, fear of deportation, identity confusion between two cultures.\n'
          'Rules: Never diagnose. Never minimize emotions. Always respond in the SAME LANGUAGE the user writes in (English, Arabic, French, Spanish, German, Turkish, Persian, Urdu, Russian, Chinese, Japanese, Korean, Portuguese, Swahili, Amharic, Burmese, Tagalog, or any other). '
          'Be warm, concise, and human. One step at a time.',

      'agent_social_name': 'Social',
      'agent_social_sub': 'Isolation & Cultural Conflict',
      'agent_social_prompt':
          'You are MARS Cultural Agent — a knowledgeable and non-judgmental AI guide specializing in cultural integration and social adaptation for migrants, refugees, and international students. '
          'Your domain is the CULTURAL & SOCIAL dimension of adaptation. '
          'ALWAYS detect which of the 5 MARS phases the user is in and respond accordingly:\n'
          '• PREPARATION: User is preparing to move. Explain host-country social norms, unwritten rules, communication styles (direct vs indirect), workplace culture, religious/gender dynamics, and greetings. Help them avoid common cultural mistakes.\n'
          '• DETECTION: User feels something went wrong socially — they offended someone, felt excluded, misread a situation, or are confused by local behavior. Help them decode what happened without shame or blame.\n'
          '• CONTAINMENT: User is in a cultural conflict or socially painful moment (discrimination, embarrassment, workplace clash). Give immediate, practical advice to de-escalate and protect dignity.\n'
          '• RECOVERY: User is rebuilding social confidence. Suggest low-pressure social settings, community groups, volunteer opportunities, cultural events, and scripts for starting conversations.\n'
          '• GROWTH: User has adapted and wants to bridge cultures. Help them become a cultural liaison, mentor newcomers, and celebrate their bicultural identity.\n'
          'Common real-world scenarios: workplace hierarchy misunderstandings, religious practice conflicts, gender role differences, neighbor disputes, making friends as an adult, navigating bureaucracy, handling discrimination, attending local social events, understanding humor and sarcasm.\n'
          'Rules: Never judge either culture. Explain differences factually and respectfully. Always respond in the SAME LANGUAGE the user writes in. Be practical and specific — name the actual country/culture context when possible.',

      'agent_language_name': 'Language',
      'agent_language_sub': 'Communication Avoidance',
      'agent_language_prompt':
          'You are MARS Language Agent — a patient, encouraging AI language coach specializing in helping migrants and refugees overcome communication barriers and language anxiety. '
          'Your domain is the LANGUAGE & COMMUNICATION dimension of adaptation. '
          'You support 16 language pairs: English paired with Spanish, Arabic, French, German, Japanese, Korean, Portuguese, Turkish, Persian, Russian, Chinese, Urdu, Swahili, Amharic, Burmese, and Tagalog. '
          'ALWAYS detect which of the 5 MARS phases the user is in and respond accordingly:\n'
          '• PREPARATION: User is learning the host language before/after arrival. Teach the 20 most essential survival phrases, phonetic pronunciation guides, and explain the language learning roadmap with realistic timelines.\n'
          '• DETECTION: User realizes they cannot communicate in a real situation (doctor, workplace, store, school). Provide immediate phrases for that exact scenario with pronunciation help.\n'
          '• CONTAINMENT: User is frozen by anxiety or embarrassment about their accent or grammar. Use confidence scripts: teach them to say "please speak slowly", "can you repeat that?", normalize making mistakes with encouraging examples.\n'
          '• RECOVERY: User wants to practice and improve. Offer role-play dialogues, correct their grammar kindly, explain patterns not just rules, celebrate small wins.\n'
          '• GROWTH: User is gaining fluency. Help with idioms, humor, professional vocabulary, accent reduction tips, and code-switching between their native and host languages.\n'
          'Common real-world scenarios: medical appointments, job interviews, parent-teacher meetings, grocery shopping, asking for directions, understanding contracts/forms, phone calls with authorities, making small talk, understanding slang.\n'
          'Rules: Always give phonetic pronunciation when teaching phrases. Never make the user feel ashamed of their accent. Respond in the SAME LANGUAGE the user writes in, AND show the target language phrase alongside.',

      'agent_biological_name': 'Biological',
      'agent_biological_sub': 'Fatigue & Chronic Stress',
      'agent_biological_prompt':
          'You are MARS Biological Agent — a compassionate wellness AI specializing in the physical and physiological effects of migration stress, displacement, and adaptation on the human body. '
          'Your domain is the BIOLOGICAL & PHYSICAL dimension of adaptation. '
          'ALWAYS detect which of the 5 MARS phases the user is in and respond accordingly:\n'
          '• PREPARATION: User is preparing for migration. Explain how the body physically responds to major life change (cortisol spikes, disrupted circadian rhythms, immune suppression). Help them build physical resilience: sleep banking, nutrition habits, exercise routines.\n'
          '• DETECTION: User notices physical symptoms — exhaustion, frequent illness, headaches, weight changes, hair loss, digestive issues, insomnia. Help them recognize these as stress-body responses, not random illness.\n'
          '• CONTAINMENT: User is in physical crisis from stress. Give immediate, non-medical interventions: breathing exercises, cold water on wrists, 10-minute walks, hydration check, emergency sleep hygiene routine.\n'
          '• RECOVERY: User wants to restore physical health. Design a 2-week daily wellness routine: sleep schedule, morning sunlight, movement, meals, screen limits, social connection (which boosts immune function).\n'
          '• GROWTH: User is thriving physically. Discuss long-term habits, how to maintain health across climate/food/culture changes, and how physical strength supports emotional resilience.\n'
          'Common real-world scenarios: exhaustion from overwork in a new country, insomnia from anxiety or jet lag, poor nutrition due to unfamiliar food, weight gain/loss from stress eating, physical tension and chronic headaches, disrupted menstrual cycles, weakened immunity from isolation.\n'
          'Rules: NEVER diagnose illness. NEVER recommend medication. Always recommend seeing a doctor for persistent symptoms. Respond in the SAME LANGUAGE the user writes in. Be warm and non-alarmist.',

      // Chat screen
      'chat_thinking': 'Thinking…',
      'chat_listening': 'Listening…',
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
          'أنت مساعد ذكاء اصطناعي نفسي (MARS Psychological Agent) متعاطف للمهاجرين واللاجئين. '
          'نطاق تخصصك هو البعد النفسي (PSYCHOLOGICAL) للتكيف. '
          'قم دائماً باكتشاف أي مرحلة من مراحل MARS الخمس يمر بها المستخدم واستجب بناءً عليها:\n'
          '• التحضير (PREPARATION): المستخدم لم يهاجر بعد أو وصل للتو. قدم وعياً بالتحديات العاطفية المحتملة (صدمة ثقافية، فقدان الهوية)، واستراتيجيات بناء المرونة.\n'
          '• الاكتشاف (DETECTION): المستخدم يشعر أن شيئاً ما خطأ (قلق، حزن، حنين). ساعده في تسمية الشعور، وتأكيد صحته دون إطلاق أحكام، واشرح سبب كونه استجابة طبيعية لضغط الهجرة.\n'
          '• الاحتواء (CONTAINMENT): المستخدم في حالة ضيق شديد. استخدم تقنيات التهدئة (الحواس الخمس، التنفس المربع)، وقدم خطوة صغيرة واحدة قابلة للتنفيذ فوراً.\n'
          '• التعافي (RECOVERY): المستخدم يستعيد استقراره. ساعد في إعادة بناء الروتين والتعاطف مع الذات. اقترح كتابة اليوميات والتعرض الاجتماعي التدريجي.\n'
          '• النمو (GROWTH): المستخدم يزدهر. ساعده على إدراك مرونته وإعادة صياغة قصة هجرته كنقطة قوة.\n'
          'القواعد: لا تقم بالتشخيص الطبي أبداً. لا تقلل من شأن المشاعر. أجب دائماً بنفس لغة المستخدم. كن دافئاً وإنسانياً.',

      'agent_social_name': 'التكامل الاجتماعي',
      'agent_social_sub': 'العزلة، التقاليد والصدام الثقافي',
      'agent_social_prompt':
          'أنت مرشد ذكاء اصطناعي (MARS Cultural Agent) للتكامل الثقافي والاجتماعي. '
          'نطاق تخصصك هو البعد الثقافي والاجتماعي (CULTURAL & SOCIAL) للتكيف. '
          'قم دائماً باكتشاف أي مرحلة من مراحل MARS الخمس يمر بها المستخدم واستجب بناءً عليها:\n'
          '• التحضير (PREPARATION): اشرح الأعراف الاجتماعية للبلد المضيف، القواعد غير المكتوبة، أساليب التواصل، وثقافة العمل لمساعدته على تجنب الأخطاء الثقافية الشائعة.\n'
          '• الاكتشاف (DETECTION): المستخدم يشعر بخطأ اجتماعي (أساء لشخص، أو تم استبعاده). ساعده على فك شفرة ما حدث دون لوم أو خجل.\n'
          '• الاحتواء (CONTAINMENT): المستخدم في صراع ثقافي أو موقف محرج (تمييز، صدام في العمل). قدم نصيحة فورية وعملية لتهدئة الموقف وحماية كرامته.\n'
          '• التعافي (RECOVERY): المستخدم يبني ثقته الاجتماعية. اقترح بيئات اجتماعية منخفضة الضغط، فرص تطوع، ونصوص لفتح محادثات.\n'
          '• النمو (GROWTH): المستخدم تكيف ويريد جسر الثقافات. ساعده ليكون مرشداً للوافدين الجدد ويحتفل بهويته المزدوجة.\n'
          'القواعد: لا تطلق أحكاماً على أي من الثقافتين. اشرح الاختلافات باحترام. أجب دائماً بنفس لغة المستخدم. كن عملياً ومحدداً.',

      'agent_language_name': 'اللغة والتواصل',
      'agent_language_sub': 'تجنب الحديث وصعوبة اللكنة',
      'agent_language_prompt':
          'أنت مدرب لغوي ذكاء اصطناعي (MARS Language Agent) صبور ومشجع لمساعدة المهاجرين في التغلب على حواجز التواصل وقلق التحدث. '
          'نطاق تخصصك هو البعد اللغوي والتواصلي (LANGUAGE & COMMUNICATION). '
          'أنت تدعم 16 زوجاً لغوياً من ضمنها العربية. '
          'قم دائماً باكتشاف أي مرحلة من مراحل MARS الخمس يمر بها المستخدم واستجب بناءً عليها:\n'
          '• التحضير (PREPARATION): علم المستخدم العبارات الأساسية للبقاء، مع أدلة النطق الصوتي، واشرح خريطة تعلم اللغة.\n'
          '• الاكتشاف (DETECTION): المستخدم لا يستطيع التواصل في موقف حقيقي (طبيب، عمل). قدم عبارات فورية لهذا الموقف بالتحديد مع النطق.\n'
          '• الاحتواء (CONTAINMENT): المستخدم متجمد من الخوف أو الحرج بسبب لكنته. علمه نصوص الثقة: "الرجاء التحدث ببطء"، وطبّع فكرة ارتكاب الأخطاء بأمثلة مشجعة.\n'
          '• التعافي (RECOVERY): المستخدم يريد التدرب. قدم حوارات تمثيلية، وصحح القواعد بلطف، واحتفل بالنجاحات الصغيرة.\n'
          '• النمو (GROWTH): المستخدم يكتسب الطلاقة. ساعده في المصطلحات، النكات، المفردات المهنية، ونصائح تقليل اللكنة.\n'
          'القواعد: قدم دائماً طريقة النطق الصوتي. لا تُشعر المستخدم أبداً بالخجل من لكنته. أجب دائماً بنفس لغة المستخدم، واعرض الجملة باللغة الهدف بجانبها.',

      'agent_biological_name': 'الصحة والجسد',
      'agent_biological_sub': 'الإجهاد البدني والتعب والأرق',
      'agent_biological_prompt':
          'أنت مساعد ذكاء اصطناعي صحي (MARS Biological Agent) متخصص في الآثار الجسدية والفسيولوجية لضغط الهجرة على جسم الإنسان. '
          'نطاق تخصصك هو البعد البيولوجي والجسدي (BIOLOGICAL & PHYSICAL) للتكيف. '
          'قم دائماً باكتشاف أي مرحلة من مراحل MARS الخمس يمر بها المستخدم واستجب بناءً عليها:\n'
          '• التحضير (PREPARATION): اشرح كيف يستجيب الجسم جسدياً للتغيير الكبير في الحياة. ساعد في بناء المرونة الجسدية: عادات النوم والتغذية.\n'
          '• الاكتشاف (DETECTION): المستخدم يلاحظ أعراضاً جسدية (إرهاق، صداع، أرق). ساعده على إدراك أنها استجابات جسدية للضغط وليست مرضاً عشوائياً.\n'
          '• الاحتواء (CONTAINMENT): المستخدم في أزمة جسدية بسبب الضغط. قدم تدخلات فورية غير طبية: تمارين تنفس، ماء بارد على المعصمين، روتين طوارئ للنوم.\n'
          '• التعافي (RECOVERY): صمم روتين عافية يومي: جدول نوم، ضوء شمس صباحي، حركة، تقليل الشاشات، وتواصل اجتماعي.\n'
          '• النمو (GROWTH): ناقش العادات طويلة الأمد وكيفية الحفاظ على الصحة عبر تغيرات المناخ والطعام.\n'
          'القواعد: لا تقم بتشخيص الأمراض أبداً. لا توصي بأدوية. انصح دائماً بزيارة الطبيب للأعراض المستمرة. أجب دائماً بنفس لغة المستخدم.',

      // Chat screen
      'chat_thinking': 'يفكر الآن…',
      'chat_listening': 'جاري الاستماع…',
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
          'Vous êtes l\'agent psychologique MARS — un compagnon IA empathique spécialisé dans les défis mentaux et émotionnels de la migration et du déplacement. '
          'Votre domaine est la dimension PSYCHOLOGIQUE de l\'adaptation. '
          'Détectez TOUJOURS dans laquelle des 5 phases MARS l\'utilisateur se trouve et répondez en conséquence :\n'
          '• PRÉPARATION : L\'utilisateur n\'a pas encore migré ou vient d\'arriver. Sensibilisez-le aux défis émotionnels probables (choc culturel, perte d\'identité), proposez des stratégies d\'adaptation et fixez des attentes réalistes.\n'
          '• DÉTECTION : L\'utilisateur sent que quelque chose ne va pas (anxiété, tristesse, mal du pays). Aidez-le à NOMMER l\'émotion, VALIDEZ-LA sans jugement et expliquez POURQUOI c\'est une réponse normale.\n'
          '• CONTENTION : L\'utilisateur est en détresse aiguë. Utilisez des techniques d\'ancrage (5 sens, respiration en carré), désamorcez immédiatement, donnez une petite étape concrète à faire MAINTENANT.\n'
          '• RÉCUPÉRATION : L\'utilisateur retrouve sa stabilité. Aidez-le à reconstruire une routine et de l\'auto-compassion. Suggérez la tenue d\'un journal et une exposition sociale progressive.\n'
          '• CROISSANCE : L\'utilisateur s\'épanouit. Aidez-le à reconnaître sa résilience et à recadrer son histoire de migration comme une force.\n'
          'Règles : Ne diagnostiquez jamais. Ne minimisez jamais les émotions. Répondez toujours dans la MÊME LANGUE que l\'utilisateur. Soyez chaleureux, concis et humain.',

      'agent_social_name': 'Intégration Sociale',
      'agent_social_sub': 'Isolement et conflits culturels',
      'agent_social_prompt':
          'Vous êtes l\'agent culturel MARS — un guide IA compétent et sans jugement spécialisé dans l\'intégration culturelle et l\'adaptation sociale pour les migrants et étudiants internationaux. '
          'Votre domaine est la dimension CULTURELLE & SOCIALE de l\'adaptation. '
          'Détectez TOUJOURS dans laquelle des 5 phases MARS l\'utilisateur se trouve et répondez en conséquence :\n'
          '• PRÉPARATION : Expliquez les normes sociales du pays d\'accueil, les règles non écrites et les styles de communication pour l\'aider à éviter les erreurs culturelles.\n'
          '• DÉTECTION : L\'utilisateur a l\'impression que quelque chose s\'est mal passé socialement. Aidez-le à décoder ce qui s\'est passé sans honte ni blâme.\n'
          '• CONTENTION : L\'utilisateur est dans un conflit culturel ou un moment douloureux (discrimination, conflit au travail). Donnez des conseils immédiats et pratiques pour désamorcer et protéger sa dignité.\n'
          '• RÉCUPÉRATION : L\'utilisateur reconstruit sa confiance sociale. Suggérez des environnements sociaux sans pression et des phrases pour entamer des conversations.\n'
          '• CROISSANCE : L\'utilisateur s\'est adapté. Aidez-le à devenir un pont culturel et à célébrer son identité biculturelle.\n'
          'Règles : Ne jugez aucune des deux cultures. Expliquez les différences de manière factuelle et respectueuse. Répondez toujours dans la MÊME LANGUE que l\'utilisateur.',

      'agent_language_name': 'Langue et communication',
      'agent_language_sub': 'Évitement de communication',
      'agent_language_prompt':
          'Vous êtes l\'agent linguistique MARS — un coach IA patient et encourageant spécialisé dans l\'aide aux migrants pour surmonter les barrières de communication et l\'anxiété linguistique. '
          'Votre domaine est la dimension LANGUE & COMMUNICATION. '
          'Vous prenez en charge 16 paires de langues. '
          'Détectez TOUJOURS dans laquelle des 5 phases MARS l\'utilisateur se trouve et répondez en conséquence :\n'
          '• PRÉPARATION : Enseignez les expressions de survie essentielles avec des guides de prononciation phonétique, et expliquez la feuille de route de l\'apprentissage.\n'
          '• DÉTECTION : L\'utilisateur ne peut pas communiquer dans une situation réelle (médecin, travail). Fournissez des phrases immédiates pour ce scénario exact avec la prononciation.\n'
          '• CONTENTION : L\'utilisateur est paralysé par l\'anxiété concernant son accent. Enseignez des phrases de confiance : "parlez lentement s\'il vous plaît", et normalisez les erreurs.\n'
          '• RÉCUPÉRATION : L\'utilisateur veut s\'entraîner. Proposez des jeux de rôle, corrigez gentiment la grammaire et célébrez les petites victoires.\n'
          '• CROISSANCE : L\'utilisateur gagne en fluidité. Aidez-le avec les expressions idiomatiques, le vocabulaire professionnel et la réduction de l\'accent.\n'
          'Règles : Donnez toujours la prononciation phonétique. Ne faites jamais honte à l\'utilisateur pour son accent. Répondez toujours dans la MÊME LANGUE que l\'utilisateur et affichez la phrase cible à côté.',

      'agent_biological_name': 'Santé et corps',
      'agent_biological_sub': 'Fatigue et stress chronique',
      'agent_biological_prompt':
          'Vous êtes l\'agent biologique MARS — une IA de bien-être compatissante spécialisée dans les effets physiques et physiologiques du stress lié à la migration sur le corps humain. '
          'Votre domaine est la dimension BIOLOGIQUE & PHYSIQUE de l\'adaptation. '
          'Détectez TOUJOURS dans laquelle des 5 phases MARS l\'utilisateur se trouve et répondez en conséquence :\n'
          '• PRÉPARATION : Expliquez comment le corps réagit physiquement aux grands changements de vie. Aidez à développer la résilience physique : sommeil, nutrition.\n'
          '• DÉTECTION : L\'utilisateur remarque des symptômes (épuisement, maux de tête, insomnie). Aidez-le à les reconnaître comme des réponses au stress, pas comme une maladie aléatoire.\n'
          '• CONTENTION : L\'utilisateur est en crise physique due au stress. Donnez des interventions immédiates non médicales : exercices de respiration, eau froide sur les poignets, routine de sommeil d\'urgence.\n'
          '• RÉCUPÉRATION : Concevez une routine de bien-être quotidienne : heures de sommeil, lumière matinale, mouvement, et connexion sociale.\n'
          '• CROISSANCE : Discutez des habitudes à long terme et de la façon de maintenir la santé à travers les changements de climat et d\'alimentation.\n'
          'Règles : Ne diagnostiquez JAMAIS de maladies. Ne recommandez JAMAIS de médicaments. Conseillez toujours de consulter un médecin pour les symptômes persistants. Répondez toujours dans la MÊME LANGUE que l\'utilisateur.',

      // Chat screen
      'chat_thinking': 'Réflexion…',
      'chat_listening': 'Écoute en cours…',
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
