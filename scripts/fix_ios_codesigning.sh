#!/bin/bash

# Fix iOS code signing for IPA build without Apple Developer account
echo "🔧 Fixing iOS code signing settings..."

cd ios

# Create a backup of the original project file
cp Runner.xcodeproj/project.pbxproj Runner.xcodeproj/project.pbxproj.backup

# Fix code signing settings using sed
echo "📝 Updating Xcode project settings..."

# Set code signing style to manual
sed -i '' 's/CODE_SIGN_STYLE = Automatic/CODE_SIGN_STYLE = Manual/g' Runner.xcodeproj/project.pbxproj

# Remove development team requirements
sed -i '' 's/DEVELOPMENT_TEAM = .*/DEVELOPMENT_TEAM = ""/g' Runner.xcodeproj/project.pbxproj

# Remove provisioning profile requirements  
sed -i '' 's/PROVISIONING_PROFILE_SPECIFIER = .*/PROVISIONING_PROFILE_SPECIFIER = ""/g' Runner.xcodeproj/project.pbxproj

# Remove code sign identity requirements
sed -i '' 's/"CODE_SIGN_IDENTITY\[sdk=iphoneos\*\]" = "iPhone Developer"/"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = ""/g' Runner.xcodeproj/project.pbxproj

echo "✅ Code signing settings fixed!"
echo "📱 Ready to build IPA without Apple Developer account"

cd ..
