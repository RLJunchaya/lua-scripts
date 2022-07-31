--[[
$module Client

Get information about the current client. For the purposes of Finale Lua, the client is
the Finale application that's running on someones machine. Therefore, the client has
details about the user's setup, such as their Finale version, plugin version, and
operating system.

One of the main uses of using client details is to check its capabilities. As such,
the bulk of this library is helper functions to determine what the client supports.
]] --
local client = {}

local function to_human_string(feature)
    return string.gsub(feature, "_", " ")
end

local function requires_later_plugin_version(feature)
    if feature then
        return "This script uses " .. to_human_string(feature) .. "which is only available in a later version of RGP Lua. Please update RGP Lua instead to use this script."
    end
    return "This script requires a later version of RGP Lua. Please update RGP Lua instead to use this script."
end

local function requires_rgp_lua(feature)
    if feature then
        return "This script uses " .. to_human_string(feature) .. " which is not available on JW Lua. Please use RGP Lua instead to use this script."
    end
    return "This script requires RGP Lua, the successor of JW Lua. Please use RGP Lua instead to use this script."
end

local function requires_plugin_version(version, feature)
    if version <= 0.54 then
        if feature then
            return "This script uses " .. to_human_string(feature) .. " which requires RGP Lua or JW Lua version " .. version ..
                       " or later. Please update your plugin to use this script."
        end
        return "This script requires RGP Lua or JW Lua version " .. version .. " or later. Please update your plugin to use this script."
    end
    if feature then
        return "This script uses " .. to_human_string(feature) .. " which requires RGP Lua version " .. version .. " or later. Please update your plugin to use this script."
    end
    return "This script requires RGP Lua version " .. version .. " or later. Please update your plugin to use this script."
end

local function requires_finale_version(version, feature)
    return "This script uses " .. to_human_string(feature) .. ", which is only available on Finale " .. version .. " or later"
end

local features = {
    clef_change = {
        test = function()
            return finenv.StringVersion >= "0.60"
        end,
        error = requires_plugin_version("0.58", "a clef change"),
    },
    custom_key_signature = {
        test = function()
            local key = finale.FCKeySignature()
            return finenv.IsRGPLua and key.CalcTotalChromaticSteps
        end,
        error = requires_later_plugin_version("a custom key signature"),
    },
    ["FCCategory::SaveWithNewType"] = {
        test = function()
            return finenv.StringVersion >= "0.58"
        end,
        error = requires_plugin_version("0.58"),
    },
    finenv_query_invoked_modifier_keys = {
        test = function()
            return finenv.IsRGPLua and finenv.QueryInvokedModifierKeys
        end,
        error = requires_later_plugin_version(),
    },
    modeless_dialog = {
        test = function()
            return finenv.IsRGPLua
        end,
        error = requires_rgp_lua("a modeless dialog"),
    },
    retained_state = {
        test = function()
            return finenv.IsRGPLua and finenv.RetainLuaState ~= nil
        end,
        error = requires_later_plugin_version(),
    },
    smufl_font = {
        test = function()
            return finenv.RawFinaleVersion >= client.get_raw_finale_version(27, 1)
        end,
        error = requires_finale_version("27.1", "a SMUFL font"),
    },
}

--[[
% get_raw_finale_version
Returns a raw Finale version from major, minor, and (optional) build parameters. For 32-bit Finale
this is the internal major Finale version, not the year.

@ major (number) Major Finale version
@ minor (number) Minor Finale version
@ [build] (number) zero if omitted

: (number)
]]
function client.get_raw_finale_version(major, minor, build)
    local retval = bit32.bor(bit32.lshift(math.floor(major), 24), bit32.lshift(math.floor(minor), 20))
    if build then
        retval = bit32.bor(retval, math.floor(build))
    end
    return retval
end

--[[
% supports

Checks the client supports a given feature. Returns true if the client
supports the feature, false otherwise.

To assert the client must support a feature, use `client.assert_supports`.

For a list of valid features, see the [`features` table in the codebase](https://github.com/finale-lua/lua-scripts/blob/master/src/library/client.lua#L52).

@ feature (string) The feature the client should support.
: (boolean)
]]
function client.supports(feature)
    return features[feature].test()
end

--[[
% assert_supports

Asserts that the client supports a given feature. If the client doesn't
support the feature, this function will throw an friendly error then
exit the program.

To simply check if a client supports a feature, use `client.supports`.

For a list of valid features, see the [`features` table in the codebase](https://github.com/finale-lua/lua-scripts/blob/master/src/library/client.lua#L52).

@ feature (string) The feature the client should support.
: (boolean)
]]
function client.assert_supports(feature)
    local error_level = finenv.DebugEnabled and 2 or 0
    if not client.supports(feature) then
        if features[feature].error then
            error(features[feature].error, error_level)
        end
        -- Generic error message
        error("Your Finale version does not support " .. to_human_string(feature), error_level)
    end
    return true
end

return client
