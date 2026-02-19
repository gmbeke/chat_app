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

class _HomeViewState extends State<HomeView> {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  final PresenceService _presenceService = PresenceService();
  final _searchCtrl = TextEditingController();
  UserModel? _me;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _presenceService.startTracking();
    _loadMe();
  }
 
  Future<void> _loadMe() async {
    final user = _authService.currentUser;
    if (user != null) {
      await _authService.ensureUserExists(); // Ensure Firestore entry exists
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

    if (user != null) {
      if (!mounted) return;
      if (user.uid == _me?.uid) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("That's your own ID!")));
        return;
      }
      _openChat(user);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User not found")));
    }
  }

  void _openChat(UserModel other) {
    if (_me == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatView(me: _me!, other: other),
      ),
    );
  }

  void _openProfile() async {
    if (_me == null) return;
    final updated = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ProfileView(user: _me!)));
    if (updated == true) {
      _loadMe();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Connecta',
          style: TextStyle(fontWeight: FontWeight.bold),
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
      body: Column(
        children: [
          if (_me != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 0,
                color: Colors.blue[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        child: Text(
                          (_me!.displayName.isNotEmpty)
                              ? _me!.displayName[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _me!.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'My ID: ${_me!.identificationNumber}',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Enter User ID to Chat...',
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _searchUser,
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              textCapitalization: TextCapitalization.characters,
              onSubmitted: (_) => _searchUser(),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Suggested Users',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _chatService.getUsers(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Error: ${snapshot.error}\n\nPlease ensure your Firestore database is created in the Firebase Console.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final users =
                    snapshot.data?.where((u) => u.uid != _me?.uid).toList() ??
                    [];
                if (users.isEmpty) {
                  return const Center(child: Text('No other users yet, asky user to give you his user Id.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final other = users[index];
                    return StreamBuilder<bool>(
                      stream: _presenceService.isUserOnline(other.uid),
                      builder: (context, onlineSnap) {
                        final isOnline = onlineSnap.data ?? other.isOnline;
                        return ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                backgroundImage: other.photoUrl != null
                                    ? NetworkImage(other.photoUrl!)
                                    : null,
                                child: other.photoUrl == null
                                    ? Text(
                                        (other.displayName.isNotEmpty)
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
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text('ID: ${other.identificationNumber}'),
                          onTap: () => _openChat(other),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _presenceService.stopTracking();
    super.dispose();
  }
}
