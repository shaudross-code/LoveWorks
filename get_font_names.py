from fontTools.ttLib import TTFont
import sys

def get_font_name(font_path):
    font = TTFont(font_path)
    print(f"Font: {font_path}")
    name_opts = set()
    for record in font['name'].names:
        if record.nameID in (1, 2, 4, 6):
            name_opts.add(record.toUnicode())
    print(name_opts)

get_font_names("iLoveWorks/iLoveWorks/Fonts/Outfit-VariableFont_wght.ttf")
get_font_names("iLoveWorks/iLoveWorks/Fonts/Manrope-VariableFont_wght.ttf")
