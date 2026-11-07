import re

with open('App/Info.plist', 'r') as file:
    content = file.read()

# Make sure we don't have multiple
content = re.sub(r'\t<key>UIApplicationSceneManifest</key>\n\t<dict>\n\t\t<key>UIApplicationSupportsMultipleScenes</key>\n\t\t<false/>\n\t</dict>\n', '', content)
content = re.sub(r'\t<key>UIApplicationSceneManifest</key>\n\t<dict>\n\t\t<key>UIApplicationSupportsMultipleScenes</key>\n\t\t<false/>\n\t\t<key>UISceneConfigurations</key>\n\t\t<dict/>\n\t</dict>\n', '', content)

scene_manifest = """	<key>UIApplicationSceneManifest</key>
	<dict>
		<key>UIApplicationSupportsMultipleScenes</key>
		<false/>
		<key>UISceneConfigurations</key>
		<dict/>
	</dict>
	<key>UILaunchStoryboardName</key>"""

content = re.sub(r'\t<key>UILaunchStoryboardName</key>', scene_manifest, content)

with open('App/Info.plist', 'w') as file:
    file.write(content)
