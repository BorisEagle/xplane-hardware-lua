# X-Plane Hardware Lua

FlyWithLua scripts that improve physical cockpit hardware integration in
X-Plane 12. The scripts target the Zibo 737-800 and supported cockpit hardware.

## Available scripts

### WINCTRL 3N PDC L MINS acceleration

[`scripts/winwing/winctrl_pdc_l_mins.lua`](scripts/winwing/winctrl_pdc_l_mins.lua)
adds progressive acceleration to the captain-side MINS knob.

The script handles both fine adjustment and staged acceleration itself,
including on Linux without SimAppPro.

| Hold time | Behaviour |
| --- | --- |
| On press | One immediate 1 ft step |
| Less than 0.30 seconds | No additional movement |
| 0.30–1.50 seconds | 10 ft steps every 0.18 seconds |
| At least 1.50 seconds | 100 ft steps every 0.20 seconds |

Movement stops immediately when the knob is released. The script writes exact
increments to Zibo's captain MINS dataref, avoiding oversized or
frame-rate-dependent jumps from the native FAST command.

### Saitek AV8R-01 position lights

[`scripts/saitek/av8r_zibo_position_lights.lua`](scripts/saitek/av8r_zibo_position_lights.lua)
maps the joystick's maintained OFF/A/B switch to the Zibo position-light
switch. Buttons 12 and 13 continue to select Steady and Strobe directly; the
script selects Off once when both buttons are released.

## Requirements

- X-Plane 12
- Zibo 737-800
- FlyWithLua NG
- Supported hardware for the selected script

## Installation

1. Download the required `.lua` file from the [`scripts`](scripts) directory.
2. Copy it to:

   ```text
   X-Plane 12/Resources/plugins/FlyWithLua/Scripts/
   ```

3. Start X-Plane 12 and load the Zibo 737-800.

## WINCTRL 3N PDC L configuration

SimAppPro is not required. Keep the Linux WINCTRL plugin installed for the
other panel functions.

In X-Plane's joystick settings, assign the two physical MINS direction buttons
(buttons 40 and 42) to the matching commands:

| Physical direction | X-Plane command |
| --- | --- |
| MINS increase | `PDC_L/EFIS/MINS_UP_ACCEL` |
| MINS decrease | `PDC_L/EFIS/MINS_DOWN_ACCEL` |

The Linux [WINCTRL plugin](https://github.com/BorisEagle/winctrl-xplane-plugin)
skips its own handling for buttons assigned in X-Plane, so Lua owns both the
initial step and acceleration. Keep only one copy of this script loaded.
On Windows, disable any parallel SimAppPro MINS mapping to avoid duplicate
movement.

This fix retains the existing direct-dataref behaviour; it does not implement
the plugin's recovery of the last MINS value after RST/unset.

## Saitek AV8R-01 configuration

In X-Plane's joystick settings, keep the maintained switch buttons assigned
directly to the Zibo commands:

| Physical position | Button state | X-Plane command |
| --- | --- | --- |
| OFF | Neither pressed | Supplied by the Lua script |
| A | Button 12 pressed | Position Light Switch Steady |
| B | Button 13 pressed | Position Light Switch Strobe |

The script sends `laminar/B738/toggle_switch/position_light_off` once when the
switch enters OFF. If FlyWithLua reports different global button numbers,
change `STEADY_BUTTON` and `STROBE_BUTTON` near the top of the script.

## WINCTRL tuning

Acceleration timing and step sizes are defined near the top of the script:

```lua
medium_after = 0.30
fast_after   = 1.50
medium_step  = 10
fast_step    = 100
```

The acceleration timings were previously tested with the Zibo 737-800 and
WINCTRL 3N PDC L. The standalone initial-step fix is checked with a Lua test
harness; in-simulator verification is still required.

## Related project

The separate [`improvedTCA`](https://github.com/BorisEagle/improvedTCA) fork is
kept for Thrustmaster Boeing TCA integration and upstream compatibility.

## License

This project is licensed under the [MIT License](LICENSE).
