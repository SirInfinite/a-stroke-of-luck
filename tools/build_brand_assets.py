"""A Stroke of Luck's editable vector source; no downloaded/generated raster art.

Run: python tools/build_brand_assets.py [--check]
Requires fontTools only for outlining the repository's approved Fredoka font.
SVGs are build outputs, deliberately plain paths/circles with no embedded fonts.
The game loads imported SVG textures, never raw source files at runtime.
"""

from __future__ import annotations

import argparse
from pathlib import Path
from xml.etree import ElementTree

from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont

ROOT = Path(__file__).resolve().parents[1]
WHITE = "#ffffff"
# These colored vector exports predate the production pixel palette. Preserve
# their authored ink so rebuilding semantic glyphs cannot recolor archived brand
# art, the app icon or native toggle assets when UIStyle changes.
PALETTE = {
    'INK': '17201e', 'PAPER': 'f6f1df', 'GOLD': 'edbf45',
    'GOLD_DARK': 'a86f24', 'CURSE': 'e15468', 'CURSE_DARK': '4b1d2b',
}
INK, PAPER, GOLD, CORAL = (f'#{PALETTE[name]}' for name in ['INK', 'PAPER', 'GOLD', 'CURSE'])


def path(d: str, solid: bool = False, width: float = 4) -> str:
    return (f'<path d="{d}" fill="{WHITE if solid else "none"}" '
            f'stroke="{WHITE}" stroke-width="{width}" '
            'stroke-linecap="round" stroke-linejoin="round"/>')


def disc(x: float, y: float, radius: float, solid: bool = True) -> str:
    return (f'<circle cx="{x}" cy="{y}" r="{radius}" '
            f'fill="{WHITE if solid else "none"}" '
            f'stroke="{WHITE if not solid else "none"}" stroke-width="4"/>')


def circle_path(x: float, y: float, radius: float) -> str:
    return f'M{x-radius} {y}a{radius} {radius} 0 1 0 {radius*2} 0a{radius} {radius} 0 1 0 {-radius*2} 0Z'


def punched(outer: str, holes: str) -> str:
    return f'<path d="{outer} {holes}" fill="{WHITE}" fill-rule="evenodd"/>'


def dimples(x: float, y: float, radius: float) -> str:
    # Shallow staggered golf dimples, not three deep bowling-ball finger holes.
    result = ''
    for dx, dy in [(-.34, -.35), (.12, -.44), (.48, -.14), (-.52, .10), (-.04, .04), (.22, .42), (-.25, .47)]:
        cx, cy = x + dx * radius, y + dy * radius
        r = radius * .075
        result += f'M{cx-r} {cy}q{r} {r*1.7} {r*2} 0q{-r} {r*.6} {-r*2} 0Z'
    return result


def box(x: int, y: int, width: int, height: int) -> str:
    return f'<rect x="{x}" y="{y}" width="{width}" height="{height}" rx="4" fill="none" stroke="{WHITE}" stroke-width="4"/>'


def glyphs(small: bool) -> dict[str, str]:
    """All glyphs share a 64-unit optical grid. Small omits nonessential marks."""
    club = path('M49 8L25 47') + path('M13 42L29 39L36 49L20 57L8 51Z', True)
    ball = punched(circle_path(32, 32, 22), '' if small else dimples(32, 32, 22))
    flag = path('M25 52V10') + path('M26 11L51 19L26 28Z', True)
    star = path('M32 9L39 24L55 26L43 38L46 54L32 46L18 54L21 38L9 26L25 24Z', True, 3)
    target = disc(32, 32, 19, False) + disc(32, 32, 4)
    shield = path('M32 9L51 16V30Q51 45 32 55Q13 45 13 30V16Z')
    curse = path('M20 9H43L52 18V49Q52 53 48 53H16Q12 53 12 49V17Q12 13 16 13')
    curse += path('M34 11L27 28L38 33L29 49', False, 5)
    # Flat front-facing die: seed is a repeatable roll, randomize is a new roll.
    seed = box(11, 11, 42, 42)
    for x, y in [(22, 22), (42, 22), (32, 32), (22, 42), (42, 42)]:
        seed += disc(x, y, 2.7)
    card = box(22, 12, 30, 42) + path('M15 47H12Q8 47 8 43V12Q8 8 12 8H39')
    card += path('M37 23L44 32L37 41L30 32Z', True, 2)
    magnet = path('M14 12H25V34Q25 42 32 42Q39 42 39 34V12H50V35Q50 55 32 55Q14 55 14 35Z')
    magnet += path('M15 23H24M40 23H49')
    boot = path('M18 10H35V32L49 37Q55 39 55 47V50H11V42L18 35Z')
    boot += path('M12 55H54M28 19H35M28 27H35')
    if not small:
        boot += path('M19 50V55M33 50V55M47 50V55', False, 3)
    flake = path('M32 9V55M12 20L52 44M12 44L52 20')
    if not small:
        flake += path('M25 14L32 20L39 14M25 50L32 44L39 50M12 28L21 26L20 16M44 48L43 38L52 36', False, 3)
    # Biomes: one botanical/geological silhouette, a shared substantial weight,
    # and one negative-space detail. They remain emblems rather than mini scenes.
    flower = punched('M32 7C39 7 40 16 38 19C47 12 54 18 50 25C59 31 53 39 44 37C43 47 34 48 32 40C26 48 18 44 20 37C10 40 5 31 14 26C9 17 18 13 26 19C23 11 26 7 32 7Z', circle_path(32, 27, 5))
    flower += path('M32 41V55M32 53Q18 54 13 45Q27 42 32 53M33 52Q43 41 53 44Q48 55 33 55', False, 4)
    leaf = punched('M32 7L39 20L48 15L46 29L56 30L45 42L47 48L35 48L33 57L29 56L29 48L17 49L19 42L8 31L19 28L16 15L26 20Z', 'M30 22H34V41L44 33L46 36L34 46H30L18 36L20 33L30 41Z')
    cactus = path('M29 55V15Q29 8 35 8Q41 8 41 15V55', False, 8)
    cactus += path('M29 35H20Q14 35 14 29V21M41 43H48Q53 43 53 37V29', False, 7)
    cactus += path('M22 55H48', False, 4) + disc(14, 11, 4)
    swamp = path('M26 47V15M42 47V23M26 41Q15 40 11 29', False, 4)
    swamp += path('M26 14V25M42 21V32', False, 9)
    swamp += punched('M10 51Q24 42 40 46Q53 47 55 54Q36 61 10 55Z', 'M34 49L47 47L41 54Z')
    volcano = punched('M7 55L22 26L29 23L39 26L57 55Z', 'M29 27L24 37L35 35L29 46L36 53L40 50L35 44L42 31L32 32L33 28Z')
    volcano += path('M25 17Q19 12 25 8M36 17Q43 14 39 8', False, 4)
    flake = path('M32 8V56M11 20L53 44M11 44L53 20', False, 5)
    flake += path('M25 12L32 19L39 12M25 52L32 45L39 52M11 28L22 26L21 15M43 49L42 38L53 36M11 36L22 38L21 49M43 15L42 26L53 28', False, 3)
    if small:
        flake = path('M32 8V56M11 20L53 44M11 44L53 20', False, 6) + disc(32, 32, 8)
    warning = punched('M32 8L58 54H6Z', 'M29 23H35V39H29Z' + circle_path(32, 46, 3))
    result = {
        'ball': ball,
        'hole': flag + path('M15 47Q4 53 17 56H41Q52 54 43 48'),
        'stroke': club,
        'par': target,
        'trajectory': path('M10 51L30 18L52 43M40 43H52V31') + disc(10, 51, 4),
        'power': path('M35 8L14 35H29L25 56L51 26H35Z', True, 3),
        'tee': disc(32, 22, 13, False) + path('M16 39H48M23 40L32 56L41 40'),
        'timer': disc(32, 36, 19, False) + path('M25 8H39M32 9V17M32 25V37L42 41'),
        'coin': punched(circle_path(32, 32, 23), 'M32 21L43 32L32 43L21 32Z'),
        'biome': path('M10 49L24 24L34 36L42 22L55 49Z') + disc(17, 15, 5),
        'benefit': path('M26 12H38V26H52V38H38V52H26V38H12V26H26Z', True, 3),
        'curse': curse,
        'stack': box(22, 10, 30, 36) + path('M16 18V50H45M10 26V56H38'),
        'card': card,
        'active_effect': card + path('M15 24V35M10 29H20', False, 3),
        'shop': path('M13 28V54H51V28M9 27L15 10H49L55 27Z') + path('M26 54V39H39V54M24 12L22 26M40 12L42 26'),
        'lock': box(14, 28, 36, 27) + path('M22 27V19Q22 9 32 9Q42 9 42 19V27') + disc(32, 41, 3),
        'warning': warning,
        'oob': path('M11 9V55H55M11 24H20M11 41H20') + disc(43, 20, 9, False) + path('M30 43L48 28M29 32V44H41'),
        'sand': path('M9 42Q19 22 32 36Q44 45 55 28M10 53Q27 39 45 52') + disc(18, 16, 2.5) + disc(32, 22, 2.5),
        'water': path('M10 39Q17 32 25 39T41 39T55 39M10 51Q17 44 25 51T41 51T55 51') + path('M32 8Q16 26 32 29Q48 26 32 8Z', True, 2),
        'ice': box(11, 11, 42, 42) + path('M36 12L27 28L39 33L27 52M27 28L15 26'),
        'lava': path('M11 47Q23 40 33 47T54 47M16 55H48') + path('M33 8Q33 22 43 23Q53 41 32 41Q12 39 23 22Q23 33 31 31Q25 21 33 8Z', True, 2),
        'bounce_pad': box(10, 40, 44, 14) + path('M18 33L32 19L46 33M18 20L32 6L46 20'),
        'blocker': box(9, 14, 46, 38) + path('M10 32H54M31 15V31M23 33V51M43 33V51'),
        'pendulum': path('M10 9H35M24 10L38 29') + path('M42 25L47 31L55 31L54 39L59 45L52 49L49 56L41 53L33 55L30 47L23 43L28 36L29 28L37 29Z', True, 2),
        'falling_ice': box(13, 27, 38, 28) + path('M13 8V18M32 6V17M51 8V18M34 28L27 39L37 44L29 55'),
        'meadow': flower,
        'desert': cactus,
        'autumn': leaf,
        'snow': flake,
        'swamp': swamp,
        'volcanic': volcano,
        'settings': path('M10 17H54M10 32H54M10 47H54') + path('M24 12V22M42 27V37M26 42V52', False, 9),
        'display': box(9, 11, 46, 33) + path('M24 54H40M32 45V54'),
        'audio': path('M11 26H21L34 14V50L21 38H11Z') + path('M43 23Q51 32 43 41M49 14Q63 32 49 50'),
        'controls': box(8, 15, 48, 34) + disc(20, 26, 2.5) + disc(32, 26, 2.5) + disc(44, 26, 2.5) + path('M19 39H45'),
        'accessibility': disc(32, 13, 5) + path('M12 25L32 29L52 25M32 30V40L20 55M32 40L44 55', False, 5),
        'back': path('M51 32H13M27 17L12 32L27 47', False, 5),
        'continue': path('M13 32H51M37 17L52 32L37 47', False, 5),
        'close': path('M17 17L47 47M47 17L17 47', False, 5),
        'restart': path('M13 25A22 22 0 1 1 13 42M12 11V26H27'),
        'copy': box(23, 21, 29, 34) + path('M16 44H12V9H41V14'),
        'seed': seed,
        'randomize': path('M9 17H17Q23 17 31 32T46 47H55M9 47H17Q23 47 31 32T46 17H55M47 9L55 17L47 25M47 39L55 47L47 55'),
        'difficulty_easy': path('M26 54V11') + path('M27 12H48L42 22L48 32H27Z', True, 2),
        'difficulty_normal': path('M17 54V11M36 54V26') + path('M18 12H39L33 22L39 30H18Z', True, 2) + path('M37 27H54L49 36L54 44H37Z', True, 2),
        'difficulty_hard': path('M11 54V10M28 54V23M45 54V35') + path('M12 11H31L26 20L31 27H12Z', True, 2) + path('M29 24H46L41 32L46 40H29Z', True, 2) + path('M46 36H58V49H46Z', True, 2),
        'dark': path('M44 10A24 24 0 1 0 54 45A25 25 0 0 1 44 10Z', True, 2),
        'light': disc(32, 32, 12, False) + path('M32 7V13M32 51V57M7 32H13M51 32H57M14 14L18 18M46 46L50 50M14 50L18 46M46 18L50 14'),
        'menu': path('M12 17H52M12 32H45M12 47H52', False, 5),
        'help': disc(32, 32, 23, False) + path('M25 24Q25 16 33 16Q46 17 36 29L32 33V37') + disc(32, 45, 2.5),
        'quit': path('M29 10H13V54H29M31 32H54M44 22L54 32L44 42'),
        'chevron_down': path('M14 24L32 42L50 24', False, 5),
        'chevron_up': path('M14 40L32 22L50 40', False, 5),
        'check': path('M13 33L26 46L52 18', False, 5),
        'trophy': path('M18 12H46V29Q46 42 32 43Q18 42 18 29Z', True, 3) + path('M17 18H9V25Q9 34 19 35M47 18H55V25Q55 34 45 35M32 42V53M22 55H42'),
        'star': star,
        'rarity_common': path('M32 12L50 32L32 52L14 32Z'),
        'rarity_rare': path('M22 12H42L54 28L32 53L10 28Z') + path('M11 28H53'),
        'rarity_epic': path('M32 8L53 21V42L32 56L11 42V21Z') + path('M32 20L42 32L32 44L22 32Z', False, 3),
        'rarity_legendary': path('M9 18L22 26L32 9L42 26L55 18L48 43L32 56L16 43Z') + path('M17 42H47'),
        'power_club': club + disc(48, 45, 7, False) + path('M48 29V33M58 36L55 38', False, 3),
        'overdrive_driver': club + path('M45 25L36 38H46L40 55L57 34H46Z', True, 2),
        'rangefinder_lens': target + path('M32 7V19M32 45V57M7 32H19M45 32H57'),
        'coin_magnet': magnet,
        'sand_cleats': boot,
        'heavy_core': disc(32, 32, 22, False) + disc(32, 32, 11),
        'gust_guard': shield + path('M21 25H36Q44 25 40 20M19 35H39M24 42H31', False, 3 if not small else 4),
        'lucky_putter': path('M20 11V44H45V52H13V44H20') + punched('M41 12C42 3 55 7 50 16C61 16 57 29 49 24C48 35 36 31 41 24C30 23 32 12 41 12Z', circle_path(45, 19, 2.5)),
        'missing': box(10, 10, 44, 44) + path('M20 20L44 44M44 20L20 44'),
    }
    if small:
        result['sand'] = path('M9 36Q19 20 32 34Q44 43 55 27M10 51Q27 37 50 51')
        result['water'] = path('M11 41Q21 32 32 41T54 41M11 53Q21 44 32 53T54 53') + path('M32 9Q17 27 32 28Q47 27 32 9Z', True, 2)
        result['blocker'] = box(9, 14, 46, 38) + path('M10 32H54M31 15V31M31 33V51')
        result['gust_guard'] = shield + path('M23 25H40M20 36H37')
        result['power_club'] = club + disc(48, 45, 7, False)
    return result


ALIASES = {
    'strokes': 'stroke', 'club': 'stroke', 'coins': 'coin', 'bonus': 'benefit',
    'cards': 'card', 'control': 'trajectory', 'target': 'rangefinder_lens',
    'difficulty': 'difficulty_normal', 'tutorial': 'help', 'score_good': 'star',
    'score_bad': 'curse', 'replay': 'restart', 'wall': 'blocker',
    'moving_hazard': 'pendulum', 'spike_ball': 'pendulum', 'copy_seed': 'copy',
    'risk': 'warning', 'reward': 'star',
}


def svg(body: str, width: int = 256, height: int | None = None,
        viewbox: str = '0 0 64 64') -> str:
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" '
            f'height="{height or width}" viewBox="{viewbox}">\n{body}\n</svg>\n')


def wordmark() -> str:
    """Fredoka outlines, two ball-Os, and an outward U-shaped club swing."""
    font = TTFont(ROOT / 'assets/fonts/Fredoka-Bold.ttf')
    glyph_set, cmap = font.getGlyphSet(), font.getBestCmap()
    upem = font['head'].unitsPerEm
    body: list[str] = []
    rows = [('A STROKE', 118, 22, 137, PAPER), ('OF LUCK', 177, 12, 291, GOLD)]
    for text, size, origin, baseline, paint in rows:
        scale = size / upem
        x = float(origin)
        for index, char in enumerate(text):
            glyph = glyph_set[cmap[ord(char)]]
            advance = glyph.width * scale
            if char == 'O':
                # Ball replaces the O glyph, sharing its cap-height and advance.
                center, radius = (x + advance / 2, baseline - size * .34), size * .34
                ball_shape = circle_path(*center, radius)
                holes = dimples(*center, radius)
                body.append(punched(ball_shape, holes).replace(WHITE, paint))
                body.append(f'<path d="M{center[0]-radius*.69:.3f} {center[1]-radius*.32:.3f}Q{center[0]-radius*.35:.3f} {center[1]-radius*.82:.3f} {center[0]+radius*.17:.3f} {center[1]-radius*.76:.3f}" fill="none" stroke="{INK}" stroke-opacity=".18" stroke-width="3" stroke-linecap="round"/>')
            elif text == 'OF LUCK' and char == 'U':
                # The letter IS the swing, ending in a club head on the outward
                # right stroke. No extra flag pasted beside an ordinary glyph.
                left, right, top = x + advance*.20, x + advance*.81, baseline-size*.63
                bottom = baseline-size*.10
                body.append(f'<path d="M{left:.3f} {top:.3f}V{bottom-28:.3f}Q{left:.3f} {baseline+3:.3f} {x+advance*.51:.3f} {baseline+3:.3f}Q{right:.3f} {baseline+3:.3f} {right:.3f} {bottom-28:.3f}V{top:.3f}" fill="none" stroke="{paint}" stroke-width="26" stroke-linecap="round"/>')
                body.append(f'<path d="M{left-18:.3f} {top+29:.3f}Q{left-20:.3f} {baseline+22:.3f} {x+advance*.51:.3f} {baseline+23:.3f}Q{right+18:.3f} {baseline+23:.3f} {right+18:.3f} {top+28:.3f}" fill="none" stroke="{paint}" stroke-width="3" stroke-linecap="round"/>')
                body.append(f'<path d="M{right-13:.3f} {top+8:.3f}l-4 -18 28 -6 7 17 -16 12Z" fill="{PAPER}" stroke="{paint}" stroke-width="3" stroke-linejoin="round"/>')
                body.append(f'<path d="M{right-7:.3f} {top-8:.3f}l17 -4M{right-5:.3f} {top-2:.3f}l17 -4" stroke="{INK}" stroke-opacity=".4" stroke-width="2"/>')
            else:
                pen = SVGPathPen(glyph_set, ntos=lambda number: f'{number:.3f}'.rstrip('0').rstrip('.') or '0')
                glyph.draw(TransformPen(pen, (scale, 0, 0, -scale, x, baseline)))
                body.append(f'<path d="{pen.getCommands()}" fill="{paint}"/>')
            # Deliberate optical spacing, not random per-letter rotation.
            x += advance + (0 if char == ' ' else 1.5)
    # A single clipped card corner anchors the wordmark; no surrounding stickers.
    body.append(f'<path d="M20 325H653L687 306V342H20Z" fill="{GOLD}"/>')
    body.append(f'<path d="M24 329H646M666 318V334H679" fill="none" stroke="{INK}" stroke-opacity=".5" stroke-width="2"/>')
    body.append(f'<path d="M41 330L46 334L41 338L36 334Z" fill="{INK}"/>')
    font.close()
    return svg('\n'.join(body), 1580, 720, '0 0 790 360')


def emblem(small: bool = False) -> str:
    card = f'<path d="M13 5H43L57 19V55Q57 59 53 59H13Q7 59 7 53V11Q7 5 13 5Z" fill="{INK}"/>'
    card += f'<path d="M43 5V19H57" fill="{GOLD}"/>'
    holes = '' if small else dimples(32, 33, 16)
    card += punched(circle_path(32, 33, 16), holes).replace(WHITE, PAPER)
    card += f'<path d="M22 54H43" stroke="{GOLD}" stroke-width="3" stroke-linecap="round"/>'
    return svg(card)


def catalog_source(names: list[str]) -> str:
    ids = ',\n\t'.join(f'&"{name}"' for name in names)
    aliases = ',\n\t'.join(f'&"{key}": &"{value}"' for key, value in ALIASES.items())
    return f'''class_name IconCatalog
extends RefCounted
## Generated by tools/build_brand_assets.py. Semantic glyphs and original card art.

const IDS: Array[StringName] = [
\t{ids},
]
const ALIASES := {{
\t{aliases},
}}
const ROOT := "res://assets/ui/icons/"
const CARD_ROOT := "res://assets/presentation/cards/"
const CARD_IDS: Array[StringName] = [
\t&"overdrive_driver", &"rangefinder_lens", &"sand_cleats", &"heavy_core",
\t&"lucky_putter", &"power_club", &"coin_magnet", &"gust_guard",
]
const CARD_ALIASES := {{
\t&"tutorial_training_driver": &"overdrive_driver",
\t&"tutorial_sand_shoes": &"sand_cleats",
\t&"tutorial_pocket_change": &"coin_magnet",
\t&"tutorial_steady_grip": &"rangefinder_lens",
}}
static var _card_textures: Dictionary = {{}}

static func canonical(id: StringName) -> StringName:
\treturn CARD_ALIASES.get(id, ALIASES.get(id, id))

static func has_icon(id: StringName) -> bool:
\treturn canonical(id) in IDS

static func asset_path(id: StringName, small := false) -> String:
\tvar resolved := canonical(id)
\tif has_card_art(resolved):
\t\treturn card_asset_path(resolved)
\tif resolved not in IDS:
\t\tresolved = &"missing"
\treturn ROOT + "icon_%s%s.svg" % [resolved, "_small" if small else ""]

static func texture(id: StringName, small := false) -> Texture2D:
\tif has_card_art(id):
\t\treturn card_texture(id)
\t# The drawing control retains this reference for the lifetime of its draw RID.
\treturn load(asset_path(id, small)) as Texture2D

static func has_card_art(id: StringName) -> bool:
\treturn canonical(id) in CARD_IDS

static func card_asset_path(id: StringName) -> String:
\tvar resolved := canonical(id)
\treturn CARD_ROOT + String(resolved) + ".png" if resolved in CARD_IDS else ""

static func card_texture(id: StringName) -> Texture2D:
\tvar resolved := canonical(id)
\tif resolved not in CARD_IDS:
\t\treturn null
\t# ResourceLoader caches weakly. Keep a bounded strong reference to each of the
\t# eight sprites so a texture loaded in _draw survives until the renderer uses it.
\tif not _card_textures.has(resolved):
\t\tvar loaded := load(card_asset_path(resolved)) as Texture2D
\t\tif loaded:
\t\t\t_card_textures[resolved] = loaded
\treturn _card_textures.get(resolved) as Texture2D
'''


def outputs() -> dict[Path, str]:
    files: dict[Path, str] = {}
    regular = glyphs(False)
    for small in [False, True]:
        for name, body in glyphs(small).items():
            suffix = '_small' if small else ''
            files[ROOT / f'assets/ui/icons/icon_{name}{suffix}.svg'] = svg(body, 64 if small else 256)
    files[ROOT / 'scripts/ui/icon_catalog.gd'] = catalog_source(list(regular))
    files[ROOT / 'assets/ui/brand/wordmark.svg'] = wordmark()
    files[ROOT / 'assets/ui/brand/wordmark_light.svg'] = wordmark().replace(PAPER, INK).replace(GOLD, '#' + PALETTE['GOLD_DARK']).replace(CORAL, '#' + PALETTE['CURSE_DARK'])
    files[ROOT / 'assets/ui/brand/emblem.svg'] = emblem()
    files[ROOT / 'assets/ui/brand/emblem_small.svg'] = emblem(True)
    files[ROOT / 'assets/icon.svg'] = emblem()
    # These three stable Theme paths stay put. The tick is the same canonical path.
    for enabled in [False, True]:
        fill = '#' + PALETTE['BONUS'] if enabled else PAPER
        ink = INK
        body = f'<rect x="2" y="2" width="58" height="28" rx="4" fill="{fill}" stroke="{ink}" stroke-width="3"/>'
        body += f'<rect x="{36 if enabled else 6}" y="6" width="20" height="20" rx="3" fill="{ink}"/>'
        symbol = glyphs(True)['check'] if enabled else path('M16 32H48')
        body += f'<g transform="translate({5 if enabled else 33},3) scale(.40)">{symbol.replace(WHITE, ink)}</g>'
        files[ROOT / f'assets/ui/toggle_{"on" if enabled else "off"}.svg'] = svg(body, 62, 32, '0 0 62 32')
    grip = f'<rect x="3" y="3" width="22" height="22" rx="4" fill="{GOLD}" stroke="{INK}" stroke-width="3"/>'
    grip += f'<path d="M11 10V18M17 10V18" stroke="{INK}" stroke-width="2" stroke-linecap="round"/>'
    files[ROOT / 'assets/ui/slider_knob.svg'] = svg(grip, 28, 28, '0 0 28 28')
    # Native OptionButton/PopupMenu furniture uses this family too, at native
    # pixel dimensions so the Theme cannot accidentally inflate a control.
    for name, body in {
        'dropdown': glyphs(True)['chevron_down'],
        'radio_checked': glyphs(True)['par'],
        'radio_unchecked': disc(32, 32, 19, False),
    }.items():
        files[ROOT / f'assets/ui/theme/{name}.svg'] = svg(body, 16)
    return files


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='Read-only source/output parity check')
    args = parser.parse_args()
    files = outputs()
    mismatches = []
    for destination, content in files.items():
        if destination.suffix == '.svg':
            ElementTree.fromstring(content)
        if args.check:
            if not destination.exists() or destination.read_text(encoding='utf-8') != content:
                mismatches.append(str(destination.relative_to(ROOT)))
        else:
            destination.parent.mkdir(parents=True, exist_ok=True)
            if not destination.exists() or destination.read_text(encoding='utf-8') != content:
                destination.write_text(content, encoding='utf-8', newline='\n')
    if mismatches:
        print('STALE BRAND OUTPUTS:\n' + '\n'.join(mismatches))
        return 1
    print(f'BRAND {"CHECK" if args.check else "BUILD"} PASS: {len(glyphs(False))} glyphs, two tiers; {len(files)} deterministic vector/catalog outputs.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
