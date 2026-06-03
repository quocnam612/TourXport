import 'package:flutter/material.dart';

import 'legal_scaffold.dart';

class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  static const List<_TeamMember> _members = [
    _TeamMember(
      id: '24120238',
      name: 'Phạm Anh Tuấn',
      roleVi: 'Lập trình viên Frontend\nQuản lý dự án',
      roleEn: 'Frontend developer\nProject Manager',
    ),
    _TeamMember(
      id: '24120289',
      name: 'Nguyễn Anh Đức',
      roleVi: 'Lập trình viên Frontend',
      roleEn: 'Frontend developer',
    ),
    _TeamMember(
      id: '24120098',
      name: 'Nguyễn Quốc Nam',
      roleVi: 'Lập trình viên Backend\nKỹ sư DevOps',
      roleEn: 'Backend developer\nDevOps Engineer',
    ),
    _TeamMember(
      id: '24120244',
      name: 'Phan Văn Việt',
      roleVi: 'Lập trình viên Backend',
      roleEn: 'Backend developer',
    ),
    _TeamMember(
      id: '24120076',
      name: 'Nguyễn Đức Anh Khôi',
      roleVi: 'Lập trình viên AI',
      roleEn: 'AI developer',
    ),
    _TeamMember(
      id: '24120336',
      name: 'Võ Minh Khang',
      roleVi: 'Lập trình viên AI',
      roleEn: 'AI developer',
    ),
    _TeamMember(
      id: '24120224',
      name: 'Nguyễn Anh Thái',
      roleVi: 'Kỹ sư dữ liệu',
      roleEn: 'Data Engineer',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isVi = Localizations.localeOf(context).languageCode == 'vi';

    return LegalScaffold(
      title: isVi ? 'Liên Hệ Hỗ Trợ' : 'Contact Support',
      subtitle: isVi
          ? 'Danh sách thành viên phụ trách hỗ trợ và phát triển TourXport.'
          : 'Team members responsible for supporting and developing TourXport.',
      activeRoute: '/contact',
      children: [
        LegalNotice(
          icon: Icons.contact_support_rounded,
          title: isVi ? 'Thông tin liên hệ hỗ trợ' : 'Support contacts',
          body: isVi
              ? 'Bạn có thể liên hệ thành viên phù hợp theo vai trò bên dưới. Email được tạo theo định dạng MSSV@student.hcmus.edu.vn.'
              : 'You can contact the relevant member by role below. Email addresses follow the MSSV@student.hcmus.edu.vn format.',
        ),
        _TeamTable(members: _members, isVi: isVi),
      ],
    );
  }
}

class _TeamTable extends StatelessWidget {
  final List<_TeamMember> members;
  final bool isVi;

  const _TeamTable({
    required this.members,
    required this.isVi,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isVi ? 'Thành viên' : 'Team members',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            for (final member in members) ...[
              _TeamMemberCard(member: member, isVi: isVi),
              if (member != members.last)
                Divider(color: Colors.white.withOpacity(0.10), height: 18),
            ],
          ],
        ),
      ),
    );
  }
}

class _TeamMemberCard extends StatelessWidget {
  final _TeamMember member;
  final bool isVi;

  const _TeamMemberCard({
    required this.member,
    required this.isVi,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;
          final content = [
            _InfoBlock(label: isVi ? 'Họ và tên' : 'Full name', value: member.name),
            _InfoBlock(label: isVi ? 'Vai trò' : 'Role', value: isVi ? member.roleVi : member.roleEn),
            _InfoBlock(label: 'Email', value: member.email),
          ];

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: content,
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: content[0]),
              const SizedBox(width: 18),
              Expanded(flex: 2, child: content[1]),
              const SizedBox(width: 18),
              Expanded(flex: 3, child: content[2]),
            ],
          );
        },
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String label;
  final String value;

  const _InfoBlock({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: const Color(0xFFD4AF7A).withOpacity(0.86),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: Colors.white.withOpacity(0.80),
              fontSize: 15,
              height: 1.42,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamMember {
  final String id;
  final String name;
  final String roleVi;
  final String roleEn;

  const _TeamMember({
    required this.id,
    required this.name,
    required this.roleVi,
    required this.roleEn,
  });

  String get email => '$id@student.hcmus.edu.vn';
}
