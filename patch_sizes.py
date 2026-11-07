import re

# Update JS
with open("frontend/src/lib/sizes.js", "r") as f:
    js_text = f.read()

js_text = js_text.replace('C("bra_band", "Bra band", BANDS, ["womens"]),', 'C("bra_band", "Bra band", BANDS, ["womens", "unspecified"]),')
js_text = js_text.replace('C("bra_cup", "Bra cup", CUPS, ["womens"]),', 'C("bra_cup", "Bra cup", CUPS, ["womens", "unspecified"]),')
js_text = js_text.replace('C("sports_bra", "Sports bra", LETTER6, ["womens"]),', 'C("sports_bra", "Sports bra", LETTER6, ["womens", "unspecified"]),')

with open("frontend/src/lib/sizes.js", "w") as f:
    f.write(js_text)

# Update Swift
with open("iLoveWorks/iLoveWorks/Sizes/SizesService.swift", "r") as f:
    swift_text = f.read()

swift_text = swift_text.replace('C("bra_band", "Bra band", BANDS, ["womens"]),', 'C("bra_band", "Bra band", BANDS, ["womens", "unspecified"]),')
swift_text = swift_text.replace('C("bra_cup", "Bra cup", CUPS, ["womens"]),', 'C("bra_cup", "Bra cup", CUPS, ["womens", "unspecified"]),')
swift_text = swift_text.replace('C("sports_bra", "Sports bra", LETTER6, ["womens"]),', 'C("sports_bra", "Sports bra", LETTER6, ["womens", "unspecified"]),')

with open("iLoveWorks/iLoveWorks/Sizes/SizesService.swift", "w") as f:
    f.write(swift_text)
