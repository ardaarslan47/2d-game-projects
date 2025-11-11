#!/usr/bin/env python3
"""
Generate a simple placeholder tileset for immediate testing.
Creates a 4x4 grid of 32x32 tiles with different colors for terrain types.
"""

try:
    from PIL import Image, ImageDraw
except ImportError:
    print("PIL not installed. Installing...")
    import subprocess
    subprocess.check_call(["pip3", "install", "Pillow"])
    from PIL import Image, ImageDraw

# Tile configuration
TILE_SIZE = 32
GRID_SIZE = 4  # 4x4 = 16 tiles for Wang tileset
TOTAL_SIZE = TILE_SIZE * GRID_SIZE

# Colors
LOWER_COLOR = (60, 60, 70)      # Dark concrete
UPPER_COLOR = (100, 110, 120)   # Lighter metal platform
TRANSITION_COLOR = (80, 85, 95) # Mid-tone transition
OUTLINE_COLOR = (40, 40, 50)    # Dark outline

# Create image
img = Image.new('RGB', (TOTAL_SIZE, TOTAL_SIZE), LOWER_COLOR)
draw = ImageDraw.Draw(img)

# Wang tile patterns (0-15)
# Each tile is determined by its 4 corners (NW, NE, SW, SE)
# 0 = lower terrain, 1 = upper terrain

def get_tile_color(nw, ne, sw, se):
    """Get color based on corner configuration"""
    total = nw + ne + sw + se
    if total == 0:
        return LOWER_COLOR
    elif total == 4:
        return UPPER_COLOR
    else:
        # Blend colors for transition
        ratio = total / 4.0
        r = int(LOWER_COLOR[0] + (UPPER_COLOR[0] - LOWER_COLOR[0]) * ratio)
        g = int(LOWER_COLOR[1] + (UPPER_COLOR[1] - LOWER_COLOR[1]) * ratio)
        b = int(LOWER_COLOR[2] + (UPPER_COLOR[2] - LOWER_COLOR[2]) * ratio)
        return (r, g, b)

# Generate all 16 Wang tiles
for index in range(16):
    # Calculate position in grid
    col = index % 4
    row = index // 4
    x = col * TILE_SIZE
    y = row * TILE_SIZE

    # Decode corner values from index
    nw = (index >> 0) & 1
    ne = (index >> 1) & 1
    sw = (index >> 2) & 1
    se = (index >> 3) & 1

    # Get base color
    base_color = get_tile_color(nw, ne, sw, se)

    # Fill tile with base color
    draw.rectangle([x, y, x + TILE_SIZE - 1, y + TILE_SIZE - 1], fill=base_color)

    # Add corner indicators for easier debugging (optional)
    corner_size = 4
    if nw:
        draw.rectangle([x, y, x + corner_size, y + corner_size], fill=UPPER_COLOR)
    if ne:
        draw.rectangle([x + TILE_SIZE - corner_size, y, x + TILE_SIZE, y + corner_size], fill=UPPER_COLOR)
    if sw:
        draw.rectangle([x, y + TILE_SIZE - corner_size, x + corner_size, y + TILE_SIZE], fill=UPPER_COLOR)
    if se:
        draw.rectangle([x + TILE_SIZE - corner_size, y + TILE_SIZE - corner_size, x + TILE_SIZE, y + TILE_SIZE], fill=UPPER_COLOR)

    # Add grid lines for visibility
    draw.rectangle([x, y, x + TILE_SIZE - 1, y + TILE_SIZE - 1], outline=OUTLINE_COLOR, width=1)

# Save
output_path = "assets/tilesets/placeholder_tactical.png"
img.save(output_path)
print(f"✅ Placeholder tileset created: {output_path}")
print(f"   Size: {TOTAL_SIZE}x{TOTAL_SIZE} ({GRID_SIZE}x{GRID_SIZE} tiles)")
print(f"   Tile size: {TILE_SIZE}x{TILE_SIZE}")
print(f"   Wang tiles: 16")
