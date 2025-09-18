<div align="center">
  <h1><code>Shavit Tank Controls</code></h1>
  <p>
    <strong>90's-inspired tank controls for shavit's CS:S bhop timer with fixed third-person camera rotation</strong>
  </p>
</div>

---

## Features

- **Third-person camera** with 4-way rotation (behind/left/front/right)
- **Automatic binds**: E/Shift keys rotate camera (toggleable)
- **Manual commands**: If you don't like the default keybinds you can bind `tcleft` / `tcright` to any button you want to rotate the camera
- **Interactive settings menu**: Change FOV, toggle binds and night vision directly in the menu
- **Quick commands**: All commands accessible in-game
- **Shavit integration**: Seamless with shavit-timer system

## Installation

> **⚠️ IMPORTANT NOTICE:**  
> Add `bash_bypass` to your Tank Controls style specialstring to avoid Bash warnings/bans:
> ```
> "specialstring" "tcontrols; bash_bypass"
> ```

1. **Compile**: `spcomp -include shavit-style-tankcontrols.sp`
2. **Install**: Place the compiled `.smx` in `addons/sourcemod/plugins/`
3. **Configure**: Add your style with `"specialstring" "tcontrols"` in your Shavit config
4. **Restart your server**

## Commands & Controls

| Command         | Key/Usage      | Description                              |
|-----------------|---------------|------------------------------------------|
| `/tcmenu`       | -             | Open the Tank Controls settings menu     |
| `/tcsettings`   | -             | Alias for `/tcmenu`                      |
| `/tcoptions`    | -             | Alias for `/tcmenu`                      |
| `/tccommands`   | -             | Show all Tank Controls commands     |
| `/tchelp`       | -             | Alias for `/tccommands`                  |
| `/tcfov <val>`  | -             | Set camera FOV (80-120)                  |
| `/tcnvg`        | -             | Toggle night vision                      |
| `tcright`       | -             | Rotate camera right                      |
| `tcleft`        | -             | Rotate camera left                       |
| `toggletckeys`  | -             | Toggle auto-binded rotation on/off       |
| `+speed`        | **Shift**     | Rotate camera left (if enabled)          |
| `+use`          | **E**         | Rotate camera right (if enabled)         |


## Usage

1. Select **Tank Controls** style in the `!style` menu
2. Camera switches to third-person automatically
3. Use **Shift/E** or manual commands to rotate the camera
4. Use `/tcmenu` for all settings (FOV, binds, night vision, etc.)
5. Use `/tchelp` for a quick in-game reference of all commands

## Menu System

- **Settings Menu**:  
  - Toggle Shift/E binds  
  - Toggle night vision  
  - Adjust FOV (80-120)  
  - Access commands

- **Commands Menu**:  
  - Shows all available commands  
  - Accessible via `/tchelp` or `/tccommands`


## Configuration Example

Add to your `shavit-styles.cfg`:

```json
"TankControls"
{
    "name"              "Tank Controls"
    "shortname"         "TANK"
    "htmlcolor"         "FFFFFF"
    "specialstring"     "tcontrols"
    // ... other style settings
}
```

## ConVars

| ConVar                        | Default       | Description                    |
|-------------------------------|---------------|--------------------------------|
| `ss_tankcontrols_specialstring` | `tcontrols` | Special string for style detection |

## Requirements

- SourceMod 1.10+
- Shavit Timer
- Counter-Strike: Source
- SDKHooks extension
- ClientPrefs extension

## Troubleshooting

- **Camera not activating**:  
  Ensure your style has `"specialstring" "tcontrols"` in the Shavit config.

- **Keys not working**:  
  Use `/toggletckeys` or try manual commands (`tcright`, `tcleft`).

- **Can't switch weapons**:  
  This is a limitation of the third-person implementation, which uses the Spectator Camera. Unless the camera system is changed, this can't be fixed.


---
