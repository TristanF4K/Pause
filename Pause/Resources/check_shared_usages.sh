#!/bin/bash

# Find all .shared usages in the project
# This script helps identify remaining singleton usages that need to be migrated

echo "🔍 Searching for remaining .shared usages in the project..."
echo ""
echo "=========================================="
echo "❌ FORBIDDEN .shared usages:"
echo "=========================================="
echo ""

# Search for forbidden singleton usages
echo "📋 AppState.shared:"
grep -rn "AppState\.shared" --include="*.swift" ./Pause 2>/dev/null | grep -v "Documentation" | grep -v "\.md"
echo ""

echo "📋 ScreenTimeController.shared:"
grep -rn "ScreenTimeController\.shared" --include="*.swift" ./Pause 2>/dev/null | grep -v "Documentation" | grep -v "\.md"
echo ""

echo "📋 TagController.shared:"
grep -rn "TagController\.shared" --include="*.swift" ./Pause 2>/dev/null | grep -v "Documentation" | grep -v "\.md"
echo ""

echo "📋 TimeProfileController.shared:"
grep -rn "TimeProfileController\.shared" --include="*.swift" ./Pause 2>/dev/null | grep -v "Documentation" | grep -v "\.md"
echo ""

echo "=========================================="
echo "✅ ALLOWED .shared usages:"
echo "=========================================="
echo ""

echo "📋 SelectionManager.shared (OK):"
grep -rn "SelectionManager\.shared" --include="*.swift" ./Pause 2>/dev/null | grep -v "Documentation" | grep -v "\.md" | wc -l
echo " occurrences found (this is OK - legitimate singleton)"
echo ""

echo "📋 NFCController.shared (OK):"
grep -rn "NFCController\.shared" --include="*.swift" ./Pause 2>/dev/null | grep -v "Documentation" | grep -v "\.md" | wc -l
echo " occurrences found (this is OK - hardware controller)"
echo ""

echo "📋 PersistenceController.shared (OK):"
grep -rn "PersistenceController\.shared" --include="*.swift" ./Pause 2>/dev/null | grep -v "Documentation" | grep -v "\.md" | wc -l
echo " occurrences found (this is OK - persistence layer)"
echo ""

echo "📋 AuthorizationCenter.shared (OK):"
grep -rn "AuthorizationCenter\.shared" --include="*.swift" ./Pause 2>/dev/null | grep -v "Documentation" | grep -v "\.md" | wc -l
echo " occurrences found (this is OK - Apple framework)"
echo ""

echo "=========================================="
echo "📊 Summary"
echo "=========================================="
echo ""
echo "If any FORBIDDEN usages are found above, they need to be migrated to @EnvironmentObject."
echo ""
echo "See QUICK_FIX_GUIDE.md for step-by-step instructions."
echo ""
