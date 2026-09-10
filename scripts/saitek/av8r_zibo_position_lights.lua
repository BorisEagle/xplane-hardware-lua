-- Saitek AV8R-01 three-position switch for Zibo position lights
-- Version 1.0.0
-- Copyright (c) 2026 Borys Nechypor
-- SPDX-License-Identifier: MIT
--
-- Keep these two buttons assigned directly in X-Plane:
--   Button 12: Position Light Switch Steady
--   Button 13: Position Light Switch Strobe
--
-- This script supplies the missing OFF position when neither button is held.

local STEADY_BUTTON = 12
local STROBE_BUTTON = 13
local POSITION_LIGHT_OFF_COMMAND =
    "laminar/B738/toggle_switch/position_light_off"

-- Start false so OFF is sent once after loading when the hardware starts in OFF.
local was_in_off_position = false


function saitek_av8r_update_position_lights()
    local is_in_off_position =
        not button(STEADY_BUTTON) and not button(STROBE_BUTTON)

    if is_in_off_position and not was_in_off_position then
        command_once(POSITION_LIGHT_OFF_COMMAND)
    end

    was_in_off_position = is_in_off_position
end


do_every_frame("saitek_av8r_update_position_lights()")
