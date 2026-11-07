import re

def fix(path):
    try:
        with open(path, 'r') as f:
            text = f.read()

        # Remove our hack
        text = re.sub(r' SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";', '', text)
        
        # Clean build folders explicitly
        
        with open(path, 'w') as f:
            f.write(text)
    except FileNotFoundError:
        pass

fix('App.xcodeproj/project.pbxproj')
