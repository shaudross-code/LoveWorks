import re
with open('App.xcodeproj/project.pbxproj', 'r') as file: content = file.read()
content = re.sub(r'IPHONEOS_DEPLOYMENT_TARGET = 14\.0;', 'IPHONEOS_DEPLOYMENT_TARGET = 15.0;', content)
with open('App.xcodeproj/project.pbxproj', 'w') as file: file.write(content)
