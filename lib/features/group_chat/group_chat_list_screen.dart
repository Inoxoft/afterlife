import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/utils/ukrainian_font_utils.dart';
import '../../core/widgets/animated_particles.dart';
import '../../l10n/app_localizations.dart';
import 'models/group_chat_model.dart';
import '../providers/group_chat_provider.dart';
import 'character_selection_screen.dart';
import 'group_chat_screen.dart';
import '../providers/characters_provider.dart';

class GroupChatListScreen extends StatefulWidget {
  const GroupChatListScreen({Key? key}) : super(key: key);

  @override
  State<GroupChatListScreen> createState() => _GroupChatListScreenState();
}

class _GroupChatListScreenState extends State<GroupChatListScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // State
  bool _isFirstLoad = true;
  GroupChatModel? _previewSelectedGroup;

  // Cached widgets for performance
  late final Widget _particleBackground = const Opacity(
    opacity: 0.2,
    child: AnimatedParticles(
      particleCount: 20,
      particleColor: AppTheme.warmGold,
      minSpeed: 0.01,
      maxSpeed: 0.03,
    ),
  );

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadGroupChats();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));

    if (_isFirstLoad) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _fadeController.forward();
          _slideController.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupChats() async {
    final provider = Provider.of<GroupChatProvider>(context, listen: false);
    
    try {
      await provider.loadGroupChats();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading group chats: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFirstLoad = false;
          // Initialize preview selection for wide layout
          if (_previewSelectedGroup == null && provider.groupChats.isNotEmpty) {
            _previewSelectedGroup = provider.groupChats.first;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final localizations = AppLocalizations.of(context);
    
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
                  _buildAppBar(localizations),
                  Expanded(child: _buildContent(localizations)),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildCreateGroupFAB(localizations),
    );
  }

  Widget _buildAppBar(AppLocalizations localizations) {
    final fontScale = ResponsiveUtils.getFontSizeScale(context);
    
    return Container(
      padding: ResponsiveUtils.getScreenPadding(context),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.groupChats,
                  style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                    text: localizations.groupChats,
                    fontSize: 24 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.warmGold,
                  ),
                ),
                Consumer<GroupChatProvider>(
                  builder: (context, provider, child) {
                    return Text(
                      '${provider.groupChats.length} ${localizations.groupsCreated}',
                      style: UkrainianFontUtils.latoWithUkrainianSupport(
                        text: '${provider.groupChats.length} ${localizations.groupsCreated}',
                        fontSize: 12 * fontScale,
                        color: AppTheme.silverMist.withValues(alpha: 0.7),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AppLocalizations localizations) {
    return Consumer<GroupChatProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && _isFirstLoad) {
          return _buildLoadingState(localizations);
        }

        if (provider.groupChats.isEmpty) {
          return _buildEmptyState(localizations);
        }

        final size = MediaQuery.of(context).size;
        final isLandscape = size.width > size.height;
        final isTabletOrDesktop = ResponsiveUtils.isTabletOrDesktop(context);
        final useWide = _shouldUseWideLayout(context);

        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: (isTabletOrDesktop && isLandscape)
                ? _buildHorizontalRow(provider, localizations)  // Force horizontal scroll in landscape
                : (useWide 
                    ? _buildWideLayout(provider, localizations)  // Side-by-side only in portrait wide screens
                    : _buildGroupList(provider, localizations)), // Regular list/grid
          ),
        );
      },
    );
  }

  bool _shouldUseWideLayout(BuildContext context) {
    // Only use wide layout for portrait orientation on wide screens
    // Landscape should always use horizontal scroll instead
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    
    // Don't use wide layout in landscape - that's for horizontal scroll
    if (isLandscape) return false;
    
    // Use wide layout for portrait on really wide screens
    final isReallyWide = size.width >= 1000;
    return isReallyWide || (ResponsiveUtils.shouldUseWideLayout(context) && !isLandscape);
  }

  Widget _buildGroupList(
    GroupChatProvider provider,
    AppLocalizations localizations, {
    bool selectForPreview = false,
  }) {
    final gridAxisCount = ResponsiveUtils.getGridAxisCount(context);
    final isTabletOrDesktop = ResponsiveUtils.isTabletOrDesktop(context);
    
    // Note: Landscape is now handled in _buildContent, so this is only for portrait/narrow screens
    if (isTabletOrDesktop) {
      return _buildGridView(provider, localizations, gridAxisCount, selectForPreview: selectForPreview);
    } else {
      return _buildListView(provider, localizations, selectForPreview: selectForPreview);
    }
  }

  Widget _buildListView(
    GroupChatProvider provider,
    AppLocalizations localizations, {
    bool selectForPreview = false,
  }) {
    return RefreshIndicator(
      onRefresh: _loadGroupChats,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: ResponsiveUtils
            .getScreenPadding(context)
            .add(const EdgeInsets.only(bottom: 88)),
        itemCount: provider.groupChats.length,
        itemBuilder: (context, index) {
          final group = provider.groupChats[index];
          final isSelected = selectForPreview && _previewSelectedGroup?.id == group.id;
          return _GroupChatListCard(
            group: group,
            onTap: () => selectForPreview ? _selectPreviewGroup(group) : _openGroupChat(group),
            onEdit: () => _editGroup(group),
            onDelete: () => _deleteGroup(group),
            isSelected: isSelected,
          );
        },
      ),
    );
  }

  Widget _buildGridView(
    GroupChatProvider provider,
    AppLocalizations localizations,
    int gridAxisCount, {
    bool selectForPreview = false,
  }) {
    return RefreshIndicator(
      onRefresh: _loadGroupChats,
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        padding: ResponsiveUtils
            .getScreenPadding(context)
            .add(const EdgeInsets.only(bottom: 88)),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: _getTileMaxWidth(context),
          crossAxisSpacing: ResponsiveUtils.getGridSpacing(context),
          mainAxisSpacing: ResponsiveUtils.getGridSpacing(context),
          childAspectRatio: _getAdjustedAspectRatio(context),
        ),
        itemCount: provider.groupChats.length,
        itemBuilder: (context, index) {
          final group = provider.groupChats[index];
          final isSelected = selectForPreview && _previewSelectedGroup?.id == group.id;
          return _GroupChatGridCard(
            group: group,
            onTap: () => selectForPreview ? _selectPreviewGroup(group) : _openGroupChat(group),
            onEdit: () => _editGroup(group),
            onDelete: () => _deleteGroup(group),
            isSelected: isSelected,
          );
        },
      ),
    );
  }

  double _getAdjustedAspectRatio(BuildContext context) {
    final base = ResponsiveUtils.getGridChildAspectRatio(context);
    final deviceType = ResponsiveUtils.getDeviceType(context);
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    double ratio = base;
    // Make cards taller in tablet/desktop, especially in landscape to show more text
    if (deviceType == DeviceType.tablet) {
      ratio = base - (isLandscape ? 0.25 : 0.15);
    } else if (deviceType == DeviceType.desktop || deviceType == DeviceType.tv) {
      ratio = base - (isLandscape ? 0.2 : 0.1);
    }

    return ratio.clamp(0.5, 2.0);
  }

  double _getTileMaxWidth(BuildContext context) {
    final deviceType = ResponsiveUtils.getDeviceType(context);
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    // Use dynamic tile width to keep 2 columns in wide landscape for readability
    final horizontalPadding = ResponsiveUtils.getScreenPadding(context).horizontal;
    final availableWidth = (size.width - horizontalPadding).clamp(300.0, size.width);

    switch (deviceType) {
      case DeviceType.mobile:
        // 1–2 columns
        return isLandscape ? availableWidth / 2 : 380;
      case DeviceType.tablet:
        // Prefer 2 columns in landscape, 2–3 in portrait
        return isLandscape ? (availableWidth / 2) : 460;
      case DeviceType.desktop:
        // Force 2 columns in landscape so cards are big and text readable
        return isLandscape ? (availableWidth / 2) : 520;
      case DeviceType.tv:
        return isLandscape ? (availableWidth / 2) : 640;
    }
  }

  Widget _buildHorizontalRow(
    GroupChatProvider provider,
    AppLocalizations localizations, {
    bool selectForPreview = false,
  }) {
    final padding = ResponsiveUtils.getScreenPadding(context);
    final size = MediaQuery.of(context).size;

    // Large square-ish cards; adapt by device width
    double cardSide = (size.width * 0.32).clamp(260.0, 520.0);

    return SizedBox(
      height: cardSide + padding.vertical, // ensure single row height
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: padding.left, vertical: padding.top),
        itemBuilder: (context, index) {
          final group = provider.groupChats[index];
          return SizedBox(
            width: cardSide,
            child: _GroupChatGridCard(
              group: group,
              onTap: () => selectForPreview ? _selectPreviewGroup(group) : _openGroupChat(group),
              onEdit: () => _editGroup(group),
              onDelete: () => _deleteGroup(group),
              isSelected: selectForPreview && _previewSelectedGroup?.id == group.id,
            ),
          );
        },
        separatorBuilder: (context, index) => SizedBox(width: ResponsiveUtils.getGridSpacing(context)),
        itemCount: provider.groupChats.length,
      ),
    );
  }

  Widget _buildWideLayout(GroupChatProvider provider, AppLocalizations localizations) {
    final padding = ResponsiveUtils.getScreenPadding(context);
    final fontScale = ResponsiveUtils.getFontSizeScale(context);

    // Ensure preview selection is valid
    _previewSelectedGroup ??= provider.groupChats.isNotEmpty ? provider.groupChats.first : null;

    return Row(
      children: [
        // Left pane: list/grid
        Expanded(
          flex: 5,
          child: Container(
            padding: EdgeInsets.only(left: padding.left, right: padding.left / 2),
            child: _buildGroupList(provider, localizations, selectForPreview: true),
          ),
        ),
        // Right pane: preview
        Expanded(
          flex: 7,
          child: Container(
            padding: EdgeInsets.only(right: padding.right, left: padding.right / 2),
            child: _previewSelectedGroup == null
                ? _buildEmptyPreview(localizations)
                : _buildGroupPreview(_previewSelectedGroup!, fontScale, localizations),
          ),
        ),
      ],
    );
  }

  void _selectPreviewGroup(GroupChatModel group) {
    setState(() {
      _previewSelectedGroup = group;
    });
  }

  Widget _buildEmptyPreview(AppLocalizations localizations) {
    return Center(
      child: Text(
        'Select a group to preview',
        style: UkrainianFontUtils.latoWithUkrainianSupport(
          text: 'Select a group to preview',
          fontSize: 16,
          color: AppTheme.silverMist.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildGroupPreview(
    GroupChatModel group,
    double fontScale,
    AppLocalizations localizations,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.midnightPurple.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.warmGold.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16 * fontScale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.groups, color: AppTheme.warmGold, size: 20 * fontScale),
                SizedBox(width: 8 * fontScale),
                Expanded(
                  child: Text(
                    group.name,
                    style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                      text: group.name,
                      fontSize: 20 * fontScale,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.warmGold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _openGroupChat(group),
                  icon: const Icon(Icons.chat),
                  label: Text(
                    localizations.openChat,
                    style: UkrainianFontUtils.latoWithUkrainianSupport(
                      text: localizations.openChat,
                      fontSize: 12 * fontScale,
                      color: AppTheme.deepNavy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warmGold,
                    foregroundColor: AppTheme.deepNavy,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12 * fontScale),
            // Stats
            Text(
              '${group.characterCount} ${localizations.members} • ${group.messageCount} ${localizations.messages}',
              style: UkrainianFontUtils.latoWithUkrainianSupport(
                text: '${group.characterCount} ${localizations.members} • ${group.messageCount} ${localizations.messages}',
                fontSize: 12 * fontScale,
                color: AppTheme.silverMist.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: 12 * fontScale),
            // Last message
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.deepNavy.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.warmGold.withValues(alpha: 0.2),
                  ),
                ),
                padding: EdgeInsets.all(12 * fontScale),
                child: SingleChildScrollView(
                  child: Text(
                    group.lastMessage?.content ?? 'No messages yet',
                    style: UkrainianFontUtils.latoWithUkrainianSupport(
                      text: group.lastMessage?.content ?? 'No messages yet',
                      fontSize: 14 * fontScale,
                      color: AppTheme.silverMist,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12 * fontScale),
            // Actions
            Row(
              children: [
                _buildActionButton(Icons.edit, localizations.editGroup, () => _editGroup(group), fontScale),
                SizedBox(width: 8 * fontScale),
                _buildActionButton(Icons.delete_outline, localizations.delete, () => _deleteGroup(group), fontScale, isDestructive: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
    double fontScale, {
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDestructive 
            ? AppTheme.errorColor.withValues(alpha: 0.1)
            : AppTheme.warmGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDestructive 
              ? AppTheme.errorColor.withValues(alpha: 0.3)
              : AppTheme.warmGold.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 18 * fontScale,
          color: isDestructive ? AppTheme.errorColor : AppTheme.warmGold,
        ),
        tooltip: tooltip,
        constraints: BoxConstraints(
          minWidth: math.max(44.0, 36 * fontScale),
          minHeight: math.max(44.0, 36 * fontScale),
        ),
      ),
    );
  }

  Widget _buildLoadingState(AppLocalizations localizations) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.warmGold,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading group chats...',
            style: UkrainianFontUtils.latoWithUkrainianSupport(
              text: 'Loading group chats...',
              fontSize: 16,
              color: AppTheme.silverMist.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations localizations) {
    final fontScale = ResponsiveUtils.getFontSizeScale(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Group chat icon
            Container(
              width: 120 * fontScale,
              height: 120 * fontScale,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.warmGold.withValues(alpha: 0.3),
                    AppTheme.warmGold.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.warmGold.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.groups,
                size: 60 * fontScale,
                color: AppTheme.warmGold,
              ),
            ),
            
            const SizedBox(height: 32),
            
            Text(
              localizations.noGroupChats,
              style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                text: localizations.noGroupChats,
                fontSize: 28 * fontScale,
                fontWeight: FontWeight.bold,
                color: AppTheme.warmGold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              localizations.createFirstGroupChat,
              style: UkrainianFontUtils.latoWithUkrainianSupport(
                text: localizations.createFirstGroupChat,
                fontSize: 16 * fontScale,
                color: AppTheme.silverMist.withValues(alpha: 0.8),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 40),
            
            // Create group button
            ElevatedButton.icon(
              onPressed: _createNewGroup,
              icon: Icon(
                Icons.add,
                size: 20 * fontScale,
              ),
              label: Text(
                localizations.createGroupChat,
                style: UkrainianFontUtils.latoWithUkrainianSupport(
                  text: localizations.createGroupChat,
                  fontSize: 16 * fontScale,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.deepNavy,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warmGold,
                foregroundColor: AppTheme.deepNavy,
                padding: EdgeInsets.symmetric(
                  horizontal: 32 * fontScale,
                  vertical: 16 * fontScale,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 8,
                shadowColor: AppTheme.warmGold.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateGroupFAB(AppLocalizations localizations) {
    return Consumer<GroupChatProvider>(
      builder: (context, provider, child) {
        if (provider.groupChats.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return FloatingActionButton.extended(
          onPressed: _createNewGroup,
          backgroundColor: AppTheme.warmGold,
          foregroundColor: AppTheme.deepNavy,
          elevation: 8,
          icon: const Icon(Icons.add),
          label: Text(
            localizations.createGroupChat,
            style: UkrainianFontUtils.latoWithUkrainianSupport(
              text: localizations.createGroupChat,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.deepNavy,
            ),
          ),
        );
      },
    );
  }

  void _openGroupChat(GroupChatModel group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupChatScreen(groupId: group.id),
      ),
    ).then((_) {
      // Refresh the list when returning from chat
      _loadGroupChats();
    });
  }

  void _editGroup(GroupChatModel group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CharacterSelectionScreen(existingGroup: group),
      ),
    ).then((result) {
      if (result != null) {
        _loadGroupChats();
      }
    });
  }

  void _deleteGroup(GroupChatModel group) {
    showDialog(
      context: context,
      builder: (context) => _DeleteGroupDialog(
        group: group,
        onConfirm: () async {
          final provider = Provider.of<GroupChatProvider>(context, listen: false);
          try {
            await provider.deleteGroupChat(group.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Group "${group.name}" deleted'),
                  backgroundColor: AppTheme.warmGold,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error deleting group: $e'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _createNewGroup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CharacterSelectionScreen(),
      ),
    ).then((result) {
      if (result != null) {
        _loadGroupChats();
      }
    });
  }
}

/// List card for group chats in mobile view
class _GroupChatListCard extends StatelessWidget {
  final GroupChatModel group;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isSelected;

  const _GroupChatListCard({
    required this.group,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final fontScale = ResponsiveUtils.getFontSizeScale(context);
    final localizations = AppLocalizations.of(context);
    
    return Container(
      margin: EdgeInsets.only(bottom: 16 * fontScale),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.midnightPurple.withValues(alpha: 0.5)
            : AppTheme.midnightPurple.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppTheme.warmGold.withValues(alpha: 0.6)
              : AppTheme.warmGold.withValues(alpha: 0.3),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepNavy.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16 * fontScale),
            child: Row(
              children: [
                // Group avatar
                _buildGroupAvatar(fontScale),
                
                SizedBox(width: 16 * fontScale),
                
                // Group info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Group name
                      Text(
                        group.name,
                        style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                          text: group.name,
                          fontSize: 18 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.warmGold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      SizedBox(height: 4 * fontScale),
                      
                      // Group stats
                      Text(
                        '${group.characterCount} ${localizations.members} • ${group.messageCount} ${localizations.messages}',
                        style: UkrainianFontUtils.latoWithUkrainianSupport(
                          text: '${group.characterCount} ${localizations.members} • ${group.messageCount} ${localizations.messages}',
                          fontSize: 12 * fontScale,
                          color: AppTheme.silverMist.withValues(alpha: 0.7),
                        ),
                      ),
                      
                      SizedBox(height: 8 * fontScale),
                      
                      // Last message preview
                      if (group.lastMessage != null)
                        Text(
                          group.lastMessage!.content,
                          style: UkrainianFontUtils.latoWithUkrainianSupport(
                            text: group.lastMessage!.content,
                            fontSize: 14 * fontScale,
                            color: AppTheme.silverMist.withValues(alpha: 0.8),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      
                      SizedBox(height: 8 * fontScale),
                      
                      // Last active time
                      Text(
                        _formatLastActive(group.lastMessageAt),
                        style: UkrainianFontUtils.latoWithUkrainianSupport(
                          text: _formatLastActive(group.lastMessageAt),
                          fontSize: 11 * fontScale,
                          color: AppTheme.silverMist.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Action buttons
                Column(
                  children: [
                    _buildActionButton(
                      Icons.chat,
                      localizations.openChat,
                      onTap,
                      fontScale,
                    ),
                    SizedBox(height: 8 * fontScale),
                    _buildActionButton(
                      Icons.edit,
                      localizations.editGroup,
                      onEdit,
                      fontScale,
                    ),
                    SizedBox(height: 8 * fontScale),
                    _buildActionButton(
                      Icons.delete_outline,
                      localizations.delete,
                      onDelete,
                      fontScale,
                      isDestructive: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupAvatar(double fontScale) {
    final avatarSize = 60.0 * fontScale;
    
    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.warmGold.withValues(alpha: 0.3),
            AppTheme.warmGold.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(avatarSize / 2),
        border: Border.all(
          color: AppTheme.warmGold.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Icon(
        Icons.groups,
        size: 30 * fontScale,
        color: AppTheme.warmGold,
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
    double fontScale, {
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDestructive 
            ? AppTheme.errorColor.withValues(alpha: 0.1)
            : AppTheme.warmGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDestructive 
              ? AppTheme.errorColor.withValues(alpha: 0.3)
              : AppTheme.warmGold.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 18 * fontScale,
          color: isDestructive ? AppTheme.errorColor : AppTheme.warmGold,
        ),
        tooltip: tooltip,
        constraints: BoxConstraints(
          minWidth: math.max(44.0, 36 * fontScale),
          minHeight: math.max(44.0, 36 * fontScale),
        ),
      ),
    );
  }

  String _formatLastActive(DateTime lastMessageAt) {
    final now = DateTime.now();
    final difference = now.difference(lastMessageAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// Grid card for group chats in tablet/desktop view
class _GroupChatGridCard extends StatelessWidget {
  final GroupChatModel group;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isSelected;

  const _GroupChatGridCard({
    required this.group,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final fontScale = ResponsiveUtils.getFontSizeScale(context);
    final localizations = AppLocalizations.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.midnightPurple.withValues(alpha: 0.5)
            : AppTheme.midnightPurple.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppTheme.warmGold.withValues(alpha: 0.6)
              : AppTheme.warmGold.withValues(alpha: 0.3),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepNavy.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16 * fontScale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with avatar and actions
                Row(
                  children: [
                    _buildGroupAvatar(fontScale),
                    const Spacer(),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            onEdit();
                            break;
                          case 'delete':
                            onDelete();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16 * fontScale),
                              SizedBox(width: 8 * fontScale),
                              Text(localizations.editGroup),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, 
                                   size: 16 * fontScale, 
                                   color: AppTheme.errorColor),
                              SizedBox(width: 8 * fontScale),
                              Text(localizations.delete, 
                                   style: TextStyle(color: AppTheme.errorColor)),
                            ],
                          ),
                        ),
                      ],
                      icon: Icon(
                        Icons.more_vert,
                        color: AppTheme.warmGold,
                        size: 20 * fontScale,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 12 * fontScale),
                
                // Group name
                Text(
                  group.name,
                  style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                    text: group.name,
                    fontSize: 16 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.warmGold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: 6 * fontScale),
                
                // Group stats
                Text(
                  '${group.characterCount} ${localizations.members}',
                  style: UkrainianFontUtils.latoWithUkrainianSupport(
                    text: '${group.characterCount} ${localizations.members}',
                    fontSize: 11 * fontScale,
                    color: AppTheme.silverMist.withValues(alpha: 0.7),
                  ),
                ),
                
                const Spacer(),
                
                // Last message preview
                if (group.lastMessage != null) ...[
                  Text(
                    group.lastMessage!.content,
                    style: UkrainianFontUtils.latoWithUkrainianSupport(
                      text: group.lastMessage!.content,
                      fontSize: 12 * fontScale,
                      color: AppTheme.silverMist.withValues(alpha: 0.8),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8 * fontScale),
                ],
                
                // Last active
                Text(
                  _formatLastActive(group.lastMessageAt),
                  style: UkrainianFontUtils.latoWithUkrainianSupport(
                    text: _formatLastActive(group.lastMessageAt),
                    fontSize: 10 * fontScale,
                    color: AppTheme.silverMist.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupAvatar(double fontScale) {
    final avatarSize = 40.0 * fontScale;
    
    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.warmGold.withValues(alpha: 0.3),
            AppTheme.warmGold.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(avatarSize / 2),
        border: Border.all(
          color: AppTheme.warmGold.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Icon(
        Icons.groups,
        size: 20 * fontScale,
        color: AppTheme.warmGold,
      ),
    );
  }

  String _formatLastActive(DateTime lastMessageAt) {
    final now = DateTime.now();
    final difference = now.difference(lastMessageAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// Delete confirmation dialog
class _DeleteGroupDialog extends StatelessWidget {
  final GroupChatModel group;
  final VoidCallback onConfirm;

  const _DeleteGroupDialog({
    required this.group,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final fontScale = ResponsiveUtils.getFontSizeScale(context);
    final localizations = AppLocalizations.of(context);
    
    return AlertDialog(
      backgroundColor: AppTheme.deepNavy,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.warmGold.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      title: Text(
        'Delete Group Chat',
        style: UkrainianFontUtils.cinzelWithUkrainianSupport(
          text: 'Delete Group Chat',
          fontSize: 20 * fontScale,
          fontWeight: FontWeight.bold,
          color: AppTheme.warmGold,
        ),
      ),
      content: Text(
        'Are you sure you want to delete "${group.name}"? This action cannot be undone.',
        style: UkrainianFontUtils.latoWithUkrainianSupport(
          text: 'Are you sure you want to delete "${group.name}"? This action cannot be undone.',
          fontSize: 14 * fontScale,
          color: AppTheme.silverMist,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            localizations.cancel,
            style: UkrainianFontUtils.latoWithUkrainianSupport(
              text: localizations.cancel,
              fontSize: 14 * fontScale,
              color: AppTheme.silverMist,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.errorColor,
            foregroundColor: Colors.white,
          ),
          child: Text(
            localizations.delete,
            style: UkrainianFontUtils.latoWithUkrainianSupport(
              text: localizations.delete,
              fontSize: 14 * fontScale,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}