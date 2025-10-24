# Momentchen Swift - Quick Start Guide

**Version:** 1.0
**Date:** October 22, 2025
**Platform:** iOS 17.0+, macOS 14.0+

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Build and Run](#build-and-run)
3. [Configure Notion Integration](#configure-notion-integration)
4. [Test Key Flows](#test-key-flows)
5. [Troubleshooting](#troubleshooting)
6. [Development Workflow](#development-workflow)

---

## Prerequisites

### Required Software

- **Xcode:** 15.0+ (for Swift 5.9+ and SwiftUI support)
- **macOS:** 14.0+ (Sonoma or later)
- **iOS Simulator:** iOS 17.0+ or physical device
- **Notion Account:** Free or paid account
- **Notion Integration Token:** Created via Notion developers portal

### System Requirements

- **Disk Space:** ~500MB for Xcode project + build artifacts
- **Memory:** 8GB RAM minimum (16GB recommended for simulator)
- **Network:** Active internet connection for Notion API calls

---

## Build and Run

### Step 1: Open Project in Xcode

```bash
cd /Users/rubeen/dev/personal/momentchen-app
open Momentchen/Momentchen.xcodeproj
```

**Expected Result:** Xcode opens with project structure visible

### Step 2: Select Target Device

**For iPhone:**
1. Click device selector in Xcode toolbar
2. Choose "iPhone 15" (or any iOS 17.0+ simulator)
3. Or select your physical iPhone if connected

**For macOS:**
1. Click device selector
2. Choose "My Mac (Designed for iPad)" or "My Mac"

### Step 3: Build the Project

**Keyboard Shortcut:** `⌘B` (Command + B)

**Menu:** Product → Build

**Expected Output:**
```
Build Succeeded
0 errors, 0 warnings
Build time: ~30-60 seconds (first build)
```

**Common Build Issues:**

| Error | Solution |
|-------|----------|
| "Swift compiler version mismatch" | Ensure Xcode 15+ installed |
| "Cannot find 'SwiftData' in scope" | Select iOS 17.0+ deployment target |
| "Module 'SwiftUI' not found" | Clean build folder (⇧⌘K) and rebuild |

### Step 4: Run the App

**Keyboard Shortcut:** `⌘R` (Command + R)

**Menu:** Product → Run

**Expected Behavior:**
- Simulator/device launches
- App displays "Mit Notion verbinden" setup screen
- No crashes or errors in console

**Xcode Console Output (Expected):**
```
[Momentchen] App launched successfully
[NotionAPI] Initializing API service
[SwiftData] ModelContainer created for AppConfiguration
```

---

## Configure Notion Integration

### Step 1: Create Notion Integration Token

1. **Open Notion Developers Portal:**
   - Navigate to: https://www.notion.so/my-integrations
   - Click "New integration"

2. **Configure Integration:**
   - **Name:** "Momentchen Test" (or any name)
   - **Associated workspace:** Select your personal workspace
   - **Type:** Internal integration
   - **Capabilities:**
     - ✅ Read content
     - ✅ Update content
     - ✅ Insert content
     - ❌ No user information needed

3. **Copy Integration Token:**
   - Click "Show" next to "Internal Integration Token"
   - Copy token (format: `secret_XXXXXXXXXXXXXXXXXXXXXX`)
   - ⚠️ **Keep this secret!** Do not commit to version control

### Step 2: Create Test Notion Databases

#### Database 1: Momente (Moments)

1. Create new database in Notion
2. Add properties:
   - **Name** (Title) - Already exists
   - **Typ** (Select) - Add options:
     - Gedanke (Color: Blue)
     - Erlebnis (Color: Green)
     - Aktivität (Color: Orange)
     - Idee (Color: Yellow)
     - Emotion (Color: Red)
     - Lernen (Color: Purple)
   - **Zeitpunkt** (Date) - Include time
   - **Projekt** (Relation) - Link to "Projekte" database
   - **Lebensbereich** (Relation) - Link to "Lebensbereiche" database

3. **Share Database with Integration:**
   - Click "..." menu in top-right
   - Select "Add connections"
   - Choose "Momentchen Test" integration

#### Database 2: Projekte (Projects)

1. Create new database
2. Add properties:
   - **Projekt** (Title) - Already exists
   - **Status** (Status) - Add group: "In Bearbeitung"

3. Add sample projects:
   - "Sport & Gesundheit" (Status: In Bearbeitung)
   - "Lernen & Entwicklung" (Status: In Bearbeitung)
   - "Kreative Projekte" (Status: In Bearbeitung)

4. Share with integration (same as above)

#### Database 3: Lebensbereiche (Life Areas)

1. Create new database
2. Add properties:
   - **Thema** (Title) - Already exists
   - **Status** (Status) - Add group: "Aktiv"

3. Add sample life areas:
   - "Körper & Gesundheit" (Status: Aktiv)
   - "Geist & Lernen" (Status: Aktiv)
   - "Beziehungen" (Status: Aktiv)
   - "Karriere" (Status: Aktiv)

4. Share with integration

### Step 3: Configure App

1. **Launch App** (if not already running)

2. **Enter Token:**
   - Paste integration token into SecureField
   - Tap "Validieren" button
   - ✅ Success: Green checkmark + "Token validiert!"
   - ❌ Error: Alert with "Ungültiger Token"

3. **Select Databases:**
   - **Momente Datenbank:** Choose your "Momente" database
   - **Projekte Datenbank:** Choose your "Projekte" database
   - **Lebensbereiche Datenbank:** Choose your "Lebensbereiche" database

4. **Save Configuration:**
   - Tap "Speichern" button (enabled when all 3 selected)
   - Alert: "Setup abgeschlossen!"
   - App navigates to moment list view

---

## Test Key Flows

### Flow 1: Create a Moment

**Estimated Time:** 30 seconds

1. **Open Moment Form:**
   - Tap "+" button in top-right
   - Form sheet appears

2. **Fill Form:**
   - **Beschreibung:** "Spaziergang im Park bei Sonnenuntergang"
   - **Typ:** Tap "Erlebnis" (green button)
   - **Zeitpunkt:** Keep current time (or adjust)
   - **Projekt:** Select "Sport & Gesundheit"
   - **Lebensbereich:** Select "Körper & Gesundheit"

3. **Save:**
   - Tap "Speichern"
   - Sheet dismisses
   - New moment appears in list

**Validation:**
- ✅ Moment visible in list with green "Erlebnis" badge
- ✅ Timestamp shows current time (HH:mm format)
- ✅ Project and life area badges visible
- ✅ Open Notion web → Verify page created in database

### Flow 2: View Today's Moments

**Expected Behavior:**
- List shows all moments with "Zeitpunkt" = today (UTC date)
- Moments sorted newest first (descending timestamp)
- Each row shows:
  - Description (max 2 lines)
  - Type badge with color
  - Timestamp in local time (e.g., "14:30")
  - Project/life area icons (if present)

**Test Auto-Refresh:**
1. Create a moment in Notion web interface (manually)
2. Wait 15 seconds
3. ✅ New moment appears in app automatically

**Test Pull-to-Refresh:**
1. Swipe down from top of list
2. ✅ Refresh spinner appears
3. ✅ List updates with latest data

### Flow 3: Edit a Moment

**Current Implementation Note:** ⚠️ No separate detail view (see Known Limitations)

1. **Open Moment:**
   - Tap on a moment in list
   - Edit form appears (pre-filled)

2. **Modify Fields:**
   - Change description
   - Switch type to "Gedanke"
   - Update timestamp

3. **Save Changes:**
   - Tap "Speichern"
   - Form dismisses
   - ✅ Updated moment visible in list
   - ✅ Verify changes in Notion web

### Flow 4: Theme Switching

1. **Open Settings:**
   - Tap "Settings" tab (if TabView implemented)
   - Or navigate to SettingsView

2. **Switch Theme:**
   - Tap "Dark" in segmented control
   - ✅ UI immediately switches to dark theme
   - ✅ No flashing or delay

3. **Test Persistence:**
   - Close app (swipe up in simulator)
   - Relaunch app
   - ✅ Dark theme still active

### Flow 5: Setup Reset

1. **Navigate to Settings**

2. **Tap "Setup zurücksetzen"**
   - Confirmation dialog appears: "Warnung vor Datenverlust"

3. **Confirm:**
   - Tap "Zurücksetzen" (destructive action)
   - ✅ App navigates to setup screen
   - ✅ Token/databases cleared
   - ✅ Moment data NOT deleted (still in Notion)

4. **Re-configure:**
   - Enter token again
   - Select databases
   - ✅ Previous moments still visible (from Notion)

---

## Troubleshooting

### Issue: Token Validation Fails (401 Error)

**Symptoms:**
- Alert: "Token ungültig oder abgelaufen"
- Console: `HTTP 401: Unauthorized`

**Solutions:**
1. **Check Token Format:**
   - Must start with `secret_`
   - 50+ characters long
   - No extra spaces or line breaks

2. **Verify Integration Active:**
   - Go to Notion integrations page
   - Ensure integration not archived/deleted

3. **Regenerate Token:**
   - Click "Secrets" → "Show" → "Refresh"
   - Copy new token
   - Try again in app

### Issue: Databases Not Loading

**Symptoms:**
- Empty database pickers
- Error: "Keine Datenbanken gefunden"

**Solutions:**
1. **Check Integration Connection:**
   - Open each database in Notion web
   - Click "..." → "Add connections"
   - Ensure integration listed

2. **Verify Database Shared:**
   - Integration must have explicit access
   - Check "Connections" section in database settings

3. **Check Network:**
   - Disable VPN (some VPNs block Notion API)
   - Test with mobile hotspot

### Issue: Moments Not Appearing in List

**Symptoms:**
- List shows empty state
- Console: No errors
- Moments exist in Notion

**Solutions:**
1. **Check Date Filter:**
   - App filters for TODAY only (UTC date)
   - Create a moment with today's date manually
   - Verify "Zeitpunkt" property has date+time

2. **Check Database ID:**
   - Settings → Verify correct "Momente DB" selected
   - Reset setup if wrong database chosen

3. **Manual Refresh:**
   - Pull-to-refresh
   - Check console for API errors

### Issue: Auto-Refresh Not Working

**Symptoms:**
- New moments don't appear after 15 seconds
- Timer not firing

**Debug Steps:**
1. **Check Console:**
   ```
   [MomentListViewModel] Auto-refresh started
   [MomentListViewModel] Refreshing moments (silent)
   ```

2. **Verify Timer:**
   - Add breakpoint in `MomentListViewModel.startAutoRefresh()`
   - Check `refreshTimer` is not nil

3. **Check App State:**
   - Timer paused when app in background
   - Return to foreground to resume

### Issue: Build Errors

**Error: "Cannot find 'SwiftData' in scope"**

**Solution:**
1. Select project in Navigator
2. Select "Momentchen" target
3. General → Deployment Info → Set to iOS 17.0+
4. Clean build folder (⇧⌘K)
5. Rebuild (⌘B)

**Error: "Module compiled with Swift X.X cannot be imported by Swift Y.Y"**

**Solution:**
1. Xcode → Preferences → Locations
2. Command Line Tools → Select Xcode 15.0+
3. Restart Xcode
4. Clean and rebuild

### Issue: App Crashes on Launch

**Symptoms:**
- App opens then immediately crashes
- Xcode shows SIGABRT or SIGSEGV

**Debug Steps:**
1. **Check Exception Breakpoint:**
   - Debug Navigator → Breakpoints → "+" → Exception Breakpoint
   - Run again to see exact crash line

2. **Check SwiftData:**
   - Console error: "Could not create ModelContainer"
   - Solution: Reset simulator (Device → Erase All Content and Settings)

3. **Check API Token:**
   - If crash in `NotionAPIService.init()`
   - Ensure token is valid string (not causing encoding issues)

---

## Development Workflow

### Running Tests (When Implemented)

**Unit Tests:**
```bash
# Command line
xcodebuild test -scheme Momentchen -destination 'platform=iOS Simulator,name=iPhone 15'

# Or in Xcode: ⌘U (Command + U)
```

**Expected Output:**
```
Test Suite 'All tests' passed at 2025-10-22 14:30:00.
Executed 42 tests, with 0 failures (0 unexpected) in 2.5 seconds
```

### Debugging with Xcode

**Enable Debug Logging:**
1. Edit Scheme (⌘<)
2. Run → Arguments → Environment Variables
3. Add: `NOTION_DEBUG=1`
4. Run app
5. Console shows detailed API requests/responses

**Breakpoint Workflow:**
1. Click line number in code editor (blue arrow appears)
2. Run app (⌘R)
3. When breakpoint hits:
   - Step Over: F6
   - Step Into: F7
   - Continue: ⌘⌃Y
   - Inspect variables in Debug Area

**View Hierarchy Debugging:**
1. Run app
2. Pause execution (pause button in toolbar)
3. Click "View Hierarchy" icon (3D layers)
4. Inspect SwiftUI view tree

### Testing on Physical Device

1. **Connect iPhone via USB**

2. **Trust Computer:**
   - iPhone prompt: "Trust This Computer?"
   - Enter passcode

3. **Select Device:**
   - Device selector → Your iPhone name

4. **Build and Run:**
   - First time: Xcode will install provisioning profile
   - iPhone Settings → General → VPN & Device Management
   - Trust developer certificate

5. **Performance Testing:**
   - Physical device recommended for:
     - Auto-refresh CPU usage
     - Network latency
     - Scroll performance

### Instruments Profiling

**Measure Load Time:**
1. Product → Profile (⌘I)
2. Select "Time Profiler"
3. Record session
4. Navigate to moment list
5. Stop recording
6. Analyze call tree for bottlenecks

**Measure Memory:**
1. Product → Profile
2. Select "Leaks"
3. Run typical user flow
4. Check for leaked objects (should be 0)

**Measure Network:**
1. Product → Profile
2. Select "Network"
3. Observe API calls:
   - Request size
   - Response time
   - Bandwidth usage

---

## API Testing with Postman/curl

### Validate Token (Manual Test)

```bash
curl -X POST https://api.notion.com/v1/users/me \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Notion-Version: 2022-06-28"
```

**Expected Response:**
```json
{
  "object": "user",
  "id": "user-id-here",
  "name": "Your Name",
  "type": "person"
}
```

### Search Databases

```bash
curl -X POST https://api.notion.com/v1/search \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d '{
    "filter": {
      "property": "object",
      "value": "database"
    },
    "page_size": 100
  }'
```

### Query Today's Moments

```bash
curl -X POST https://api.notion.com/v1/databases/YOUR_DB_ID/query \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d '{
    "filter": {
      "property": "Zeitpunkt",
      "date": {
        "equals": "2025-10-22"
      }
    },
    "sorts": [
      {
        "property": "Zeitpunkt",
        "direction": "descending"
      }
    ],
    "page_size": 100
  }'
```

---

## Environment Variables (Optional)

For automated testing, add to Xcode scheme:

| Variable | Value | Purpose |
|----------|-------|---------|
| `NOTION_TEST_TOKEN` | Your test token | Skip manual token entry in tests |
| `MOMENTS_DB_ID` | Database ID | Automated setup |
| `PROJECTS_DB_ID` | Database ID | Automated setup |
| `LIFEAREAS_DB_ID` | Database ID | Automated setup |
| `NOTION_DEBUG` | `1` | Enable verbose API logging |

**How to Add:**
1. Edit Scheme (⌘<)
2. Run → Arguments → Environment Variables
3. Click "+" to add variables
4. Run app with variables active

---

## Known Limitations

### API Limitations

1. **No Delete Support:**
   - Notion API does not support page deletion
   - Swipe-delete action shows error message
   - Workaround: Archive pages in Notion web

2. **Rate Limiting:**
   - 3 requests per second average
   - App implements exponential backoff
   - Rare to hit in normal usage

### Implementation Gaps (See validation-report.md)

1. **No Detail View Mode:**
   - Tapping moment opens edit form directly
   - No readonly view with edit icon
   - Planned for V1.1

2. **No Dirty-State Confirmation:**
   - Cancel button dismisses without warning
   - No "Unsaved changes" alert
   - Planned for V1.1

3. **No 401 Auto-Redirect:**
   - Invalid token shows alert
   - Manual navigation to setup required
   - Planned for V1.1

---

## Next Steps

After successful setup and testing:

1. **Explore Code:**
   - Read `architecture.md` for detailed design
   - Review `test-plan.md` for comprehensive test cases
   - Check `validation-report.md` for PRD compliance

2. **Contribute:**
   - Implement missing features (see gaps in validation report)
   - Add unit tests (currently 0% coverage)
   - Improve accessibility (VoiceOver labels)

3. **Deploy:**
   - Archive for App Store (Product → Archive)
   - TestFlight beta testing
   - Submit for review

---

## Support

**Documentation:**
- Architecture: `docs/architecture.md`
- PRD: `docs/prd.txt`
- Test Plan: `docs/test-plan.md`
- Validation Report: `docs/validation-report.md`

**External Resources:**
- Notion API Docs: https://developers.notion.com/reference/intro
- SwiftUI Tutorials: https://developer.apple.com/tutorials/swiftui
- SwiftData Guide: https://developer.apple.com/documentation/swiftdata

**Common Questions:**
- "Where is the token stored?" → SwiftData (encrypted by iOS Keychain)
- "Can I use multiple Notion workspaces?" → No, V1 supports single workspace
- "Does offline mode work?" → No, app requires internet connection
- "Can I export my data?" → Not in V1, use Notion's export feature

---

**Document Version:** 1.0
**Last Updated:** October 22, 2025
**Tested On:** Xcode 15.0, iOS 17.0 Simulator
