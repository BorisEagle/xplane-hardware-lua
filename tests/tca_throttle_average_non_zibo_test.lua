-- Run from the repository root:
-- lua tests/tca_throttle_average_non_zibo_test.lua
-- The Zibo-only script must stay inert for every other aircraft.

PLANE_ICAO = "C172"
AIRCRAFT_PATH = "/Aircraft/Laminar Research/Cessna 172 SP/"

function dataref_table(path)
    error("non-Zibo load must not bind dataref table: " .. path)
end

function dataref(_, path, _)
    error("non-Zibo load must not bind dataref: " .. path)
end

function do_every_frame(_)
    error("non-Zibo load must not register a frame callback")
end

function do_on_exit(_)
    error("non-Zibo load must not register an exit callback")
end

function logMsg(_) end

local path = (arg and arg[1]) or
    "scripts/thrustmaster/tca_throttle_average_zibo.lua"
dofile(path)

print("PASS (" .. _VERSION .. "): inert outside the Zibo 737-800")
