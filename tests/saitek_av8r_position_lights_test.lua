-- Run from the repository root:
-- lua tests/saitek_av8r_position_lights_test.lua
-- FlyWithLua boundary stubs; exercises the registered frame callback.

local button_states = {}
local off_command_count = 0
local registered_callback = nil

function button(number)
    return button_states[number] == true
end

function command_once(command)
    assert(
        command == "laminar/B738/toggle_switch/position_light_off",
        "OFF must use the Zibo position-light command"
    )
    off_command_count = off_command_count + 1
end

function do_every_frame(callback)
    registered_callback = callback
end

local path = (arg and arg[1]) or "scripts/saitek/av8r_zibo_position_lights.lua"
dofile(path)

assert(
    registered_callback == "saitek_av8r_update_position_lights()",
    "the switch handler must run every frame"
)

-- Starting in OFF sends one command, not one command per frame.
saitek_av8r_update_position_lights()
assert(off_command_count == 1, "initial OFF must synchronize the Zibo switch")
saitek_av8r_update_position_lights()
assert(off_command_count == 1, "remaining in OFF must not repeat the command")

-- A (steady) does not send OFF; moving A -> OFF sends it once.
button_states[12] = true
saitek_av8r_update_position_lights()
assert(off_command_count == 1, "steady must not send OFF")
button_states[12] = false
saitek_av8r_update_position_lights()
assert(off_command_count == 2, "steady to OFF must send one command")

-- B (strobe) does not send OFF; moving B -> OFF sends it once.
button_states[13] = true
saitek_av8r_update_position_lights()
assert(off_command_count == 2, "strobe must not send OFF")
button_states[13] = false
saitek_av8r_update_position_lights()
assert(off_command_count == 3, "strobe to OFF must send one command")

-- Both pressed cannot occur mechanically, but must not be treated as OFF.
button_states[12] = true
button_states[13] = true
saitek_av8r_update_position_lights()
assert(off_command_count == 3, "both pressed must not send OFF")

print("PASS (" .. _VERSION .. "): initial OFF, steady, strobe, transitions")
