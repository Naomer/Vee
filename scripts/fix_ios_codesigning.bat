@echo off
echo 🔧 Fixing iOS code signing settings...

cd ios

REM Create a backup of the original project file
copy Runner.xcodeproj\project.pbxproj Runner.xcodeproj\project.pbxproj.backup

echo 📝 Updating Xcode project settings...

REM Set code signing style to manual
powershell -Command "(Get-Content Runner.xcodeproj\project.pbxproj) -replace 'CODE_SIGN_STYLE = Automatic', 'CODE_SIGN_STYLE = Manual' | Set-Content Runner.xcodeproj\project.pbxproj"

REM Remove development team requirements
powershell -Command "(Get-Content Runner.xcodeproj\project.pbxproj) -replace 'DEVELOPMENT_TEAM = .*', 'DEVELOPMENT_TEAM = \"\"' | Set-Content Runner.xcodeproj\project.pbxproj"

REM Remove provisioning profile requirements
powershell -Command "(Get-Content Runner.xcodeproj\project.pbxproj) -replace 'PROVISIONING_PROFILE_SPECIFIER = .*', 'PROVISIONING_PROFILE_SPECIFIER = \"\"' | Set-Content Runner.xcodeproj\project.pbxproj"

REM Remove code sign identity requirements
powershell -Command "(Get-Content Runner.xcodeproj\project.pbxproj) -replace '\"CODE_SIGN_IDENTITY\[sdk=iphoneos\*\]\" = \"iPhone Developer\"', '\"CODE_SIGN_IDENTITY[sdk=iphoneos*]\" = \"\"' | Set-Content Runner.xcodeproj\project.pbxproj"

echo ✅ Code signing settings fixed!
echo 📱 Ready to build IPA without Apple Developer account

cd ..
