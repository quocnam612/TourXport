import 'package:flutter/material.dart';

class SavedAccountsDropdown extends StatelessWidget {
  final List<Map<String, String>> savedAccounts;
  final Function(Map<String, String>) onSelectAccount;
  final Function(String) onRemoveAccount;
  final double s;

  const SavedAccountsDropdown({
    super.key,
    required this.savedAccounts,
    required this.onSelectAccount,
    required this.onRemoveAccount,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    if (savedAccounts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8 * s),
        SizedBox(
          height: 40 * s,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: savedAccounts.length,
            separatorBuilder: (_, __) => SizedBox(width: 8 * s),
            itemBuilder: (context, index) {
              final acc = savedAccounts[index];
              return GestureDetector(
                onTap: () => onSelectAccount(acc),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 6 * s),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20 * s),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 12 * s,
                        backgroundColor: Colors.white24,
                        backgroundImage: acc['avatar'] != null && acc['avatar']!.isNotEmpty
                            ? NetworkImage(acc['avatar']!)
                            : null,
                        child: acc['avatar'] == null || acc['avatar']!.isEmpty
                            ? Icon(Icons.person, size: 16 * s, color: Colors.white)
                            : null,
                      ),
                      SizedBox(width: 8 * s),
                      Text(
                        acc['name'] ?? acc['email']!,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12 * s,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 6 * s),
                      GestureDetector(
                        onTap: () => onRemoveAccount(acc['email']!),
                        child: Container(
                          padding: EdgeInsets.all(2 * s),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                          child: Icon(Icons.close, size: 12 * s, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
