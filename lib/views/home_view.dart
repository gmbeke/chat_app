import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/presence_service.dart';
import '../widgets/online_indicator.dart';
import 'chat_view.dart';
import 'profile_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  final PresenceService _presenceService = PresenceService();
  final _searchCtrl = TextEditingController();

  UserModel? _me;
  bool _isSearching = false;

  late final AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _presenceService.startTracking();
    _loadMe();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  Future<void> _loadMe() async {
    final user = _authService.currentUser;
    if (user != null) {
      await _authService.ensureUserExists();
      final me = await _chatService.getUserByUid(user.uid);
      if (mounted) {
        setState(() => _me = me);
      }
    }
  }

  Future<void> _searchUser() async {
    final id = _searchCtrl.text.trim().toUpperCase();
    if (id.isEmpty) return;

    setState(() => _isSearching = true);
    final user = await _chatService.getUserByIdentification(id);
    setState(() => _isSearching = false);

    if (!mounted) return;

    if (user == null) {
      _showSnack('User not found');
      return;
    }

    if (user.uid == _me?.uid) {
      _showSnack("That's your own ID!");
      return;
    }

    _openChat(user);
  }

  void _openChat(UserModel other) {
    if (_me == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatView(me: _me!, other: other)),
    );
  }

  void _openProfile() async {
    if (_me == null) return;
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileView(user: _me!)),
    );
    if (updated == true) _loadMe();
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Group 12 Chat App',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: _openProfile,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _authService.signOut(),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeCtrl,
        child: Column(
          children: [
            if (_me != null) _buildMyCard(theme),
            _buildSearchField(),
            const SizedBox(height: 12),
            _buildSectionTitle(),
            Expanded(child: _buildUsersList()),
          ],
        ),
      ),
    );
  }

  Widget _buildMyCard(ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor, theme.primaryColorDark],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.15),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white,
            child: Text(
              _me!.displayName.isNotEmpty
                  ? _me!.displayName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: 22,
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _me!.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${_me!.identificationNumber}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchCtrl,
        textCapitalization: TextCapitalization.characters,
        onSubmitted: (_) => _searchUser(),
        decoration: InputDecoration(
          hintText: 'Enter User ID...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: _searchUser,
                  ),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Suggested Users',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    return StreamBuilder<List<UserModel>>(
      stream: _chatService.getUsers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users =
            snapshot.data!.where((u) => u.uid != _me?.uid).toList();

        if (users.isEmpty) {
          return const Center(child: Text('No other users available'));
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final other = users[index];

            return StreamBuilder<bool>(
              stream: _presenceService.isUserOnline(other.uid),
              builder: (context, snap) {
                final isOnline = snap.data ?? other.isOnline;

                return AnimatedScale(
                  duration: const Duration(milliseconds: 250),
                  scale: 1,
                  child: ListTile(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          backgroundImage: other.photoUrl != null
                              ? NetworkImage(other.photoUrl!)
                              : null,
                          child: other.photoUrl == null
                              ? Text(
                                  other.displayName.isNotEmpty
                                      ? other.displayName[0].toUpperCase()
                                      : '?',
                                )
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: OnlineIndicator(isOnline: isOnline),
                        ),
                      ],
                    ),
                    title: Text(
                      other.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('ID: ${other.identificationNumber}'),
                    onTap: () => _openChat(other),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _presenceService.stopTracking();
    _fadeCtrl.dispose();
    super.dispose();
  }
}
