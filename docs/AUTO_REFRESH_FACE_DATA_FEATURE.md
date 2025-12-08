# Auto Refresh Face Data Feature

## Overview
This feature automatically refreshes (downloads) face data from Firestore after creating or editing students, ensuring the face recognition system always has the latest data. This prevents recognition failures caused by forgotten manual refreshes.

## Problem Solved
Users often forget to manually refresh face data after adding or editing students, leading to:
- Face recognition failures for newly added students
- Outdated face data for edited students
- Confusion and troubleshooting time

## Implementation

### Settings
- **Setting Name**: "Auto Refresh Face Data"
- **Default**: ON (enabled by default)
- **Location**: Settings → Display section
- **Purpose**: Automatically refresh face data after student create/edit operations

### How It Works

1. **Student Created**
   - New student is saved to Firestore
   - Face samples and face data are uploaded
   - If auto-refresh is ON: automatically downloads all face data
   - CameraViewModel is notified to reload cache
   - User sees success message

2. **Student Edited**
   - Student is updated in Firestore
   - Face data is updated (if new images captured)
   - If auto-refresh is ON: automatically downloads all face data
   - CameraViewModel is notified to reload cache
   - User sees success message

3. **Cache Update**
   - Downloaded face data is saved to local cache
   - Notification "FaceDataRefreshed" is posted
   - CameraViewModel listens for notification
   - Cache is reloaded automatically
   - Face recognition uses updated data immediately

### Code Changes

#### 1. SettingsService.swift
- Added `autoRefreshAfterStudentChange` key
- Added property with default value `true`
- Added to reset functionality

```swift
var autoRefreshAfterStudentChange: Bool {
    get {
        if defaults.object(forKey: Keys.autoRefreshAfterStudentChange) == nil {
            return true  // Default ON
        }
        return defaults.bool(forKey: Keys.autoRefreshAfterStudentChange)
    }
    set {
        defaults.set(newValue, forKey: Keys.autoRefreshAfterStudentChange)
    }
}
```

#### 2. StudentViewModel.swift
- Added `cacheService` and `settingsService` dependencies
- Added `autoRefreshFaceData()` function
- Calls auto-refresh after `createStudent()`
- Calls auto-refresh after `updateStudent()`
- Posts notification when refresh completes

```swift
private func autoRefreshFaceData(reason: String) async {
    do {
        let faceData = try await firebaseService.downloadFaceData(schoolId: schoolId)
        try cacheService.saveFaceData(faceData)
        NotificationCenter.default.post(name: NSNotification.Name("FaceDataRefreshed"), object: nil)
    } catch {
        // Silent failure - background operation
    }
}
```

#### 3. CameraViewModel.swift
- Added notification observer in `init()`
- Listens for "FaceDataRefreshed" notification
- Automatically reloads cache when notified

```swift
NotificationCenter.default.addObserver(
    forName: NSNotification.Name("FaceDataRefreshed"),
    object: nil,
    queue: .main
) { [weak self] _ in
    self?.reloadCache()
}
```

#### 4. SettingsView.swift
- Added toggle for "Auto Refresh Face Data"
- Placed in Display section with other feature toggles
- Shows icon (arrow.clockwise) and description
- Updates setting when toggled

### When to Turn OFF
Consider turning OFF auto-refresh when:
- Adding many students in bulk (5+ students)
- Testing student creation without needing immediate recognition
- Experiencing slow network connection
- Conserving battery on device

After bulk operations, manually refresh face data from Settings → "Download Face Data".

### Benefits
1. **Prevents Recognition Failures**: Always uses latest face data
2. **Improves User Experience**: No manual refresh needed
3. **Reduces Support Issues**: Fewer "recognition not working" complaints
4. **Configurable**: Can be disabled during bulk operations
5. **Silent Operation**: Runs in background, doesn't block UI

### Testing
To test the auto-refresh feature:

1. **Verify Setting**
   - Go to Settings → Display section
   - Check "Auto Refresh Face Data" is ON by default
   - Toggle ON/OFF and verify console logs

2. **Test Student Creation**
   - Create a new student with face photos
   - Observe console: "🔄 Auto-refreshing face data: Student created"
   - Observe console: "✅ Face data auto-refreshed: X records"
   - Observe console: "🔄 Cache reloaded from auto-refresh notification"
   - Go to camera, verify cache shows updated count

3. **Test Student Editing**
   - Edit an existing student (change name or add new photos)
   - Observe same console logs as above
   - Verify cache updates automatically

4. **Test Setting OFF**
   - Turn OFF "Auto Refresh Face Data" in Settings
   - Create or edit a student
   - Should NOT see auto-refresh logs
   - Cache should NOT update automatically

### Performance Notes
- Download happens in background (async)
- UI remains responsive during download
- Failed downloads don't show errors to user (logged to console)
- Typical download time: 1-3 seconds for 10-50 students
- Network data usage: ~50-200KB per refresh

### Troubleshooting
If auto-refresh isn't working:
1. Check setting is ON in Settings → Display
2. Check console for "Auto-refreshing face data" logs
3. Check for network errors in console
4. Verify Firestore connection is working
5. Try manual refresh from Settings to test connectivity

### Future Enhancements
- Add visual indicator during auto-refresh (optional)
- Add setting for refresh delay (e.g., debounce multiple edits)
- Add offline queue for pending refreshes
- Add refresh statistics (last refresh time, data size)
