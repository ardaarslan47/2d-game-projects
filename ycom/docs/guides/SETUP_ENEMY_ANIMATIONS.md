# Enemy Animation Setup Instructions

## Enemy Assets Downloaded
Location: `assets/enemy/`

Available animations:
- **south** (6 frames)
- **west** (6 frames)
- **south-west** (6 frames)
- **north-west** (6 frames)

## Setup in Godot Editor

### 1. Open the Enemy Scene
- Open `scenes/characters/enemy.tscn` in Godot

### 2. Configure AnimatedSprite2D
1. Select the `walk_animation` node (AnimatedSprite2D)
2. In the Inspector, find **Sprite Frames** property
3. Click **[empty]** and select **New SpriteFrames**
4. Click on the SpriteFrames resource to open the bottom panel

### 3. Add Animations

#### For SOUTH direction:
1. In SpriteFrames panel, click "New Animation"
2. Rename it to: `south`
3. Set FPS to: `5`
4. Drag all 6 frames from `assets/enemy/animations/walking/south/` into the animation
   - frame_000.png through frame_005.png

#### For WEST direction:
1. Click "New Animation" again
2. Rename to: `west`
3. Set FPS to: `5`
4. Drag all 6 frames from `assets/enemy/animations/walking/west/`

#### For SOUTH-WEST direction:
1. Click "New Animation"
2. Rename to: `south-west`
3. Set FPS to: `5`
4. Drag all 6 frames from `assets/enemy/animations/walking/south-west/`

#### For NORTH-WEST direction:
1. Click "New Animation"
2. Rename to: `north-west`
3. Set FPS to: `5`
4. Drag all 6 frames from `assets/enemy/animations/walking/north-west/`

### 4. Save Everything
- Press Ctrl+S (Cmd+S on Mac) to save the scene
- The enemy will now have animated walking in 4 directions!

## Note About Missing Directions
The enemy script handles missing directions by using the closest available:
- **east**, **south-east**, **north**, **north-east** → Will use closest available direction

If you want full 8-direction support, you can retry generating the missing animations later.

## Test the Game
Run the game (F5) and:
1. Click tiles to move your player
2. Click "End Turn" button
3. Watch the enemy pathfind toward you with animated walking!
4. Enemy will use 2 AP to move, then turn ends
5. Your turn starts again with full 2 AP

## Turn System Features Working
✅ Player gets 2 AP per turn
✅ Movement costs 1 AP
✅ Visual range indicators (blue tiles)
✅ End Turn button
✅ Enemy AI pathfinds to player
✅ Enemy moves during its turn
✅ AP automatically resets each turn
✅ Turn order: Player → Enemy → Player (repeats)
