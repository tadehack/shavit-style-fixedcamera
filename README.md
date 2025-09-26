<div align="center">
  <h1><code>Shavit Fixed Camera</code></h1>
  <p>
    <strong>90's-inspired fixed camera style for shavit's CS:S bhop timer including camera rotation system and more</strong>
  </p>
</div>

---

## Features

- **Fixed camera** with 4-way rotation (behind/left/front/right) with diagonal camera angles mode included
- **Automatic binds**: Shift / E keys are binded automatically to rotate the camera (toggleable)
- **Manual binds**: If you don't like the default keybinds you can bind `fcleft` / `fcright` to any key you want to rotate the camera
- **Interactive settings menu**: Change FOV, toggle binds and night vision directly in the menu
- **Shavit integration**: Seamless with shavit's timer

## Installation

> **⚠️ IMPORTANT NOTICE:**  
> Add `bash_bypass` to your Fixed Camera style's specialstrings to avoid Bash warnings:
> ```
> "specialstring" "fixedcamera; bash_bypass"
> ```

1. **Compile**: `spcomp -include shavit-style-fixedcamera.sp` (or download the compiled plugin directly from the [releases](https://github.com/NSchrot/shavit-style-fixedcamera/releases) page)
2. **Install**: Place the compiled `.smx` in `addons/sourcemod/plugins/`
3. **Configure**: Add your style with `"specialstring" "fixedcamera"` in your shavit-styles.cfg
4. **Restart your server**

## Commands & Controls

| Command         | Key/Usage     | Description                              |
|-----------------|---------------|------------------------------------------|
| `/fcmenu`       | -             | Open the Fixed Camera settings menu      |
| `/fccommands`   | -             | Show all Fixed Camera commands           |
| `/fchelp`       | -             | Alias for `/fccommands`                  |
| `/fcdiagonal`   | -             | Toggle diagonal camera angle             |
| `/fctogglebinds`| -             | Toggle auto-binded rotation On/Off       |
| `/fcnvg`        | -             | Toggle night vision                      |
| `/fcfov <val>`  | -             | Set camera FOV (80-120)                  |
| `fcleft`        | -             | Rotate camera left                       |
| `fcright`       | -             | Rotate camera right                      |
| `+speed`        | **Shift**     | Rotate camera left (if enabled)          |
| `+use`          | **E**         | Rotate camera right (if enabled)         |


## Usage

1. Select **Fixed Camera** style in the `!style` menu
2. Camera switches to third-person automatically
3. Use **Shift/E** or manual commands to rotate the camera
4. Use `/fcmenu` for all settings (FOV, binds, night vision, etc)
5. Use `/fchelp` for a quick in-game reference of all commands

## Menu System

- **Settings Menu**:  
  - Toggle Shift/E binds  
  - Toggle night vision  
  - Adjust FOV (80-120)  
  - Access commands

- **Commands Menu**:  
  - Shows all available commands  
  - Accessible via `/fchelp` or `/fccommands`


## Configuration Example

Add to your `shavit-styles.cfg`:

```json
"FixedCamera"
{
    "name"              "Fixed Camera"
    "shortname"         "FC"
    "htmlcolor"         "FFFFFF"
    "specialstring"     "fixedcamera"
    // ... other style settings
}
```

## ConVars

| ConVar                          | Default       | Description                        |
|---------------------------------|---------------|------------------------------------|
| `ss_fixedcamera_specialstring`  | `fixedcamera` | Special string for style detection |

## Requirements

- SourceMod 1.10+
- Shavit Timer
- Counter-Strike: Source
- SDKHooks extension
- ClientPrefs extension

## Troubleshooting

- **Camera not activating**:  
  Ensure your style has `"specialstring" "fixedcamera"` in the Shavit config.

- **Keys not working**:  
  Use `/fctogglebinds` or try manual commands (`fcright`, `fcleft`).

- **Can't switch weapons**:  
  This is a limitation of the third-person implementation, which uses the Spectator Camera. Unless the camera system is somehow changed, this can't be fixed.


---

