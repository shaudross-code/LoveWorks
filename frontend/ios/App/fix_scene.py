import re

with open("App/Info.plist", "r") as f:
    text = f.read()

scene_dict = """	<key>UIApplicationSceneManifest</key>
	<dict>
		<key>UIApplicationSupportsMultipleScenes</key>
		<false/>
	</dict>
"""

# Insert before closing dict
text = text.replace("</dict>\n</plist>", scene_dict + "</dict>\n</plist>")

with open("App/Info.plist", "w") as f:
    f.write(text)
