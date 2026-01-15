# Pause. - Configuration Guide

## Required Info.plist Entries

Add these entries to your Info.plist file:

```xml
<key>NFCReaderUsageDescription</key>
<string>Pause. nutzt NFC um deine Focus-Tags zu lesen.</string>

<key>NSFaceIDUsageDescription</key>
<string>Zur Bestätigung deiner Identität bei Screen Time Änderungen.</string>
```

## Required Entitlements

Create or modify your .entitlements file to include:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.family-controls</key>
    <true/>
    
    <key>com.apple.developer.nfc.readersession.formats</key>
    <array>
        <string>NDEF</string>
    </array>
</dict>
</plist>
```

## Xcode Project Setup

### 1. Enable Capabilities
In your Xcode project settings:
1. Select your target
2. Go to "Signing & Capabilities"
3. Click "+ Capability"
4. Add:
   - **Family Controls**
   - **Near Field Communication Tag Reading**

### 2. Set Minimum Deployment Target
- Set iOS Deployment Target to **iOS 16.0** or later
- Note: iOS 18+ is required for Individual Authorization (latest Screen Time features)

### 3. Add Required Frameworks
The following frameworks are automatically linked:
- FamilyControls.framework
- ManagedSettings.framework
- CoreNFC.framework
- SwiftUI.framework

### 4. Update Bundle Identifier
Make sure your bundle identifier is unique and properly configured in your Apple Developer account.

## Testing Requirements

### Physical Device Required
- NFC scanning requires a physical iPhone (iPhone 7 or later)
- iOS Simulator does NOT support NFC
- Screen Time features work on simulator for UI testing only

### Recommended NFC Tags
- NTAG213 (144 bytes)
- NTAG215 (504 bytes) - Recommended
- NTAG216 (888 bytes)

These are available from:
- Amazon
- AliExpress
- Local electronics stores

### Test Checklist
- [ ] Screen Time authorization flow works
- [ ] NFC tag scanning triggers successfully
- [ ] Apps can be selected via FamilyActivityPicker
- [ ] Tag registration saves correctly
- [ ] Tag scanning toggles blocking state
- [ ] App respects Light/Dark mode
- [ ] Haptic feedback works on tag scan

## Known Limitations

1. **Background Scanning**: NFC only works when app is in foreground
2. **System Apps**: Some system apps cannot be blocked
3. **User Override**: Users can disable Screen Time in Settings
4. **Authorization**: User must approve Screen Time access
5. **iOS Version**: Requires iOS 16+, iOS 18+ for Individual Authorization

## Development Workflow

### Phase 1: Setup (Current)
- [x] Project structure created
- [x] MVC architecture implemented
- [x] Basic UI components created
- [ ] Add Info.plist entries
- [ ] Enable capabilities in Xcode
- [ ] Test on physical device

### Phase 2: App Selection Integration
- [ ] Properly handle ApplicationToken encoding/decoding
- [ ] Integrate FamilyActivityPicker with tags
- [ ] Store and restore selected apps
- [ ] Test blocking/unblocking flow

### Phase 3: Polish
- [ ] Add animations and transitions
- [ ] Improve error handling
- [ ] Add onboarding flow
- [ ] Localization (DE/EN)
- [ ] App icon and splash screen

## Next Steps

1. **Add the Info.plist entries** shown above
2. **Enable capabilities** in Xcode project settings
3. **Build and run** on a physical iPhone
4. **Test Screen Time authorization** flow
5. **Get NFC tags** for testing
6. **Scan a tag** to test the NFC functionality

## Troubleshooting

### "Near Field Communication Tag Reading" not available
- Make sure you're using a paid Apple Developer account
- Check that your bundle identifier is properly configured
- Verify the entitlements file is properly linked

### "Family Controls" capability missing
- iOS 16+ required
- Make sure target deployment is set correctly
- Check Apple Developer account has proper permissions

### NFC scanning doesn't work
- Must use physical device (iPhone 7+)
- Check Info.plist has NFCReaderUsageDescription
- Verify NFC capability is enabled
- Ensure tag is compatible (NTAG213/215/216)

### Screen Time authorization fails
- Go to Settings > Screen Time
- Enable Screen Time if disabled
- Check "Apps with Screen Time Access"
- Grant permission to Pause.

## Support Resources

- [Apple Developer Documentation - Family Controls](https://developer.apple.com/documentation/familycontrols)
- [Core NFC Guide](https://developer.apple.com/documentation/corenfc)
- [Screen Time API Overview](https://developer.apple.com/documentation/screentime)
