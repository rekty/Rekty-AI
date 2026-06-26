import 'package:flutter/material.dart';

import '../services/api_key_service.dart';
import '../services/isar_service.dart';
import '../services/pollinations_service.dart';
import '../services/pollinations_models.dart';
import '../services/language_service.dart';

// ── Daftar aspect ratio yang tersedia ────────────────────────────────────────
const List<Map<String, String>> kAspectRatios = [
  {'key': '1:1 Square',      'label': '1:1 — Square',          'icon': '⬛'},
  {'key': '3:4 Portrait',    'label': '3:4 — Portrait',        'icon': '📱'},
  {'key': '2:3 Portrait',    'label': '2:3 — Portrait Tall',   'icon': '📷'},
  {'key': '9:16 Story HD',   'label': '9:16 — Story HD',       'icon': '🎞️'},
  {'key': '9:16 Mobile',     'label': '9:16 — Mobile',         'icon': '📲'},
  {'key': '4:3 Landscape',   'label': '4:3 — Landscape',       'icon': '🖥️'},
  {'key': '3:2 Landscape',   'label': '3:2 — Landscape Wide',  'icon': '🌄'},
  {'key': '16:9 Widescreen', 'label': '16:9 — Widescreen',     'icon': '🎬'},
];

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final IsarService _isarService = IsarService.instance;
  final ApiKeyService _apiKeyService = ApiKeyService.instance;

  bool _hasPollinationsKey = false;
  bool _hasPollinationsAppKey = false;
  String _selectedChatModel = 'openai';
  String _selectedImageModel = 'flux';
  String _selectedAspectRatio = '1:1 Square';
  String _selectedLanguage = 'Indonesia';

  // ── Terjemahan ────────────────────────────────────────────────────────────

  String tr(String key) {
    if (_selectedLanguage == 'English') {
      switch (key) {
        // Settings screen labels
        case 'settings':              return 'Settings';
        case 'about':                 return 'About';
        case 'api_config':            return 'API CONFIGURATION';
        case 'data':                  return 'DATA';
        case 'language':              return 'Language';
        case 'chat_model':            return 'Chat Model';
        case 'image_model':           return 'Image Model';
        case 'aspect_ratio':          return 'Aspect Ratio';
        case 'license':               return 'Application License';
        case 'readme':                return 'README';
        case 'readme_subtitle':       return 'Documentation & setup guide';
        case 'pollinations_key':      return 'Pollinations Key';
        // API key tiles
        case 'upload_api_key':        return 'Upload Pollinations API Key';
        case 'change_api_key':        return 'Change Pollinations API Key';
        case 'api_key_saved':         return 'Pollinations API key saved';
        case 'api_key_hint':          return 'Enter Pollinations API key';
        case 'upload_app_key':        return 'Upload Pollinations App Key';
        case 'change_app_key':        return 'Change Pollinations App Key';
        case 'app_key_saved':         return 'Pollinations App Key saved';
        case 'app_key_hint':          return 'Enter Pollinations App Key (PK_)';
        // Data section
        case 'delete_chat_history':   return 'Delete All Chat History';
        case 'delete_chat_subtitle':  return 'Removes all saved conversations';
        case 'delete_image_history':  return 'Delete All Image History';
        case 'delete_image_subtitle': return 'Removes all generated/edited images';
        // Dialogs & actions
        case 'cancel':                return 'Cancel';
        case 'save':                  return 'Save';
        case 'close':                 return 'Close';
        case 'delete':                return 'Delete';
        case 'select_image_model':    return 'Select Image Model';
        case 'select_aspect_ratio':   return 'Select Aspect Ratio';
        case 'select_chat_model':     return 'Select Chat Model';
        case 'select_language':       return 'Select Language';
        // Snackbar
        case 'api_key_empty':         return 'Pollinations API key cannot be empty.';
        case 'api_key_success':       return 'Pollinations API key saved successfully.';
        case 'app_key_empty':         return 'Pollinations App Key cannot be empty.';
        case 'app_key_success':       return 'Pollinations App Key saved successfully.';
        case 'chat_deleted':          return 'Chat history deleted successfully.';
        case 'image_deleted':         return 'Image history deleted successfully.';
        // Confirm dialogs
        case 'delete_chat_title':     return 'Delete all chats?';
        case 'delete_chat_msg':       return 'All conversation history will be permanently deleted.';
        case 'delete_image_title':    return 'Delete all images?';
        case 'delete_image_msg':      return 'All image history will be permanently deleted.';
        // About / info
        case 'app_version':           return 'Version 1.0.0 - Powered by Rekty Anjany';
        case 'license_view':          return 'View Rekty AI terms of use';
        case 'privacy_subtitle':      return 'Rekty AI Studio privacy policy';
        default:                      return key;
      }
    }

    // Default: Indonesia
    switch (key) {
      case 'settings':              return 'Pengaturan';
      case 'about':                 return 'Tentang';
      case 'api_config':            return 'Konfigurasi API';
      case 'data':                  return 'Data';
      case 'language':              return 'Bahasa';
      case 'chat_model':            return 'Model Chat';
      case 'image_model':           return 'Model Gambar';
      case 'aspect_ratio':          return 'Rasio Gambar';
      case 'license':               return 'Lisensi Aplikasi';
      case 'readme':                return 'README';
      case 'readme_subtitle':       return 'Dokumentasi & panduan pengaturan';
      case 'pollinations_key':      return 'Pollinations Key';
      case 'upload_api_key':        return 'Upload Pollinations API Key';
      case 'change_api_key':        return 'Ganti Pollinations API Key';
      case 'api_key_saved':         return 'Pollinations API key tersimpan';
      case 'api_key_hint':          return 'Masukkan Pollinations API key';
      case 'upload_app_key':        return 'Upload Pollinations App Key';
      case 'change_app_key':        return 'Ganti Pollinations App Key';
      case 'app_key_saved':         return 'Pollinations App Key tersimpan';
      case 'app_key_hint':          return 'Masukkan Pollinations App Key (PK_)';
      case 'delete_chat_history':   return 'Hapus Semua Riwayat Chat';
      case 'delete_chat_subtitle':  return 'Menghapus seluruh percakapan yang tersimpan';
      case 'delete_image_history':  return 'Hapus Semua Riwayat Gambar';
      case 'delete_image_subtitle': return 'Menghapus seluruh gambar yang pernah dibuat/diedit';
      case 'cancel':                return 'Batal';
      case 'save':                  return 'Simpan';
      case 'close':                 return 'Tutup';
      case 'delete':                return 'Hapus';
      case 'select_image_model':    return 'Pilih Model Gambar';
      case 'select_aspect_ratio':   return 'Pilih Rasio Gambar';
      case 'select_chat_model':     return 'Pilih Model Chat';
      case 'select_language':       return 'Pilih Bahasa';
      case 'api_key_empty':         return 'Pollinations API key tidak boleh kosong.';
      case 'api_key_success':       return 'Pollinations API key berhasil disimpan.';
      case 'app_key_empty':         return 'Pollinations App Key tidak boleh kosong.';
      case 'app_key_success':       return 'Pollinations App Key berhasil disimpan.';
      case 'chat_deleted':          return 'Riwayat chat berhasil dihapus.';
      case 'image_deleted':         return 'Riwayat gambar berhasil dihapus.';
      case 'delete_chat_title':     return 'Hapus semua chat?';
      case 'delete_chat_msg':       return 'Semua riwayat percakapan akan dihapus permanen.';
      case 'delete_image_title':    return 'Hapus semua gambar?';
      case 'delete_image_msg':      return 'Semua riwayat gambar akan dihapus permanen.';
      case 'app_version':           return 'Versi 1.0.0 - Powered by Rekty Anjany';
      case 'license_view':          return 'Lihat ketentuan penggunaan Rekty AI';
      case 'privacy_subtitle':      return 'Kebijakan privasi Rekty AI Studio';
      default:                      return key;
    }
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadApiKeyState();
    _testPollinationsModels();
    // Listen ke perubahan bahasa global
    languageNotifier.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    languageNotifier.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (!mounted) return;
    setState(() => _selectedLanguage = languageNotifier.value);
  }

  Future<void> _testPollinationsModels() async {
    final models = await PollinationsService.getModels();
    print('====================');
    print('TOTAL MODELS: ${models.length}');
    print('POLLINATIONS MODELS');
    print(models);
    print('====================');
  }

  Future<void> _loadApiKeyState() async {
    final pollinationsKey = await _apiKeyService.getPollinationsApiKey();
    final pollinationsAppKey = await _apiKeyService.getPollinationsAppKey();
    final savedModel = await _apiKeyService.getImageModel();
    final savedChatModel = await _apiKeyService.getChatModel();
    final savedAspectRatio = await _apiKeyService.getAspectRatio();

    print('MODEL DARI STORAGE: $savedModel');
    print('ASPECT RATIO DARI STORAGE: $savedAspectRatio');

    if (!mounted) return;

    setState(() {
      _hasPollinationsKey = pollinationsKey != null && pollinationsKey.isNotEmpty;
      _hasPollinationsAppKey = pollinationsAppKey != null && pollinationsAppKey.isNotEmpty;
      _selectedImageModel = savedModel ?? 'flux';
      _selectedChatModel = savedChatModel ?? 'openai';
      _selectedAspectRatio = savedAspectRatio ?? '1:1 Square';
      _selectedLanguage = languageNotifier.value;
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        title: Text(tr('settings'), style: const TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // ── Tentang ────────────────────────────────────────────
          _sectionLabel(tr('about')),
          _infoTile(
            icon: Icons.auto_awesome,
            title: 'Rekty AI',
            subtitle: tr('app_version'),
          ),
          _actionTile(
            icon: Icons.description_outlined,
            title: tr('license'),
            subtitle: tr('license_view'),
            color: const Color(0xFF00E5FF),
            onTap: _showLicenseDialog,
          ),
          _actionTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: tr('privacy_subtitle'),
            color: const Color(0xFF00E5FF),
            onTap: _showPrivacyPolicyDialog,
          ),
          _actionTile(
            icon: Icons.menu_book_outlined,
            title: tr('readme'),
            subtitle: tr('readme_subtitle'),
            color: const Color(0xFF00E5FF),
            onTap: _showReadmeDialog,
          ),

          const Divider(color: Colors.white12, height: 24),

          // ── Konfigurasi API ────────────────────────────────────
          _sectionLabel(tr('api_config')),
          _actionTile(
            icon: Icons.image,
            title: _hasPollinationsKey ? tr('change_api_key') : tr('upload_api_key'),
            subtitle: _hasPollinationsKey ? tr('api_key_saved') : tr('api_key_hint'),
            color: const Color(0xFF00E5FF),
            onTap: _showPollinationsApiKeyDialog,
          ),
          _actionTile(
            icon: Icons.vpn_key,
            title: _hasPollinationsAppKey ? tr('change_app_key') : tr('upload_app_key'),
            subtitle: _hasPollinationsAppKey ? tr('app_key_saved') : tr('app_key_hint'),
            color: const Color(0xFF00E5FF),
            onTap: _showPollinationsAppKeyDialog,
          ),

          // ── Model & Rasio ──────────────────────────────────────
          _actionTile(
            icon: Icons.auto_awesome,
            title: tr('image_model'),
            subtitle: _selectedImageModel,
            color: const Color(0xFF00E5FF),
            onTap: _showImageModelDialog,
          ),

          _actionTile(
            icon: Icons.aspect_ratio,
            title: tr('aspect_ratio'),
            subtitle: _aspectRatioLabel(_selectedAspectRatio),
            color: const Color(0xFF00E5FF),
            onTap: _showAspectRatioDialog,
          ),

          _actionTile(
            icon: Icons.chat,
            title: tr('chat_model'),
            subtitle: _selectedChatModel,
            color: const Color(0xFF00E5FF),
            onTap: _showChatModelDialog,
          ),
          _actionTile(
            icon: Icons.language,
            title: tr('language'),
            subtitle: _selectedLanguage,
            color: const Color(0xFF00E5FF),
            onTap: _showLanguageDialog,
          ),

          const Divider(color: Colors.white12, height: 24),

          // ── Data ──────────────────────────────────────────────
          _sectionLabel(tr('data')),
          _actionTile(
            icon: Icons.delete_sweep_outlined,
            title: tr('delete_chat_history'),
            subtitle: tr('delete_chat_subtitle'),
            onTap: () => _confirmAction(
              title: tr('delete_chat_title'),
              message: tr('delete_chat_msg'),
              confirmLabel: tr('delete'),
              onConfirm: () async {
                await _isarService.clearAllMessages();
                _showSnack(tr('chat_deleted'));
              },
            ),
          ),
          _actionTile(
            icon: Icons.image_not_supported_outlined,
            title: tr('delete_image_history'),
            subtitle: tr('delete_image_subtitle'),
            onTap: () => _confirmAction(
              title: tr('delete_image_title'),
              message: tr('delete_image_msg'),
              confirmLabel: tr('delete'),
              onConfirm: () async {
                await _isarService.clearAllImageHistory();
                _showSnack(tr('image_deleted'));
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper: label aspect ratio ─────────────────────────────────────────

  String _aspectRatioLabel(String key) {
    final entry = kAspectRatios.firstWhere(
      (e) => e['key'] == key,
      orElse: () => {'key': key, 'label': key, 'icon': '⬛'},
    );
    return '${entry['icon']} ${entry['label']}';
  }

  // ── Helper widgets ─────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF00E5FF),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF00E5FF)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38)),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color = Colors.redAccent,
  }) {
    return ListTile(
      leading: Icon(icon, color: color.withValues(alpha: 0.9)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white30),
      onTap: onTap,
    );
  }

  // ── Dialog: Pollinations API Key ──────────────────────────────────────

  void _showPollinationsApiKeyDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101417),
        title: const Text('Pollinations API Key',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: tr('api_key_hint'),
            hintStyle: const TextStyle(color: Colors.white38),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0x3300E5FF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00E5FF)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('cancel'), style: const TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              final key = controller.text.trim();
              if (key.isEmpty) {
                _showSnack(tr('api_key_empty'));
                return;
              }
              final nav = Navigator.of(context);
              await _apiKeyService.savePollinationsApiKey(key);
              if (!mounted) return;
              nav.pop();
              await _loadApiKeyState();
              if (!mounted) return;
              _showSnack(tr('api_key_success'));
            },
            child: Text(tr('save'), style: const TextStyle(color: Color(0xFF00E5FF))),
          ),
        ],
      ),
    );
  }

  // ── Dialog: Pollinations App Key ──────────────────────────────────────

  void _showPollinationsAppKeyDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101417),
        title: const Text('Pollinations App Key',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: tr('app_key_hint'),
            hintStyle: const TextStyle(color: Colors.white38),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0x3300E5FF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00E5FF)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('cancel'), style: const TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              final key = controller.text.trim();
              if (key.isEmpty) {
                _showSnack(tr('app_key_empty'));
                return;
              }
              final nav = Navigator.of(context);
              await _apiKeyService.savePollinationsAppKey(key);
              if (!mounted) return;
              nav.pop();
              await _loadApiKeyState();
              if (!mounted) return;
              _showSnack(tr('app_key_success'));
            },
            child: Text(tr('save'), style: const TextStyle(color: Color(0xFF00E5FF))),
          ),
        ],
      ),
    );
  }

  // ── Dialog: Pilih Model Gambar ─────────────────────────────────────────

  void _showImageModelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101417),
        title: Text(tr('select_image_model'), style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              const MapEntry('auto', 'Auto (Recommended)'),
              ...PollinationsModels.imageModels.entries,
            ].map((entry) {
              return RadioListTile<String>(
                value: entry.key,
                groupValue: _selectedImageModel,
                activeColor: const Color(0xFF00E5FF),
                title: Text(entry.value, style: const TextStyle(color: Colors.white)),
                onChanged: (value) async {
                  if (value == null) return;
                  await ApiKeyService.instance.saveImageModel(value);
                  if (!mounted) return;
                  setState(() => _selectedImageModel = value);
                  Navigator.pop(this.context);
                  print('MODEL TERSIMPAN: $value');
                  print('MODEL TERPILIH: $_selectedImageModel');
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ── Dialog: Pilih Aspect Ratio ─────────────────────────────────────────

  void _showAspectRatioDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101417),
        title: Text(tr('select_aspect_ratio'), style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: kAspectRatios.map((entry) {
              final key = entry['key']!;
              final label = entry['label']!;
              final icon = entry['icon']!;
              return RadioListTile<String>(
                value: key,
                groupValue: _selectedAspectRatio,
                activeColor: const Color(0xFF00E5FF),
                title: Text('$icon  $label', style: const TextStyle(color: Colors.white)),
                subtitle: _buildAspectRatioSize(key),
                onChanged: (value) async {
                  if (value == null) return;
                  await ApiKeyService.instance.saveAspectRatio(value);
                  if (!mounted) return;
                  setState(() => _selectedAspectRatio = value);
                  Navigator.pop(this.context);
                  print('ASPECT RATIO TERSIMPAN: $value');
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('close'), style: const TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  Widget? _buildAspectRatioSize(String key) {
    const sizeMap = {
      '1:1 Square':      '1024 × 1024 px',
      '3:4 Portrait':    '1024 × 1365 px',
      '2:3 Portrait':    '1024 × 1536 px',
      '9:16 Story HD':   '1080 × 1920 px',
      '9:16 Mobile':     '830 × 1536 px',
      '4:3 Landscape':   '1365 × 1024 px',
      '3:2 Landscape':   '1536 × 1024 px',
      '16:9 Widescreen': '1820 × 1024 px',
    };
    final size = sizeMap[key];
    if (size == null) return null;
    return Text(size, style: const TextStyle(color: Colors.white38, fontSize: 12));
  }

  // ── Dialog: Pilih Model Chat ───────────────────────────────────────────

  void _showChatModelDialog() {
    final chatModels = [
      'openai',
      'deepseek',
      'mistral',
      'gemini',
      'claude',
      'nova-fast',
      'gemini-fast',
      'mistral-small-3.2',
      'gemini-search',
      'llama-scout',
      'qwen-coder',
      'gemma',
      'gemini-flash-lite-3.1',
      'openai-fast',
      'openai-fastgemini-flash-lite-3.1',
      'minimax-m2.7',
      'perplexity-fast',
      'claude-opus-4.6',
      'qwen-vision',
      'step-3.5-flash',
      'llama',
      'midijourney',
      'nova',
      'perplexity-deep',
      'step-flash',
      'grok',
      'mistral-large',
      'gpt-5.4-mini',
      'qwen-vision-pro',
      'deepseek-pro',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101417),
        title: Text(tr('select_chat_model'), style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: chatModels.map((model) {
              return RadioListTile<String>(
                value: model,
                groupValue: _selectedChatModel,
                activeColor: const Color(0xFF00E5FF),
                title: Text(model, style: const TextStyle(color: Colors.white)),
                onChanged: (value) async {
                  if (value == null) return;
                  await ApiKeyService.instance.saveChatModel(value);
                  if (!mounted) return;
                  setState(() => _selectedChatModel = value);
                  Navigator.pop(this.context);
                  print('CHAT MODEL TERSIMPAN: $value');
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ── Dialog: Pilih Bahasa ───────────────────────────────────────────────

  void _showLanguageDialog() {
    final languages = [
      'Indonesia',
      'English',
      'Chinese',
      'Japanese',
      'Korean',
      'Thai',
      'Vietnamese',
      'Hindi',
      'Arabic',
      'Russian',
      'French',
      'German',
      'Spanish',
      'Portuguese',
      'Turkish',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101417),
        title: Text(tr('select_language'), style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: languages.map((language) {
              return RadioListTile<String>(
                value: language,
                groupValue: _selectedLanguage,
                activeColor: const Color(0xFF00E5FF),
                title: Text(language, style: const TextStyle(color: Colors.white)),
                onChanged: (value) async {
                  if (value == null) return;
                  // saveLanguage sudah update languageNotifier secara otomatis
                  await LanguageService.instance.saveLanguage(value);
                  if (!mounted) return;
                  setState(() => _selectedLanguage = value);
                  Navigator.pop(this.context);
                  print('BAHASA TERSIMPAN: $value');
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ── Dialog: Konfirmasi Hapus ───────────────────────────────────────────

  void _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
    required Future<void> Function() onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101417),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('cancel'), style: const TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await onConfirm();
            },
            child: Text(confirmLabel, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // ── Dialog: Privacy Policy ────────────────────────────────────────────

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101417),
        title: const Text('Privacy Policy', style: TextStyle(color: Colors.white)),
        content: const SingleChildScrollView(
          child: Text(
            '''
Privacy Policy - Rekty AI Studio
Last Updated: June 2026

Rekty AI Studio respects your privacy and is committed to protecting your information.

INFORMATION WE COLLECT
The application may collect:
- User messages sent to AI services.
- Generated AI responses.
- Device and diagnostic information.
- Advertising data used by Google AdMob.
- Application usage information.

AI SERVICES
Rekty AI Studio uses third-party AI services to generate text and images. User requests may be transmitted to these services to provide AI functionality.

LOCAL STORAGE
Chat history, settings, and application data may be stored locally on your device to improve user experience.

ADVERTISING
Rekty AI Studio uses Google AdMob to display advertisements. AdMob may collect and process data according to Google's Privacy Policy.

DATA SECURITY
We take reasonable measures to protect user information, but no method of transmission over the Internet is completely secure.

CHILDREN'S PRIVACY
The application is not intended for children under 13 years of age.

CHANGES TO THIS POLICY
This Privacy Policy may be updated from time to time. Changes will be posted on this page.

CONTACT
Developer: Rekty Anjany
Email: rekty.anjany@gmail.com
''',
            style: TextStyle(color: Colors.white70, height: 1.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF00E5FF))),
          ),
        ],
      ),
    );
  }

  // ── Dialog: Lisensi ────────────────────────────────────────────────────

  void _showLicenseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101417),
        title: const Text('Lisensi Rekty AI', style: TextStyle(color: Colors.white)),
        content: const SingleChildScrollView(
          child: Text(
            '''
REKTY AI LICENSE AGREEMENT

Versi 1.0.0

© 2026 Rekty. All Rights Reserved.

1. Pengguna diperbolehkan menggunakan aplikasi untuk kebutuhan pribadi maupun bisnis.

2. Dilarang menjual ulang, mendistribusikan ulang, atau memodifikasi aplikasi untuk tujuan komersial tanpa izin tertulis dari Rekty.

3. Beberapa fitur menggunakan layanan AI pihak ketiga dan API Key yang valid.

4. Aplikasi disediakan sebagaimana adanya tanpa jaminan apa pun.

5. Pengembang tidak bertanggung jawab atas kehilangan data, kerugian bisnis, atau gangguan layanan pihak ketiga.

6. Dengan menggunakan aplikasi ini, pengguna dianggap menyetujui seluruh ketentuan lisensi.

© 2026 Rekty
rekty.anjany@gmail.com
            ''',
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF00E5FF))),
          ),
        ],
      ),
    );
  }

  // ── Snackbar ───────────────────────────────────────────────────────────

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF101417),
      ),
    );
  }

  // ── README dialog (tidak berubah, kontennya teknis/statis) ─────────────

  Widget _readmeHeading(String text) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF00E5FF),
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 0.3,
          ),
        ),
      );

  Widget _readmeBody(String text) => Text(
        text,
        style: const TextStyle(color: Colors.white70, height: 1.65, fontSize: 13),
      );

  Widget _readmeCode(String text) => Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0E11),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x2200E5FF)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF00E5FF),
            fontFamily: 'monospace',
            fontSize: 12,
            height: 1.6,
          ),
        ),
      );

  Widget _readmeDivider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Divider(color: Colors.white12),
      );

  void _showReadmeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101417),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        title: const Row(
          children: [
            Icon(Icons.menu_book_outlined, color: Color(0xFF00E5FF), size: 20),
            SizedBox(width: 8),
            Text('README', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Column(
                    children: [
                      Image.network(
                        'https://image.pollinations.ai/prompt/pollinations%20ai%20logo%20text%20white%20minimal%20clean?width=360&height=100&model=flux&nologo=true',
                        height: 52,
                        errorBuilder: (_, __, ___) => const Text(
                          '🌸 pollinations.ai',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Image.network(
                        'https://pollinations.ai/p/built%20with%20pollinations%20badge%20white?width=200&height=48&model=flux&nologo=true',
                        height: 36,
                        errorBuilder: (_, __, ___) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF00E5FF)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '✦ Built With pollinations.ai',
                            style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _readmeDivider(),
                const Text('Rekty AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 5),
                _readmeBody('Aplikasi chat AI + generate/edit gambar berbasis Pollinations.ai, dibangun dengan Flutter.'),
                const SizedBox(height: 8),
                _readmeBody(
                  'Konfigurasi project ini disesuaikan untuk:\n'
                  '  • Flutter 3.2.8\n'
                  '  • Java 17\n'
                  '  • Android minSdk 26 (Android 8.0+)\n'
                  '  • Gradle 7.6.3 + AGP 7.4.2 + Kotlin 1.8.22',
                ),
                _readmeDivider(),
                _readmeHeading('⚠️ WAJIB DIBACA SEBELUM BUILD'),
                _readmeBody(
                  'Project ini berisi source code lengkap, tapi untuk jadi file .apk '
                  'yang jalan, kamu harus menjalankan beberapa langkah build di komputer '
                  'kamu sendiri (Flutter SDK tidak bisa dijalankan dari chat ini).',
                ),
                _readmeDivider(),
                _readmeHeading('🌸 Powered by Pollinations.ai'),
                _readmeBody(
                  'Rekty AI menggunakan Pollinations.ai sebagai backbone untuk:\n'
                  '  • Generasi gambar — model Flux, Turbo, dan lainnya\n'
                  '  • Chat AI — OpenAI, Gemini, DeepSeek, Mistral, Claude, dan lagi\n'
                  '  • Vision — kirim gambar ke AI untuk dianalisis\n\n'
                  'Website   : https://pollinations.ai\n'
                  'API Docs  : https://pollinations.ai/docs',
                ),
                _readmeDivider(),
                _readmeHeading('Langkah 1 — Install Prasyarat'),
                _readmeBody(
                  'Pastikan sudah terinstall di komputer kamu:\n\n'
                  '1. Flutter SDK 3.2.8\n'
                  '   https://docs.flutter.dev/get-started/install\n\n'
                  '2. Java 17 (JDK 17) — pastikan JAVA_HOME mengarah ke JDK 17\n\n'
                  '3. Android Studio dengan Android SDK Platform 34 dan minimal API 26\n\n'
                  '4. Jalankan flutter doctor — pastikan semua centang hijau.',
                ),
                _readmeDivider(),
                _readmeHeading('Langkah 2 — Isi API Key Pollinations'),
                _readmeBody(
                  'Lebih mudah: isi langsung di dalam app via\nSettings → Konfigurasi API.\n\n'
                  '  • Pollinations API Key — dari https://pollinations.ai\n'
                  '  • Pollinations App Key (opsional, dimulai PK_) — untuk fitur premium\n\n'
                  'Tanpa API key pun app sudah bisa jalan dengan model gratis Pollinations.ai.',
                ),
                _readmeDivider(),
                _readmeHeading('Langkah 3 — Isi local.properties'),
                _readmeBody('Buka file: android/local.properties\nContoh macOS:'),
                _readmeCode(
                  'sdk.dir=/Users/namakamu/Library/Android/sdk\n'
                  'flutter.sdk=/Users/namakamu/flutter',
                ),
                _readmeBody('Contoh Windows:'),
                _readmeCode(
                  r'sdk.dir=C:\\Users\\NamaKamu\\AppData\\Local\\Android\\sdk'
                  '\n'
                  r'flutter.sdk=C:\Users\Administrator\develop\flutter',
                ),
                _readmeDivider(),
                _readmeHeading('Langkah 4 — Install Dependencies & Generate DB Code'),
                _readmeBody('Jalankan di terminal (folder root project):'),
                _readmeCode(
                  'flutter pub get\n'
                  'flutter pub run build_runner build --delete-conflicting-outputs',
                ),
                _readmeDivider(),
                _readmeHeading('Langkah 5 — Build APK'),
                _readmeBody('Testing cepat (debug):'),
                _readmeCode('flutter run'),
                _readmeBody('Build APK final (release):'),
                _readmeCode('flutter build apk --release'),
                _readmeBody(
                  'File hasil build:\n'
                  'build/app/outputs/flutter-apk/app-release.apk\n\n'
                  'Install ke HP Android — aktifkan "Install dari sumber tidak dikenal" di Settings HP.',
                ),
                _readmeDivider(),
                _readmeHeading('Struktur Project'),
                _readmeCode(
                  'lib/\n'
                  '├── main.dart               # Entry point, tema dark & DB\n'
                  '├── models/\n'
                  '│   ├── chat_message.dart   # Model pesan (Isar)\n'
                  '│   └── image_history.dart  # Model gambar (Isar)\n'
                  '├── services/\n'
                  '│   ├── api_key_service.dart\n'
                  '│   ├── pollinations_service.dart\n'
                  '│   ├── pollinations_models.dart\n'
                  '│   ├── isar_service.dart\n'
                  '│   ├── image_service.dart\n'
                  '│   └── language_service.dart\n'
                  '├── screens/\n'
                  '│   ├── chat_screen.dart\n'
                  '│   ├── history_screen.dart\n'
                  '│   └── settings_screen.dart\n'
                  '└── widgets/\n'
                  '    ├── chat_bubble.dart\n'
                  '    └── loading_widget.dart',
                ),
                _readmeDivider(),
                _readmeHeading('✅ Fitur'),
                _readmeBody(
                  '• Chat teks dengan berbagai model AI (via Pollinations.ai)\n'
                  '• Kirim gambar untuk ditanya (vision)\n'
                  '• Generate gambar baru dari prompt teks\n'
                  '• Edit gambar yang sudah ada dengan instruksi teks\n'
                  '• Riwayat chat tersimpan lokal (Isar database)\n'
                  '• Galeri riwayat gambar dengan favorite & delete\n'
                  '• Pilihan aspect ratio gambar (Square, Portrait, Widescreen, dll)\n'
                  '• Multi-bahasa (Indonesia, English, dan 13 bahasa lainnya)\n'
                  '• Dark theme modern hitam',
                ),
                _readmeDivider(),
                _readmeHeading('⚠️ Catatan: Model Berubah Seiring Waktu'),
                _readmeBody(
                  'Pollinations.ai sering menambah atau meng-update model. Kalau app '
                  'mendadak error "model not found", ganti model di:\n'
                  'Settings → Konfigurasi API\n\n'
                  'Cek model terbaru di:\n'
                  '  • https://pollinations.ai/docs\n'
                  '  • https://pollinations.ai/models',
                ),
                _readmeDivider(),
                _readmeHeading('🛠 Troubleshooting Umum'),
                _buildTroubleshootingTable(),
                _readmeDivider(),
                _readmeHeading('Kontak'),
                _readmeBody('Developer : Rekty Anjany\nEmail     : rekty.anjany@gmail.com'),
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      Image.network(
                        'https://image.pollinations.ai/prompt/pollinations%20ai%20logo%20white%20flower%20minimal?width=120&height=120&model=flux&nologo=true',
                        height: 44,
                        errorBuilder: (_, __, ___) => const Text('🌸', style: TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(height: 6),
                      const Text('Powered by pollinations.ai', style: TextStyle(color: Colors.white38, fontSize: 11)),
                      const SizedBox(height: 4),
                      const Text('© 2026 Rekty Anjany', style: TextStyle(color: Colors.white24, fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF00E5FF))),
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingTable() {
    final rows = [
      ['flutter.sdk not set in local.properties', 'Isi ulang android/local.properties sesuai Langkah 3'],
      ['Error ChatMessageSchema not found', 'Jalankan ulang build_runner (Langkah 4)'],
      ['Build gagal di Gradle', 'Pastikan compileSdk/targetSdk 34 terinstall di Android Studio → SDK Manager'],
      ['Gambar gagal di-generate', 'Pastikan API key valid & model masih tersedia di Pollinations.ai'],
      ['App force-close saat dibuka', 'Jalankan flutter run dulu untuk lihat error log detail'],
      ['Unsupported class file major version', 'JAVA_HOME mengarah ke Java bukan versi 17. Cek java -version'],
      ['Error kotlin-stdlib versi', 'Jalankan flutter clean lalu flutter pub get ulang, baru build lagi'],
      ['Gradle gagal download/timeout', 'Cek koneksi, atau download manual Gradle 7.6.3 dari services.gradle.org'],
      ['minSdkVersion conflict', 'Cek error log untuk nama plugin yang konflik, sesuaikan minSdk'],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows.map((row) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0E11),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x1500E5FF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(row[0], style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontFamily: 'monospace')),
              const SizedBox(height: 4),
              Text(row[1], style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.5)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
