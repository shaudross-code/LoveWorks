import re

def fix_project(path):
    print("Fixing codesign on", path)
    with open(path, 'r') as f:
        text = f.read()

    text = re.sub(r'CODE_SIGNING_ALLOWED = .*?;', 'CODE_SIGNING_ALLOWED = NO;', text)
    text = re.sub(r'CODE_SIGNING_REQUIRED = .*?;', 'CODE_SIGNING_REQUIRED = NO;', text) 
    
    with open(path, 'w') as f:
        f.write(text)

fix_project('Pods/Pods.xcodeproj/project.pbxproj')
