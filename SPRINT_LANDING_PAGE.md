# Sprint: Landing Page Redesign - API Key Input

## Sprint Overview
**Branch**: `claude/landing-page-api-key-p9ghO`
**Goal**: Redesign the landing page to be clean and minimal with just an API key input box and voip.json lottie animation in the background.

## Objectives
- Simplify the landing page to focus solely on API key configuration
- Create an elegant, minimal UI with the existing liquid glass design system
- Integrate voip.json lottie animation as an ambient background effect
- Streamline the user onboarding experience

## Current State Analysis
### Existing Components
- **HomeScreen** (`lib/src/screens/home_screen.dart`): Shows API status, configuration details, and action buttons
- **SettingsScreen** (`lib/src/screens/settings_screen.dart`): Full configuration with Base URL and API Key inputs
- **ConfigService** (`lib/src/config/config_service.dart`): Manages API configuration and secure storage
- **Design System**: Liquid glass aesthetic with defined tokens in `design_tokens.dart`
- **Background System**: Sophisticated bloom/band gradients with weather effects

### Gap Analysis
- ❌ No voip.json lottie file exists
- ❌ Landing page is cluttered with status cards and multiple buttons
- ❌ API key input is on a separate settings screen
- ✅ Glass aesthetic design system is ready
- ✅ Lottie integration already implemented
- ✅ Configuration storage working

---

## Sprint Backlog

### Task 1: Create/Add voip.json Lottie Animation
**Priority**: High
**Story Points**: 2

**Description**:
Add the voip.json lottie animation file to the project assets.

**Acceptance Criteria**:
- [ ] voip.json file placed in `assets/lottie/voip.json`
- [ ] File is referenced in `pubspec.yaml` under assets
- [ ] Animation loads without errors
- [ ] Animation is optimized for performance (< 200KB recommended)

**Technical Notes**:
- If voip.json is not provided, source a VoIP/communication-themed lottie from lottiefiles.com
- Test animation rendering with `Lottie.asset('assets/lottie/voip.json')`

---

### Task 2: Design Simplified Landing Page Layout
**Priority**: High
**Story Points**: 3

**Description**:
Design the new minimal landing page layout with focus on API key input.

**UI Specifications**:

```
┌─────────────────────────────────────────┐
│                                         │
│         [voip.json animation]           │
│         (full screen background)        │
│                                         │
│     ╔═════════════════════════════╗     │
│     ║                             ║     │
│     ║   🔌 Cisco Frontend         ║     │
│     ║                             ║     │
│     ║   ┌─────────────────────┐   ║     │
│     ║   │ Enter API Key       │   ║     │
│     ║   │ ******************  │   ║     │
│     ║   └─────────────────────┘   ║     │
│     ║                             ║     │
│     ║   [ ] Remember API Key      ║     │
│     ║                             ║     │
│     ║      [  Continue  ]         ║     │
│     ║                             ║     │
│     ╚═════════════════════════════╝     │
│                                         │
└─────────────────────────────────────────┘
```

**Design Tokens to Use**:
- Container: `GlassCard` with standard frost
- Input Field: `DesignTokens.inputBorderRadius` (15px)
- Button: `DesignTokens.buttonBorderRadius` (16px)
- Colors: `DesignTokens.textPrimary`, `DesignTokens.accentPrimary`
- Spacing: Consistent padding using existing tokens

**Acceptance Criteria**:
- [ ] Layout is centered and responsive across mobile/tablet/desktop
- [ ] Glass card container uses zero-fill aesthetic
- [ ] Animation plays continuously in background
- [ ] All elements follow liquid glass design language
- [ ] No Base URL field (can be configured later in settings)

---

### Task 3: Create New Landing Page Component
**Priority**: High
**Story Points**: 5

**Description**:
Refactor `home_screen.dart` to implement the new simplified landing page.

**Implementation Plan**:

**File**: `lib/src/screens/home_screen.dart`

```dart
class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiKeyController = TextEditingController();
  bool _rememberKey = false;
  bool _obscureText = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      // Background with voip.json animation
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400),
              child: GlassCard(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // App branding
                      Icon(...),
                      Text('Cisco Frontend'),
                      SizedBox(height: 32),

                      // API Key input
                      TextField(
                        controller: _apiKeyController,
                        obscureText: _obscureText,
                        decoration: InputDecoration(
                          labelText: 'API Key',
                          suffixIcon: IconButton(
                            icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscureText = !_obscureText),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Remember checkbox
                      CheckboxListTile(
                        title: Text('Remember API Key'),
                        value: _rememberKey,
                        onChanged: (value) => setState(() => _rememberKey = value ?? false),
                      ),
                      SizedBox(height: 24),

                      // Continue button
                      ElevatedButton(
                        onPressed: _handleContinue,
                        child: _isLoading
                          ? CircularProgressIndicator()
                          : Text('Continue'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleContinue() async {
    // Validate and save API key
    // Navigate to main app screen or wizard
  }
}
```

**Acceptance Criteria**:
- [ ] Component renders with voip.json background
- [ ] API key input field with show/hide toggle
- [ ] Remember checkbox functional
- [ ] Continue button triggers validation
- [ ] Loading state shown during API key verification
- [ ] Navigation works after successful configuration
- [ ] Follows existing code patterns and style

---

### Task 4: Integrate voip.json Background Animation
**Priority**: High
**Story Points**: 3

**Description**:
Integrate the voip.json lottie animation as a full-screen background effect.

**Implementation Options**:

**Option A: Extend WeatherEffect System**
Modify `lib/src/ui/weather_effect.dart` to support voip animation:

```dart
enum Season {
  winter,
  spring,
  summer,
  fall,
  voip, // New option
}

class WeatherEffect extends StatelessWidget {
  // Add voip case
  String? get _lottieAsset {
    switch (season) {
      case Season.voip:
        return 'assets/lottie/voip.json';
      // ... existing cases
    }
  }
}
```

**Option B: Direct Background Layer**
Add lottie directly to GlassScaffold or create custom background widget:

```dart
Stack(
  children: [
    // Background gradient
    BackgroundRenderer(preset: currentPreset),

    // Voip animation
    Positioned.fill(
      child: Lottie.asset(
        'assets/lottie/voip.json',
        fit: BoxFit.cover,
        opacity: AlwaysStoppedAnimation(0.3), // Subtle effect
      ),
    ),

    // Content
    child,
  ],
)
```

**Acceptance Criteria**:
- [ ] voip.json animation plays continuously
- [ ] Animation is subtle and doesn't distract from UI
- [ ] Animation performance is smooth (60fps)
- [ ] Works with existing background system
- [ ] Opacity can be controlled

---

### Task 5: API Key Validation & Configuration Logic
**Priority**: High
**Story Points**: 3

**Description**:
Implement validation and storage logic for the API key input.

**Implementation**:

```dart
void _handleContinue() async {
  final apiKey = _apiKeyController.text.trim();

  // Validation
  if (apiKey.isEmpty) {
    _showError('Please enter an API key');
    return;
  }

  setState(() => _isLoading = true);

  try {
    // Save to ConfigService
    final configService = context.read<ConfigService>();
    await configService.updateApiKey(apiKey, _rememberKey);

    // Optional: Test connection
    // final apiService = context.read<ApiService>();
    // final isValid = await apiService.testConnection();

    // Navigate to main app
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainAppScreen()),
      );
    }
  } catch (e) {
    _showError('Failed to configure API key: $e');
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

void _showError(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
```

**Acceptance Criteria**:
- [ ] Empty API key shows validation error
- [ ] API key is saved to ConfigService
- [ ] Remember option persists to secure storage
- [ ] Loading state prevents multiple submissions
- [ ] Error messages are user-friendly
- [ ] Success leads to navigation

---

### Task 6: Update Routing
**Priority**: Medium
**Story Points**: 2

**Description**:
Update app routing to show new landing page as entry point.

**Implementation**:

**File**: `lib/main.dart`

```dart
class CiscoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ...
      home: Consumer<ConfigService>(
        builder: (context, config, _) {
          // Show landing page if no API key
          if (config.apiKey == null || config.apiKey!.isEmpty) {
            return HomeScreen(); // New simplified landing page
          }
          // Show main app if configured
          return CollectionWizardScreen(); // or MainAppScreen
        },
      ),
    );
  }
}
```

**Acceptance Criteria**:
- [ ] App launches with landing page if not configured
- [ ] App launches with main screen if already configured
- [ ] Navigation flow is intuitive
- [ ] Back button handling is proper
- [ ] Deep links still work (if applicable)

---

### Task 7: Apply Glass Aesthetic Styling
**Priority**: Medium
**Story Points**: 2

**Description**:
Ensure all new components follow the liquid glass design language.

**Styling Checklist**:
- [ ] Input fields use transparent background with border-only approach
- [ ] Focus states use 70% opacity borders
- [ ] Glass card has zero-fill (transparent, not tinted)
- [ ] Proper backdrop blur applied
- [ ] Dual-stroke rim (40% outer + 15% inner opacity)
- [ ] Border radius matches design tokens
- [ ] No grey slabs or solid backgrounds
- [ ] Text uses proper opacity levels
- [ ] Accent color for interactive elements

**Reference**: `lib/src/ui/design_tokens.dart` (FE-UI-059)

---

### Task 8: Testing
**Priority**: High
**Story Points**: 3

**Description**:
Comprehensive testing of the new landing page.

**Test Scenarios**:

**Functional Tests**:
- [ ] API key input accepts text
- [ ] Show/hide toggle works
- [ ] Remember checkbox toggles state
- [ ] Empty API key shows validation error
- [ ] Valid API key saves to ConfigService
- [ ] Remember option persists across restarts
- [ ] Continue button navigates to next screen
- [ ] Loading state prevents double-submission

**UI/UX Tests**:
- [ ] Animation loads and plays smoothly
- [ ] Layout is responsive on mobile (< 600px)
- [ ] Layout is responsive on tablet (600-900px)
- [ ] Layout is responsive on desktop (> 900px)
- [ ] Glass effect renders correctly
- [ ] Text is readable against background
- [ ] Focus states are visible
- [ ] Touch targets are adequate (min 44x44)

**Integration Tests**:
- [ ] ConfigService integration works
- [ ] Navigation flow is correct
- [ ] App restart loads correct screen
- [ ] Secure storage works on all platforms

**Performance Tests**:
- [ ] Lottie animation maintains 60fps
- [ ] No memory leaks
- [ ] App launch time < 2s
- [ ] Smooth transitions

---

## Definition of Done
- [ ] All 8 tasks completed
- [ ] Code review passed
- [ ] All acceptance criteria met
- [ ] All tests passing
- [ ] No console errors or warnings
- [ ] Performance benchmarks met
- [ ] Documentation updated
- [ ] Screenshots added for reference
- [ ] Committed and pushed to `claude/landing-page-api-key-p9ghO`

---

## Technical Dependencies
- Flutter SDK (version in pubspec.yaml)
- lottie: ^3.1.3 (already in dependencies)
- flutter_secure_storage: ^9.2.2 (already in dependencies)
- provider: ^6.1.2 (already in dependencies)

---

## Assets Required
- `assets/lottie/voip.json` - VoIP themed lottie animation file

---

## Design References
- Design System: `/lib/src/ui/design_tokens.dart`
- Glass Components: `/lib/src/ui/glass_card.dart`, `/lib/src/ui/glass_scaffold.dart`
- Background System: `/lib/src/ui/background_renderer.dart`
- Animation System: `/lib/src/ui/weather_effect.dart`

---

## Notes
- Keep the existing SettingsScreen for advanced configuration (Base URL, etc.)
- Add a settings icon in AppBar for users who need to configure Base URL
- The landing page should only ask for the minimum required input (API key)
- Maintain consistency with the existing liquid glass aesthetic
- Ensure accessibility (screen readers, keyboard navigation)

---

## Timeline Estimate
- Task 1: 2 hours
- Task 2: 3 hours
- Task 3: 6 hours
- Task 4: 4 hours
- Task 5: 4 hours
- Task 6: 2 hours
- Task 7: 2 hours
- Task 8: 4 hours

**Total**: ~27 hours (~3-4 days for single developer)

---

## Risk Assessment
- **Medium Risk**: Lottie animation performance on low-end devices
  - Mitigation: Optimize animation file size, test on various devices
- **Low Risk**: Breaking existing configuration flow
  - Mitigation: Maintain backward compatibility with ConfigService
- **Low Risk**: Design inconsistency with liquid glass aesthetic
  - Mitigation: Follow design tokens strictly, review with design system

---

## Success Metrics
- User can configure API key in < 30 seconds
- Landing page loads in < 2 seconds
- Animation runs at 60fps on target devices
- Zero crashes related to new implementation
- Positive user feedback on simplified UX
