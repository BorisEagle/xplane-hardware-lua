-- TCA Boeing four-lever throttle averaging for the Zibo 737-800.
-- Version 1.0.1
-- Copyright (c) 2026 Borys Nechypor
-- SPDX-License-Identifier: MIT
--
-- X-Plane assignments:
--   Quadrant Boeing 1&2 left lever  -> Throttle 1
--   Quadrant Boeing 1&2 right lever -> Throttle 2
--   Quadrant Boeing 3&4 left lever  -> Throttle 3
--   Quadrant Boeing 3&4 right lever -> Throttle 4
--
-- The first pair is averaged into Zibo engine 1 and the second pair into
-- Zibo engine 2. This replaces the old Joystick Gremlin + vJoy mapping.

local aircraft_path = string.lower(AIRCRAFT_PATH or "")
local is_zibo_737 = PLANE_ICAO == "B738" and (
    string.find(aircraft_path, "800x", 1, true) ~= nil or
    string.find(aircraft_path, "zibo", 1, true) ~= nil
)

-- Aircraft changes force a FlyWithLua script reload. Avoid binding Zibo-only
-- datarefs in other aircraft (including the Laminar B738).
if not is_zibo_737 then
    logMsg("TCA throttle averaging: inactive outside the Zibo 737-800.")
    return
end

local THROTTLE_1 = 20
local THROTTLE_2 = 21
local THROTTLE_3 = 22
local THROTTLE_4 = 23
local THROTTLE_ASSIGNMENTS = {
    THROTTLE_1,
    THROTTLE_2,
    THROTTLE_3,
    THROTTLE_4,
}
local FIRST_PHYSICAL_AXIS = 0
local LAST_PHYSICAL_AXIS = 499
local AXIS_RESCAN_INTERVAL_FRAMES = 60

local joystick_axis_assignments =
    dataref_table("sim/joystick/joystick_axis_assignments")
local joystick_axis_values = dataref_table("sim/joystick/joystick_axis_values")
local joystick_axis_reverse = dataref_table("sim/joystick/joystick_axis_reverse")

dataref("zibo_avg_thr1", "laminar/B738/axis/throttle1", "writable")
dataref("zibo_avg_thr2", "laminar/B738/axis/throttle2", "writable")
dataref("zibo_avg_override", "laminar/B738/throttle_override", "writable")

local function clamp_throttle(value)
    if value < 0 then
        return 0
    end

    if value > 1 then
        return 1
    end

    return value
end

local function axis_value_is_valid(value)
    return type(value) == "number" and
        value == value and -- NaN is the only Lua number not equal to itself.
        math.abs(value + 0.01) > 0.000001 -- X-Plane's dead-axis marker.
end

local throttle_axes = {}
local frames_until_axis_rescan = 0
local last_axis_log_signature = nil

local function cached_assignments_are_complete()
    for _, assignment in ipairs(THROTTLE_ASSIGNMENTS) do
        local index = throttle_axes[assignment]

        if index == nil or joystick_axis_assignments[index] ~= assignment then
            return false
        end
    end

    return true
end

local function log_axis_discovery()
    local slots = {}
    local missing = {}

    for _, assignment in ipairs(THROTTLE_ASSIGNMENTS) do
        local index = throttle_axes[assignment]
        slots[#slots + 1] = tostring(index)

        if index == nil then
            missing[#missing + 1] = tostring(assignment - THROTTLE_1 + 1)
        end
    end

    local signature = table.concat(slots, ",")
    if signature == last_axis_log_signature then
        return
    end

    last_axis_log_signature = signature
    if #missing == 0 then
        logMsg(
            "TCA throttle averaging: Throttle 1, 2, 3 and 4 use " ..
            "physical axis slots " .. table.concat(slots, ", ") .. "."
        )
    else
        logMsg(
            "TCA throttle averaging: waiting for X-Plane assignment(s) " ..
            "Throttle " .. table.concat(missing, ", ") .. "."
        )
    end
end

local function discover_throttle_axes()
    local discovered = {}
    local pending = {}

    -- These X-Plane datarefs contain exactly 500 zero-based physical slots.
    -- Do not probe beyond them: FlyWithLua does not check the element count
    -- returned by XPLMGetDatavf/XPLMGetDatavi for an array read.
    for index = FIRST_PHYSICAL_AXIS, LAST_PHYSICAL_AXIS do
        local assignment = joystick_axis_assignments[index]

        if type(assignment) == "number" and
            assignment >= THROTTLE_1 and assignment <= THROTTLE_4 and
            discovered[assignment] == nil then
            if axis_value_is_valid(joystick_axis_values[index]) then
                discovered[assignment] = index
            elseif pending[assignment] == nil then
                -- A freshly loaded axis can briefly report -0.01 before its
                -- first poll. Remember its slot and validate it per frame.
                pending[assignment] = index
            end
        end
    end

    for _, assignment in ipairs(THROTTLE_ASSIGNMENTS) do
        throttle_axes[assignment] = discovered[assignment] or pending[assignment]
    end

    if cached_assignments_are_complete() then
        frames_until_axis_rescan = 0
    else
        frames_until_axis_rescan = AXIS_RESCAN_INTERVAL_FRAMES
    end

    log_axis_discovery()
end

local function ensure_throttle_axes_are_assigned()
    if cached_assignments_are_complete() then
        return true
    end

    if frames_until_axis_rescan <= 0 then
        discover_throttle_axes()
    else
        frames_until_axis_rescan = frames_until_axis_rescan - 1
    end

    return cached_assignments_are_complete()
end

local function read_throttle_axis(assignment)
    local index = throttle_axes[assignment]

    if index == nil or joystick_axis_assignments[index] ~= assignment then
        return nil
    end

    local value = joystick_axis_values[index]
    if not axis_value_is_valid(value) then
        return nil
    end

    if joystick_axis_reverse[index] == 1 then
        value = 1 - value
    end

    return clamp_throttle(value)
end

function tca_release_throttle_override()
    zibo_avg_override = 0
end

function tca_update_throttle_average()
    if not ensure_throttle_axes_are_assigned() then
        tca_release_throttle_override()
        return
    end

    local throttle_1 = read_throttle_axis(THROTTLE_1)
    local throttle_2 = read_throttle_axis(THROTTLE_2)
    local throttle_3 = read_throttle_axis(THROTTLE_3)
    local throttle_4 = read_throttle_axis(THROTTLE_4)

    if throttle_1 == nil or throttle_2 == nil or
        throttle_3 == nil or throttle_4 == nil then
        tca_release_throttle_override()
        return
    end

    local engine_1 = (throttle_1 + throttle_2) / 2
    local engine_2 = (throttle_3 + throttle_4) / 2

    -- Write valid positions before taking control, preventing a one-frame jump
    -- when all four physical axes first become available.
    zibo_avg_thr1 = engine_1
    zibo_avg_thr2 = engine_2
    zibo_avg_override = 1
end

discover_throttle_axes()

do_every_frame("tca_update_throttle_average()")
do_on_exit("tca_release_throttle_override()")
