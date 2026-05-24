# Changelog

## [1.0.0] - 2026-05-24

### Added
- **Guest Mode Support**: Added initial support for unregistered (guest) users, allowing them to browse the application without immediately signing in.
- **Personalized Header in Landing Page**: Displays a greeting (`XIN CHÀO, <USER>!`) and a quick-access `"VÀO TRANG CHỦ"` (Go to Home) button for authenticated users in the desktop header.
- **Login Call-to-Action Card**: Created a sleek, glassmorphic CTA card on the Profile tab prompting guest users to log in or sign up to save places and access personalized AI planning.

### Changed
- **Navigation Flow Redirection**: Reordered the app entry sequence to follow `HomeScreen (Guest)` -> `Login / Signup` -> `Landing Page (Registered)` -> `HomeScreen (Registered)`.
- **Successful Authentication Callback**: Pushes users to the updated `LandingPage` instead of directly launching the homepage dashboard after logging in or signing up.
- **Sidebar Integration**: Replaced the red `"Đăng xuất"` (Log Out) drawer item with a gold-highlighted `"Tài khoản"` button for guest mode.
- **Profile Tab Customizations**: 
  - Hides personal/authenticated sections ("Thông tin cá nhân", "Email", "Số điện thoại", "Thông báo", "Bảo mật") for guest users to prevent cluttered disabled actions.
  - Replaces the red `"Đăng xuất"` menu option at the bottom with a gold `"Đăng nhập / Đăng ký"` redirect button.
  - Hides visual avatar edit badges for guests.
- **Saved Tab Customizations**: Updated the description and layout of the saved tab to show a localized sign-in prompt for guest users.

### Removed
- **Unused Buttons**: Removed the default `"ĐĂNG NHẬP"` and `"ĐĂNG KÝ"` buttons from the web/desktop navbar for users who are already authenticated.

### Fixed
- **Saved Tab Compilation Issue**: Fixed a Flutter compilation error in `saved_place.dart` where `widget.authToken` was queried inside a `StatelessWidget` (which has no `widget` property). Resolved by passing down an explicit `isGuest` property from `dashboard.dart`.
