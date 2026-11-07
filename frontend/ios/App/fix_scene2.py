import re

with open('App/Info.plist', 'r') as file:
    content = file.read()

scene_manifest = """	<key>UIApplicationSceneManifest</key>
	<dict>
		<key>UIApplicationSupportsMultipleScenes</key>
		<false/>
	</dict>
	<key>UILaunchStoryboardName</key>"""

content = re.sub(r'\t<key>UILaunchStoryboardName</key>', scene_manifest, content)

with open('App/Info.plist', 'w') as file:
    file.write(content)
