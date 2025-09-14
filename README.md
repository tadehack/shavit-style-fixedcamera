# Shavit Tank Controls CS:S Bhop Style

A SourceMod plugin that adds 90's-inspired tank controls to shavit's Counter-Strike: Source bhop timer with fixed third-person camera rotation.

## Features

- **Third-person camera** with 4-way rotation (behind/left/front/right)
- **Automatic binded controls**: E/Shift keys rotate camera
- **Manual commands**: `tcright`/`tcleft` for precise control
- **Toggle system**: Switch between auto and manual modes
- **Shavit integration**: Seamless timer system integration

## Installation

1. **Compile**: `spcomp -iinclude shavit-style-metalgear.sp`
2. **Install**: Place `.smx` file in `addons/sourcemod/plugins/`
3. **Configure**: Add style with `"specialstring" "tcontrols"` to Shavit config
4. **Restart server**

## Commands & Controls

| Command | Key | Description |
|---------|-----|-------------|
 `+use` | **E** | Rotate camera right
 `+speed` | **Shift** | Rotate camera left
 `tcright` | - | Rotate camera right |
| `tcleft` | - | Rotate camera left |
| `toggletckeys` | - | Toggle auto-binded rotation on/off |

## Usage

1. Select **Tank Controls** style in `!style` menu
2. Camera switches to third-person automatically
3. Use **E/Shift** or manual commands to rotate
4. Use `toggletckeys` to switch between auto/manual modes

## Requirements

- SourceMod 1.10+
- Shavit Timer
- Counter-Strike: Source

## Troubleshooting

- **Camera not activating**: Check style has `"specialstring" "tcontrols"`

- **Keys not working**: Use `toggletckeys` or try manual commands

- **Can't switch weapons**: This is due to the third-person implementation that uses the Spectator Camera to simulate third-person, unless the camera implementation is changed, this can't be fixed.

---