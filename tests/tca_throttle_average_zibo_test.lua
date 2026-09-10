-- Run from the repository root:
-- lua tests/tca_throttle_average_zibo_test.lua
-- FlyWithLua boundary stubs; exercises the registered frame and exit callbacks.

local mapped_axis_values = {}
local mapped_axis_available = {}
local registered_frame_callback = nil
local registered_exit_callback = nil

PLANE_ICAO = "B738"
AIRCRAFT_PATH = "/Aircraft/B737-800X/"

function dataref_table(path)
    if path == "sim/joystick/joy_mapped_axis_value" then
        return mapped_axis_values
    end

    if path == "sim/joystick/joy_mapped_axis_avail" then
        return mapped_axis_available
    end

    error("unexpected dataref table: " .. path)
end

function dataref(variable, path, access)
    local expected = {
        zibo_avg_thr1 = "laminar/B738/axis/throttle1",
        zibo_avg_thr2 = "laminar/B738/axis/throttle2",
        zibo_avg_override = "laminar/B738/throttle_override",
    }

    assert(expected[variable] == path, "unexpected scalar dataref: " .. path)
    assert(access == "writable", path .. " must be writable")
    _G[variable] = 0
end

function do_every_frame(callback)
    registered_frame_callback = callback
end

function do_on_exit(callback)
    registered_exit_callback = callback
end

function logMsg(_) end

local function assert_near(actual, expected, message)
    assert(math.abs(actual - expected) < 0.000001, message)
end

local path = (arg and arg[1]) or
    "scripts/thrustmaster/tca_throttle_average_zibo.lua"
dofile(path)

assert(
    registered_frame_callback == "tca_update_mapped_throttle_average()",
    "the averaging handler must run every frame"
)
assert(
    registered_exit_callback == "tca_release_throttle_override()",
    "the Zibo throttle override must be released when the script exits"
)

-- X-Plane joy-use indices: Throttle 1=20, 2=21, 3=22, 4=23.
for index = 20, 23 do
    mapped_axis_available[index] = 1
end

mapped_axis_values[20] = 0.20
mapped_axis_values[21] = 0.60
mapped_axis_values[22] = 0.40
mapped_axis_values[23] = 1.00
tca_update_mapped_throttle_average()

assert(zibo_avg_override == 1, "four available axes must enable the override")
assert_near(zibo_avg_thr1, 0.40, "engine 1 must average Throttle 1 and 2")
assert_near(zibo_avg_thr2, 0.70, "engine 2 must average Throttle 3 and 4")

-- Clamp each physical input before averaging, protecting Zibo from bad values.
mapped_axis_values[20] = -0.50
mapped_axis_values[21] = 1.50
mapped_axis_values[22] = 0.20
mapped_axis_values[23] = 0.60
tca_update_mapped_throttle_average()

assert_near(zibo_avg_thr1, 0.50, "engine 1 inputs must be clamped")
assert_near(zibo_avg_thr2, 0.40, "valid engine 2 inputs must remain unchanged")

-- A corrupt non-number-like value must fail safe instead of reaching Zibo.
mapped_axis_values[20] = 0 / 0
local before_nan_thr1 = zibo_avg_thr1
local before_nan_thr2 = zibo_avg_thr2
tca_update_mapped_throttle_average()

assert(zibo_avg_override == 0, "NaN input must release the override")
assert_near(zibo_avg_thr1, before_nan_thr1, "NaN must not change engine 1")
assert_near(zibo_avg_thr2, before_nan_thr2, "NaN must not change engine 2")

-- If any of the four assignments disappears, release control and keep the
-- last outputs untouched instead of commanding an incomplete throttle pair.
mapped_axis_values[20] = 0.20
mapped_axis_available[22] = 0
local last_thr1 = zibo_avg_thr1
local last_thr2 = zibo_avg_thr2
tca_update_mapped_throttle_average()

assert(zibo_avg_override == 0, "a missing mapped axis must release the override")
assert_near(zibo_avg_thr1, last_thr1, "missing axes must not change engine 1")
assert_near(zibo_avg_thr2, last_thr2, "missing axes must not change engine 2")

zibo_avg_override = 1
tca_release_throttle_override()
assert(zibo_avg_override == 0, "the exit callback must release the override")

print("PASS (" .. _VERSION .. "): averaging, clamping, fail-safe, shutdown")
