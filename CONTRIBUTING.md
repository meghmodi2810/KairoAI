# Contributing to KairoAI

Thank you for contributing to KairoAI! This document provides guidelines for team members working on the project.

## 🚀 Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/meghmodi2810/KairoAI.git
   cd KairoAI
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## 🌿 Branch Naming Convention

Use descriptive branch names following this pattern:

- `feature/feature-name` - For new features
- `bugfix/bug-description` - For bug fixes
- `hotfix/urgent-fix` - For urgent production fixes
- `docs/documentation-update` - For documentation changes

**Examples:**
```bash
git checkout -b feature/profile-page
git checkout -b bugfix/login-validation
git checkout -b docs/api-documentation
```

## 💻 Development Workflow

### 1. Create a New Branch
```bash
git checkout main
git pull origin main
git checkout -b feature/your-feature-name
```

### 2. Make Changes
- Write clean, readable code
- Follow Flutter/Dart style guidelines
- Add comments for complex logic
- Test your changes thoroughly

### 3. Commit Your Changes
```bash
git add .
git commit -m "feat: add user profile page"
```

**Commit Message Format:**
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting)
- `refactor:` - Code refactoring
- `test:` - Adding tests
- `chore:` - Maintenance tasks

### 4. Push to GitHub
```bash
git push origin feature/your-feature-name
```

### 5. Create Pull Request
1. Go to GitHub repository
2. Click "New Pull Request"
3. Select your branch
4. Add description of changes
5. Request review from team members
6. Wait for approval before merging

## 📝 Code Style Guidelines

### Dart/Flutter Conventions
- Use `camelCase` for variables and functions
- Use `PascalCase` for class names
- Keep lines under 80 characters when possible
- Use meaningful variable names
- Add documentation comments for public APIs

### Example:
```dart
/// Validates the user's email address.
/// 
/// Returns null if valid, error message if invalid.
String? validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'Email is required';
  }
  // Validation logic...
  return null;
}
```

## 🧪 Testing

Before pushing your code:

1. **Run the app and test manually**
   ```bash
   flutter run
   ```

2. **Check for errors**
   ```bash
   flutter analyze
   ```

3. **Format your code**
   ```bash
   flutter format .
   ```

## 🔒 Firebase Access

### For Team Members:
- The `google-services.json` file is already included
- Firebase options are configured in `lib/firebase_options.dart`
- **DO NOT** modify these files unless instructed

### Creating Test Users:
See the [README.md](README.md#creating-a-test-user) for detailed instructions.

## 🚫 What NOT to Commit

Never commit these files/folders:
- ❌ `build/` - Build artifacts
- ❌ `.dart_tool/` - Dart tooling files
- ❌ `*.iml`, `.idea/` - IDE files
- ❌ Local configuration files
- ❌ API keys or secrets (if not already in google-services.json)

These are already in `.gitignore`, but be careful not to force-add them.

## 📦 Adding New Dependencies

1. **Add to `pubspec.yaml`**
   ```yaml
   dependencies:
     new_package: ^1.0.0
   ```

2. **Install the package**
   ```bash
   flutter pub get
   ```

3. **Import in your code**
   ```dart
   import 'package:new_package/new_package.dart';
   ```

4. **Commit the changes**
   ```bash
   git add pubspec.yaml pubspec.lock
   git commit -m "chore: add new_package dependency"
   ```

## 🐛 Reporting Issues

When you find a bug:

1. Check if the issue already exists
2. Create a new issue on GitHub with:
   - Clear title
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshots (if applicable)
   - Device/OS information

## 💬 Communication

- Use GitHub Issues for bug reports and feature requests
- Use Pull Request comments for code discussions
- Keep team members updated on your progress

## ⚡ Quick Commands Reference

```bash
# Update your local main branch
git checkout main
git pull origin main

# Create new feature branch
git checkout -b feature/new-feature

# Check status
git status

# Add all changes
git add .

# Commit changes
git commit -m "feat: description"

# Push to GitHub
git push origin feature/new-feature

# Update dependencies
flutter pub get

# Clean build
flutter clean

# Format code
flutter format .

# Analyze code
flutter analyze

# Run app
flutter run
```

## 🎯 Best Practices

1. **Pull before starting work**
   ```bash
   git pull origin main
   ```

2. **Keep commits small and focused**
   - One feature/fix per commit
   - Write clear commit messages

3. **Test before pushing**
   - Run the app
   - Check for errors
   - Test on different screen sizes

4. **Keep your branch updated**
   ```bash
   git checkout main
   git pull origin main
   git checkout feature/your-branch
   git merge main
   ```

5. **Don't commit commented code**
   - Remove or clean up before committing

6. **Use meaningful names**
   - Files, classes, functions should be self-explanatory

## 🆘 Need Help?

- Check the [README.md](README.md)
- Check the [Troubleshooting section](README.md#troubleshooting)
- Ask team members
- Create an issue on GitHub

---

Happy Coding! 🚀
