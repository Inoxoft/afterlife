import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/utils/ukrainian_font_utils.dart';
import '../../core/widgets/animated_particles.dart';
import '../../l10n/app_localizations.dart';
import '../models/character_model.dart';
import '../providers/characters_provider.dart';
import '../character_prompts/famous_character_prompts.dart';
import 'models/group_chat_model.dart';
import '../providers/group_chat_provider.dart';

class CharacterSelectionScreen extends StatefulWidget {
  final GroupChatModel? existingGroup; // For editing existing groups
  final Function(GroupChatModel)? onGroupCreated;

  const CharacterSelectionScreen({
    Key? key,
    this.existingGroup,
    this.onGroupCreated,
  }) : super(key: key);

  @override
  State<CharacterSelectionScreen> createState() => _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen>
    with TickerProviderStateMixin {
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Selection state
  final Set<String> _selectedCharacterIds = <String>{};
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // UI state
  int _selectedTabIndex = 0; // 0: Famous, 1: Your Characters
  bool _isCreatingGroup = false;
  String? _errorMessage;
  
  // Data
  List<Map<String, dynamic>> _famousCharacters = [];
  List<CharacterModel> _userCharacters = [];

  // Cached widgets for performance
  late final Widget _particleBackground = const Opacity(
    opacity: 0.3,
    child: AnimatedParticles(
      particleCount: 15,
      particleColor: AppTheme.warmGold,
      minSpeed: 0.01,
      maxSpeed: 0.03,
    ),
  );

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCharacters();
    _initializeEditMode();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));

    _fadeController.forward();
    _slideController.forward();
  }

  void _loadCharacters() {
    try {
      // Load famous characters
      _famousCharacters = FamousCharacterPrompts.getAllCharacters();
      print('🔧 [CharacterSelection] Loaded ${_famousCharacters.length} famous characters');
    } catch (e) {
      print('❌ [CharacterSelection] Error loading famous characters: $e');
      _famousCharacters = [];
    }
    
    try {
      // Load user characters
      final charactersProvider = Provider.of<CharactersProvider>(context, listen: false);
      _userCharacters = charactersProvider.characters;
      print('🔧 [CharacterSelection] Loaded ${_userCharacters.length} user characters');
    } catch (e) {
      print('❌ [CharacterSelection] Error loading user characters: $e');
      _userCharacters = [];
    }
  }

  void _initializeEditMode() {
    if (widget.existingGroup != null) {
      _selectedCharacterIds.addAll(widget.existingGroup!.characterIds);
      _groupNameController.text = widget.existingGroup!.name;
      _descriptionController.text = widget.existingGroup!.description ?? '';
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _groupNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canCreateGroup {
    return _selectedCharacterIds.length >= 2 && 
           _selectedCharacterIds.length <= 6 &&
           _groupNameController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final fontScale = ResponsiveUtils.getFontSizeScale(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: Stack(
          children: [
            // Background particles
            RepaintBoundary(child: _particleBackground),
            
            // Main content
            SafeArea(
              child: Column(
                children: [
                  _buildAppBar(localizations, fontScale),
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildMainContent(localizations, fontScale),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(AppLocalizations localizations, double fontScale) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.getScreenPadding(context).horizontal),
      child: Row(
        children: [
          // Back button
          Container(
            decoration: BoxDecoration(
              color: AppTheme.midnightPurple.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.warmGold.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: AppTheme.warmGold,
                size: 20 * fontScale,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Title
          Expanded(
            child: Text(
              widget.existingGroup != null 
                  ? localizations.editGroupChat 
                  : localizations.createGroupChat,
              style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                text: widget.existingGroup != null 
                    ? localizations.editGroupChat 
                    : localizations.createGroupChat,
                fontSize: 24 * fontScale,
                fontWeight: FontWeight.bold,
                color: AppTheme.warmGold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          
          // Selected count badge
          if (_selectedCharacterIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.warmGold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.warmGold.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Text(
                '${_selectedCharacterIds.length}/6',
                style: UkrainianFontUtils.latoWithUkrainianSupport(
                  text: '${_selectedCharacterIds.length}/6',
                  fontSize: 14 * fontScale,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.warmGold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent(AppLocalizations localizations, double fontScale) {
    return Column(
      children: [
        // Group details section
        _buildGroupDetailsSection(localizations, fontScale),
        
        // Character selection tabs
        _buildCharacterTabs(localizations, fontScale),
        
        // Character grid (flexible to take available space)
        Expanded(child: _buildCharacterGrid(localizations, fontScale)),
        
        // Action buttons (fixed at bottom)
        SafeArea(
          top: false,
          child: _buildActionButtons(localizations, fontScale),
        ),
      ],
    );
  }

  Widget _buildGroupDetailsSection(AppLocalizations localizations, double fontScale) {
    return Container(
      margin: EdgeInsets.all(ResponsiveUtils.getScreenPadding(context).horizontal),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.containerDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group name input
          Text(
            localizations.groupName,
            style: UkrainianFontUtils.latoWithUkrainianSupport(
              text: localizations.groupName,
              fontSize: 16 * fontScale,
              fontWeight: FontWeight.bold,
              color: AppTheme.warmGold,
            ),
          ),
          const SizedBox(height: 8),
          
          TextField(
            controller: _groupNameController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: localizations.enterGroupName,
              hintStyle: UkrainianFontUtils.latoWithUkrainianSupport(
                text: localizations.enterGroupName,
                fontSize: 14 * fontScale,
                color: AppTheme.silverMist.withValues(alpha: 0.5),
              ),
              filled: true,
              fillColor: AppTheme.deepNavy.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.warmGold.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.warmGold.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.warmGold.withValues(alpha: 0.7),
                  width: 2,
                ),
              ),
            ),
            style: UkrainianFontUtils.latoWithUkrainianSupport(
              text: _groupNameController.text,
              fontSize: 16 * fontScale,
              color: AppTheme.silverMist,
            ),
          ),
          
          if (_selectedCharacterIds.isNotEmpty) ...[
            const SizedBox(height: 16),
            
            // Selected characters preview
            Text(
              localizations.selectedCharacters,
              style: UkrainianFontUtils.latoWithUkrainianSupport(
                text: localizations.selectedCharacters,
                fontSize: 14 * fontScale,
                fontWeight: FontWeight.bold,
                color: AppTheme.warmGold,
              ),
            ),
            const SizedBox(height: 8),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedCharacterIds.map((characterId) {
                final characterName = _getCharacterName(characterId);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.warmGold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.warmGold.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        characterName,
                        style: UkrainianFontUtils.latoWithUkrainianSupport(
                          text: characterName,
                          fontSize: 12 * fontScale,
                          color: AppTheme.silverMist,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _toggleCharacterSelection(characterId),
                        child: Icon(
                          Icons.close,
                          size: 16 * fontScale,
                          color: AppTheme.warmGold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCharacterTabs(AppLocalizations localizations, double fontScale) {
    return Consumer<CharactersProvider>(
      builder: (context, charactersProvider, child) {
        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.getScreenPadding(context).horizontal,
          ),
          child: Row(
            children: [
              _buildTab(
                localizations.famousCharacters,
                0,
                _famousCharacters.length,
                fontScale,
              ),
              const SizedBox(width: 16),
              _buildTab(
                localizations.yourCharacters,
                1,
                charactersProvider.characters.length,
                fontScale,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTab(String title, int index, int count, double fontScale) {
    final isSelected = _selectedTabIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppTheme.warmGold.withValues(alpha: 0.2)
                : AppTheme.midnightPurple.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? AppTheme.warmGold.withValues(alpha: 0.7)
                  : AppTheme.warmGold.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: UkrainianFontUtils.latoWithUkrainianSupport(
                  text: title,
                  fontSize: 14 * fontScale,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.warmGold : AppTheme.silverMist,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count ${count == 1 ? 'character' : 'characters'}',
                style: UkrainianFontUtils.latoWithUkrainianSupport(
                  text: '$count ${count == 1 ? 'character' : 'characters'}',
                  fontSize: 12 * fontScale,
                  color: AppTheme.silverMist.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterGrid(AppLocalizations localizations, double fontScale) {
    return Consumer<CharactersProvider>(
      builder: (context, charactersProvider, child) {
        // Get current characters without triggering state changes
        final userCharacters = charactersProvider.characters;
        final characters = _selectedTabIndex == 0 ? _famousCharacters : userCharacters;
        
        print('🔧 [CharacterSelection] Building grid - Tab: $_selectedTabIndex, Count: ${characters.length}');
        
        if (characters.isEmpty) {
          return _buildEmptyState(localizations, fontScale);
        }

        return Container(
          margin: EdgeInsets.all(ResponsiveUtils.getScreenPadding(context).horizontal),
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ResponsiveUtils.getGridCrossAxisCount(context),
              childAspectRatio: ResponsiveUtils.getGridChildAspectRatio(context),
              crossAxisSpacing: ResponsiveUtils.getGridSpacing(context),
              mainAxisSpacing: ResponsiveUtils.getGridSpacing(context),
            ),
            itemCount: characters.length,
            itemBuilder: (context, index) {
              try {
                if (_selectedTabIndex == 0) {
                  final character = characters[index];
                  if (character is Map<String, dynamic>) {
                    final characterId = 'famous_${character['name']}';
                    return _buildFamousCharacterCard(character, characterId, fontScale);
                  } else {
                    print('❌ [CharacterSelection] Expected Map for famous character, got: ${character.runtimeType}');
                    return _buildErrorCharacterCard('Invalid famous character data', fontScale);
                  }
                } else {
                  final character = characters[index];
                  if (character is CharacterModel) {
                    return _buildUserCharacterCard(character, fontScale);
                  } else {
                    print('❌ [CharacterSelection] Expected CharacterModel for user character, got: ${character.runtimeType}');
                    return _buildErrorCharacterCard('Invalid user character data', fontScale);
                  }
                }
              } catch (e) {
                print('❌ [CharacterSelection] Error building character card: $e');
                return _buildErrorCharacterCard('Error loading character', fontScale);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildFamousCharacterCard(
    Map<String, dynamic> character,
    String characterId,
    double fontScale,
  ) {
    final isSelected = _selectedCharacterIds.contains(characterId);
    final name = character['name'] as String;
    final profession = character['profession'] as String;
    final imageUrl = character['imageUrl'] as String?;

    return GestureDetector(
      onTap: () => _toggleCharacterSelection(characterId),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.midnightPurple.withValues(alpha: isSelected ? 0.9 : 0.7),
              AppTheme.deepNavy.withValues(alpha: isSelected ? 0.8 : 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? AppTheme.warmGold.withValues(alpha: 0.8)
                : AppTheme.warmGold.withValues(alpha: 0.3),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? AppTheme.warmGold.withValues(alpha: 0.4)
                  : AppTheme.deepNavy.withValues(alpha: 0.3),
              blurRadius: isSelected ? 15 : 8,
              spreadRadius: isSelected ? 2 : 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Character image or avatar
            if (imageUrl != null)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.asset(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildCharacterInitials(name, fontScale);
                    },
                  ),
                ),
              )
            else
              _buildCharacterInitials(name, fontScale),
            
            // Selection overlay
            if (isSelected)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.warmGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            
            // Selection checkbox
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppTheme.warmGold 
                      : AppTheme.silverMist.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.warmGold,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color: AppTheme.deepNavy,
                      )
                    : null,
              ),
            ),
            
            // Character info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppTheme.deepNavy.withValues(alpha: 0.9),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                        text: name,
                        fontSize: 14 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.silverMist,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profession,
                      style: UkrainianFontUtils.latoWithUkrainianSupport(
                        text: profession,
                        fontSize: 10 * fontScale,
                        color: AppTheme.silverMist.withValues(alpha: 0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCharacterCard(CharacterModel character, double fontScale) {
    final isSelected = _selectedCharacterIds.contains(character.id);

    return GestureDetector(
      onTap: () => _toggleCharacterSelection(character.id),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.midnightPurple.withValues(alpha: isSelected ? 0.9 : 0.7),
              AppTheme.deepNavy.withValues(alpha: isSelected ? 0.8 : 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? AppTheme.warmGold.withValues(alpha: 0.8)
                : AppTheme.warmGold.withValues(alpha: 0.3),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? AppTheme.warmGold.withValues(alpha: 0.4)
                  : AppTheme.deepNavy.withValues(alpha: 0.3),
              blurRadius: isSelected ? 15 : 8,
              spreadRadius: isSelected ? 2 : 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Character content
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Character avatar/icon
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: character.accentColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: character.accentColor.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: character.userImagePath != null
                          ? ClipOval(
                              child: Image.asset(
                                character.userImagePath!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildCharacterIcon(character, fontScale);
                                },
                              ),
                            )
                          : _buildCharacterIcon(character, fontScale),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Character name
                    Text(
                      character.name,
                      style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                        text: character.name,
                        fontSize: 14 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.silverMist,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            
            // Selection overlay
            if (isSelected)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.warmGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            
            // Selection checkbox
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppTheme.warmGold 
                      : AppTheme.silverMist.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.warmGold,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color: AppTheme.deepNavy,
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterInitials(String name, double fontScale) {
    final initials = name.split(' ').map((word) => word.isNotEmpty ? word[0] : '').take(2).join();
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.warmGold.withValues(alpha: 0.3),
            AppTheme.warmGold.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: Text(
          initials,
          style: UkrainianFontUtils.cinzelWithUkrainianSupport(
            text: initials,
            fontSize: 32 * fontScale,
            fontWeight: FontWeight.bold,
            color: AppTheme.warmGold,
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterIcon(CharacterModel character, double fontScale) {
    return Icon(
      character.icon ?? Icons.person,
      size: 32 * fontScale,
      color: character.accentColor,
    );
  }

  Widget _buildErrorCharacterCard(String errorMessage, double fontScale) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red, width: 1),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 32 * fontScale,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: TextStyle(
                color: Colors.red,
                fontSize: 12 * fontScale,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations localizations, double fontScale) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedTabIndex == 0 ? Icons.explore : Icons.person_add,
            size: 64 * fontScale,
            color: AppTheme.warmGold.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedTabIndex == 0 
                ? localizations.noFamousCharacters
                : localizations.noUserCharacters,
            style: UkrainianFontUtils.latoWithUkrainianSupport(
              text: _selectedTabIndex == 0 
                  ? localizations.noFamousCharacters
                  : localizations.noUserCharacters,
              fontSize: 16 * fontScale,
              color: AppTheme.silverMist.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AppLocalizations localizations, double fontScale) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.getScreenPadding(context).horizontal),
      child: Column(
        children: [
          // Error message
          if (_errorMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.errorColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                _errorMessage!,
                style: UkrainianFontUtils.latoWithUkrainianSupport(
                  text: _errorMessage!,
                  fontSize: 14 * fontScale,
                  color: AppTheme.errorColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          
          // Create/Update button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canCreateGroup && !_isCreatingGroup ? _createOrUpdateGroup : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warmGold,
                foregroundColor: AppTheme.deepNavy,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isCreatingGroup
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: AppTheme.deepNavy,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      widget.existingGroup != null 
                          ? localizations.updateGroup
                          : localizations.createGroup,
                      style: UkrainianFontUtils.latoWithUkrainianSupport(
                        text: widget.existingGroup != null 
                            ? localizations.updateGroup
                            : localizations.createGroup,
                        fontSize: 16 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.deepNavy,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleCharacterSelection(String characterId) {
    setState(() {
      if (_selectedCharacterIds.contains(characterId)) {
        _selectedCharacterIds.remove(characterId);
      } else {
        if (_selectedCharacterIds.length < 6) {
          _selectedCharacterIds.add(characterId);
        }
      }
      _errorMessage = null;
    });
  }

  String _getCharacterName(String characterId) {
    if (characterId.startsWith('famous_')) {
      final name = characterId.substring(7);
      return name;
    } else {
      final character = _userCharacters.firstWhere(
        (c) => c.id == characterId,
        orElse: () => CharacterModel(
          id: characterId,
          name: 'Unknown',
          systemPrompt: 'Default character prompt for $characterId',
          createdAt: DateTime.now(),
        ),
      );
      return character.name;
    }
  }

  Future<void> _createOrUpdateGroup() async {
    final localizations = AppLocalizations.of(context);
    
    print('🔧 [CharacterSelection] Starting group creation/update process');
    print('🔧 [CharacterSelection] Selected characters: ${_selectedCharacterIds.length}');
    print('🔧 [CharacterSelection] Character IDs: $_selectedCharacterIds');
    print('🔧 [CharacterSelection] Group name: "${_groupNameController.text.trim()}"');
    print('🔧 [CharacterSelection] Description: "${_descriptionController.text.trim()}"');
    print('🔧 [CharacterSelection] Existing group: ${widget.existingGroup?.id ?? 'none'}');
    print('🔧 [CharacterSelection] Can create group: $_canCreateGroup');
    
    if (!_canCreateGroup) {
      print('❌ [CharacterSelection] Cannot create group - validation failed');
      setState(() {
        _errorMessage = localizations.groupCreationError;
      });
      return;
    }

    setState(() {
      _isCreatingGroup = true;
      _errorMessage = null;
    });

    try {
      print('🔧 [CharacterSelection] Getting GroupChatProvider instance...');
      final groupChatProvider = Provider.of<GroupChatProvider>(context, listen: false);
      print('🔧 [CharacterSelection] GroupChatProvider obtained: ${groupChatProvider.runtimeType}');
      print('🔧 [CharacterSelection] Provider status - Loading: ${groupChatProvider.isLoading}, Error: ${groupChatProvider.lastError}');
      
      if (widget.existingGroup != null) {
        print('🔧 [CharacterSelection] Updating existing group: ${widget.existingGroup!.id}');
        // Update existing group
        final updatedGroup = widget.existingGroup!.copyWith(
          name: _groupNameController.text.trim(),
          characterIds: _selectedCharacterIds.toList(),
        );
        
        print('🔧 [CharacterSelection] Updated group created with ${updatedGroup.characterIds.length} characters');
        print('🔧 [CharacterSelection] Calling updateGroupChat...');
        await groupChatProvider.updateGroupChat(updatedGroup);
        print('✅ [CharacterSelection] Group update completed successfully');
        
        if (mounted) {
          print('🔧 [CharacterSelection] Navigating back with updated group');
          Navigator.of(context).pop(updatedGroup);
        }
      } else {
        print('🔧 [CharacterSelection] Creating new group...');
        // Create new group
        print('🔧 [CharacterSelection] Calling createGroupChat with parameters:');
        print('🔧 [CharacterSelection] - name: "${_groupNameController.text.trim()}"');
        print('🔧 [CharacterSelection] - characterIds: $_selectedCharacterIds');
        print('🔧 [CharacterSelection] - description: "${_descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null}"');
        
        final newGroup = await groupChatProvider.createGroupChat(
          name: _groupNameController.text.trim(),
          characterIds: _selectedCharacterIds.toList(),
          description: _descriptionController.text.trim().isNotEmpty 
              ? _descriptionController.text.trim() 
              : null,
        );
        
        print('🔧 [CharacterSelection] createGroupChat returned: ${newGroup?.id ?? 'null'}');
        
        if (newGroup != null && mounted) {
          print('✅ [CharacterSelection] Group created successfully with ID: ${newGroup.id}');
          print('🔧 [CharacterSelection] Group details:');
          print('🔧 [CharacterSelection] - Name: ${newGroup.name}');
          print('🔧 [CharacterSelection] - Character count: ${newGroup.characterCount}');
          print('🔧 [CharacterSelection] - Created at: ${newGroup.createdAt}');
          
          widget.onGroupCreated?.call(newGroup);
          print('🔧 [CharacterSelection] onGroupCreated callback called');
          Navigator.of(context).pop(newGroup);
          print('🔧 [CharacterSelection] Navigation completed');
        } else {
          print('❌ [CharacterSelection] Group creation returned null or component unmounted');
          print('❌ [CharacterSelection] newGroup: $newGroup, mounted: $mounted');
          setState(() {
            _errorMessage = localizations.groupCreationFailed;
          });
        }
      }
    } catch (e, stackTrace) {
      print('❌ [CharacterSelection] Error during group creation: $e');
      print('❌ [CharacterSelection] Stack trace: $stackTrace');
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isCreatingGroup = false;
      });
      print('🔧 [CharacterSelection] Group creation process completed');
    }
  }
}