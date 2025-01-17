local __imports = {}

function require(item)
    if __imports[item] then
        return __imports[item]()
    else
        error("module '" .. item .. "' not found")
    end
end

__imports["library.configuration"] = function()
    --  Author: Robert Patterson
    --  Date: March 5, 2021
    --[[
    $module Configuration

    This library implements a UTF-8 text file scheme for configuration and user settings as follows:

    - Comments start with `--`
    - Leading, trailing, and extra whitespace is ignored
    - Each parameter is named and delimited as follows:

    ```
    <parameter-name> = <parameter-value>
    ```

    Parameter values may be:

    - Strings delimited with either single- or double-quotes
    - Tables delimited with `{}` that may contain strings, booleans, or numbers
    - Booleans (`true` or `false`)
    - Numbers

    Currently the following are not supported:

    - Tables embedded within tables
    - Tables containing strings that contain commas

    A sample configuration file might be:

    ```lua
    -- Configuration File for "Hairpin and Dynamic Adjustments" script
    --
    left_dynamic_cushion 		= 12		--evpus
    right_dynamic_cushion		= -6		--evpus
    ```

    ## Configuration Files

    Configuration files provide a way for power users to modify script behavior without
    having to modify the script itself. Some users track their changes to their configuration files,
    so scripts should not create or modify them programmatically.

    - The user creates each configuration file in a subfolder called `script_settings` within
    the folder of the calling script.
    - Each script that has a configuration file defines its own configuration file name.
    - It is entirely appropriate over time for scripts to transition from configuration files to user settings,
    but this requires implementing a user interface to modify the user settings from within the script.
    (See below.)

    ## User Settings Files

    User settings are written by the scripts themselves and reside in the user's preferences folder
    in an appropriately-named location for the operating system. (The naming convention is a detail that the
    configuration library handles for the caller.) If the user settings are to be changed from their defaults,
    the script itself should provide a means to change them. This could be a (preferably optional) dialog box
    or any other mechanism the script author chooses.

    User settings are saved in the user's preferences folder (on Mac) or AppData folder (on Windows).

    ## Merge Process

    Files are _merged_ into the passed-in list of default values. They do not _replace_ the list. Each calling script contains
    a table of all the configurable parameters or settings it recognizes along with default values. An example:

    `sample.lua:`

    ```lua
    parameters = {
       x = 1,
       y = 2,
       z = 3
    }

    configuration.get_parameters(parameters, "script.config.txt")

    for k, v in pairs(parameters) do
       print(k, v)
    end
    ```

    Suppose the `script.config.text` file is as follows:

    ```
    y = 4
    q = 6
    ```

    The returned parameters list is:


    ```lua
    parameters = {
       x = 1,       -- remains the default value passed in
       y = 4,       -- replaced value from the config file
       z = 3        -- remains the default value passed in
    }
    ```

    The `q` parameter in the config file is ignored because the input paramater list
    had no `q` parameter.

    This approach allows total flexibility for the script add to or modify its list of parameters
    without having to worry about older configuration files or user settings affecting it.
    ]]

    local configuration = {}

    local script_settings_dir = "script_settings" -- the parent of this directory is the running lua path
    local comment_marker = "--"
    local parameter_delimiter = "="
    local path_delimiter = "/"

    local file_exists = function(file_path)
        local f = io.open(file_path, "r")
        if nil ~= f then
            io.close(f)
            return true
        end
        return false
    end

    local strip_leading_trailing_whitespace = function(str)
        return str:match("^%s*(.-)%s*$") -- lua pattern magic taken from the Internet
    end

    local parse_table = function(val_string)
        local ret_table = {}
        for element in val_string:gmatch("[^,%s]+") do -- lua pattern magic taken from the Internet
            local parsed_element = parse_parameter(element)
            table.insert(ret_table, parsed_element)
        end
        return ret_table
    end

    parse_parameter = function(val_string)
        if "\"" == val_string:sub(1, 1) and "\"" == val_string:sub(#val_string, #val_string) then -- double-quote string
            return string.gsub(val_string, "\"(.+)\"", "%1") -- lua pattern magic: "(.+)" matches all characters between two double-quote marks (no escape chars)
        elseif "'" == val_string:sub(1, 1) and "'" == val_string:sub(#val_string, #val_string) then -- single-quote string
            return string.gsub(val_string, "'(.+)'", "%1") -- lua pattern magic: '(.+)' matches all characters between two single-quote marks (no escape chars)
        elseif "{" == val_string:sub(1, 1) and "}" == val_string:sub(#val_string, #val_string) then
            return parse_table(string.gsub(val_string, "{(.+)}", "%1"))
        elseif "true" == val_string then
            return true
        elseif "false" == val_string then
            return false
        end
        return tonumber(val_string)
    end

    local get_parameters_from_file = function(file_path, parameter_list)
        local file_parameters = {}

        if not file_exists(file_path) then
            return false
        end

        for line in io.lines(file_path) do
            local comment_at = string.find(line, comment_marker, 1, true) -- true means find raw string rather than lua pattern
            if nil ~= comment_at then
                line = string.sub(line, 1, comment_at - 1)
            end
            local delimiter_at = string.find(line, parameter_delimiter, 1, true)
            if nil ~= delimiter_at then
                local name = strip_leading_trailing_whitespace(string.sub(line, 1, delimiter_at - 1))
                local val_string = strip_leading_trailing_whitespace(string.sub(line, delimiter_at + 1))
                file_parameters[name] = parse_parameter(val_string)
            end
        end

        for param_name, _ in pairs(parameter_list) do
            local param_val = file_parameters[param_name]
            if nil ~= param_val then
                parameter_list[param_name] = param_val
            end
        end

        return true
    end

    --[[
    % get_parameters

    Searches for a file with the input filename in the `script_settings` directory and replaces the default values in `parameter_list`
    with any that are found in the config file.

    @ file_name (string) the file name of the config file (which will be prepended with the `script_settings` directory)
    @ parameter_list (table) a table with the parameter name as key and the default value as value
    : (boolean) true if the file exists
    ]]
    function configuration.get_parameters(file_name, parameter_list)
        local path = ""
        if finenv.IsRGPLua then
            path = finenv.RunningLuaFolderPath()
        else
            local str = finale.FCString()
            str:SetRunningLuaFolderPath()
            path = str.LuaString
        end
        local file_path = path .. script_settings_dir .. path_delimiter .. file_name
        return get_parameters_from_file(file_path, parameter_list)
    end

    -- Calculates a filepath in the user's preferences folder using recommended naming conventions
    --
    local calc_preferences_filepath = function(script_name)
        local str = finale.FCString()
        str:SetUserOptionsPath()
        local folder_name = str.LuaString
        if not finenv.IsRGPLua and finenv.UI():IsOnMac() then
            -- works around bug in SetUserOptionsPath() in JW Lua
            folder_name = os.getenv("HOME") .. folder_name:sub(2) -- strip '~' and replace with actual folder
        end
        if finenv.UI():IsOnWindows() then
            folder_name = folder_name .. path_delimiter .. "FinaleLua"
        end
        local file_path = folder_name .. path_delimiter
        if finenv.UI():IsOnMac() then
            file_path = file_path .. "com.finalelua."
        end
        file_path = file_path .. script_name .. ".settings.txt"
        return file_path, folder_name
    end

    --[[
    % save_user_settings

    Saves the user's preferences for a script from the values provided in `parameter_list`.

    @ script_name (string) the name of the script (without an extension)
    @ parameter_list (table) a table with the parameter name as key and the default value as value
    : (boolean) true on success
    ]]
    function configuration.save_user_settings(script_name, parameter_list)
        local file_path, folder_path = calc_preferences_filepath(script_name)
        local file = io.open(file_path, "w")
        if not file and finenv.UI():IsOnWindows() then -- file not found
            os.execute('mkdir "' .. folder_path ..'"') -- so try to make a folder (windows only, since the folder is guaranteed to exist on mac)
            file = io.open(file_path, "w") -- try the file again
        end
        if not file then -- still couldn't find file
            return false -- so give up
        end
        file:write("-- User settings for " .. script_name .. ".lua\n\n")
        for k,v in pairs(parameter_list) do -- only number, boolean, or string values
            if type(v) == "string" then
                v = "\"" .. v .."\""
            else
                v = tostring(v)
            end
            file:write(k, " = ", v, "\n")
        end
        file:close()
        return true -- success
    end

    --[[
    % get_user_settings

    Find the user's settings for a script in the preferences directory and replaces the default values in `parameter_list`
    with any that are found in the preferences file. The actual name and path of the preferences file is OS dependent, so
    the input string should just be the script name (without an extension).

    @ script_name (string) the name of the script (without an extension)
    @ parameter_list (table) a table with the parameter name as key and the default value as value
    @ [create_automatically] (boolean) if true, create the file automatically (default is `true`)
    : (boolean) `true` if the file already existed, `false` if it did not or if it was created automatically
    ]]
    function configuration.get_user_settings(script_name, parameter_list, create_automatically)
        if create_automatically == nil then create_automatically = true end
        local exists = get_parameters_from_file(calc_preferences_filepath(script_name), parameter_list)
        if not exists and create_automatically then
            configuration.save_user_settings(script_name, parameter_list)
        end
        return exists
    end

    return configuration

end

__imports["library.client"] = function()
    --[[
    $module Client

    Get information about the current client. For the purposes of Finale Lua, the client is
    the Finale application that's running on someones machine. Therefore, the client has
    details about the user's setup, such as their Finale version, plugin version, and
    operating system.

    One of the main uses of using client details is to check its capabilities. As such,
    the bulk of this library is helper functions to determine what the client supports.
    All functions to check a client's capabilities should start with `client.supports_`.
    These functions don't accept any arguments, and should always return a boolean.
    ]] --
    local client = {}

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
    % supports_smufl_fonts()

    Returns true if the current client supports SMuFL fonts.

    : (boolean)
    ]]
    function client.supports_smufl_fonts()
        return finenv.RawFinaleVersion >= client.get_raw_finale_version(27, 1)
    end

    --[[
    % supports_category_save_with_new_type()

    Returns true if the current client supports FCCategory::SaveWithNewType().

    : (boolean)
    ]]
    function client.supports_category_save_with_new_type()
        return finenv.StringVersion >= "0.58"
    end

    --[[
    % supports_finenv_query_invoked_modifier_keys()

    Returns true if the current client supports finenv.QueryInvokedModifierKeys().

    : (boolean)
    ]]
    function client.supports_finenv_query_invoked_modifier_keys()
        return finenv.IsRGPLua and finenv.QueryInvokedModifierKeys
    end

    --[[
    % supports_retained_state()

    Returns true if the current client supports retaining state between runs.

    : (boolean)
    ]]
    function client.supports_retained_state()
        return finenv.IsRGPLua and finenv.RetainLuaState ~= nil
    end

    --[[
    % supports_modeless_dialog()

    Returns true if the current client supports modeless dialogs.

    : (boolean)
    ]]
    function client.supports_modeless_dialog()
        return finenv.IsRGPLua
    end

    --[[
    % supports_clef_changes()

    Returns true if the current client supports changing clefs.

    : (boolean)
    ]]
    function client.supports_clef_changes()
        return finenv.IsRGPLua or finenv.StringVersion >= "0.60"
    end

    --[[
    % supports_custom_key_signatures()

    Returns true if the current client supports changing clefs.

    : (boolean)
    ]]
    function client.supports_custom_key_signatures()
        local key = finale.FCKeySignature()
        return finenv.IsRGPLua and key.CalcTotalChromaticSteps
    end

    return client

end

__imports["library.clef"] = function()
    --[[
    $module Clef

    A library of general clef utility functions.
    ]] --
    local clef = {}

    local client = require("library.client")

    --[[
    % get_cell_clef

    Gets the clef for any cell.

    @ measure (number) The measure number for the cell
    @ staff_number (number) The staff number for the cell
    : (number) The clef for the cell
    ]]
    function clef.get_cell_clef(measure, staff_number)
        local cell_clef = -1
        local cell = finale.FCCell(measure, staff_number)
        local cell_frame_hold = finale.FCCellFrameHold()

        cell_frame_hold:ConnectCell(cell)
        if cell_frame_hold:Load() then
            if cell_frame_hold.IsClefList then
                cell_clef = cell_frame_hold:CreateFirstCellClefChange().ClefIndex
            else
                cell_clef = cell_frame_hold.ClefIndex
            end
        end
        return cell_clef
    end

    --[[
    % get_default_clef

    Gets the default clef for any staff for a specific region.

    @ first_measure (number) The first measure of the region
    @ last_measure (number) The last measure of the region
    @ staff_number (number) The staff number for the cell
    : (number) The default clef for the staff
    ]]
    function clef.get_default_clef(first_measure, last_measure, staff_number)
        local staff = finale.FCStaff()
        local cell_clef = clef.get_cell_clef(first_measure - 1, staff_number)
        if cell_clef < 0 then -- failed, so check clef AFTER insertion
            cell_clef = clef.get_cell_clef(last_measure + 1, staff_number)
            if cell_clef < 0 then -- resort to destination staff default clef
                cell_clef = staff:Load(staff_number) and staff.DefaultClef or 0 -- default treble
            end
        end
        return cell_clef
    end

    --[[
    % restore_default_clef

    Restores the default clef for any staff for a specific region.

    @ first_measure (number) The first measure of the region
    @ last_measure (number) The last measure of the region
    @ staff_number (number) The staff number for the cell
    ]]
    function clef.restore_default_clef(first_measure, last_measure, staff_number)
        if not client.supports_clef_changes() then
            return
        end

        local default_clef = clef.get_default_clef(first_measure, last_measure, staff_number)

        for measure = first_measure, last_measure do
            local cell = finale.FCCell(measure, staff_number)
            local cell_frame_hold = finale.FCCellFrameHold()
            cell_frame_hold:ConnectCell(cell)
            if cell_frame_hold:Load() then
                cell_frame_hold:MakeCellSingleClef(nil) -- RGPLua v0.60
                cell_frame_hold:SetClefIndex(default_clef)
                cell_frame_hold:Save()
            end
        end
    end

    return clef

end

function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v1.47"
    finaleplugin.Date = "2022/07/11"
    finaleplugin.Notes = [[
        This script explodes a set of chords on one staff into single lines on subsequent staves. 
        The number of staves is determined by the largest number of notes in any chord.
        It warns if pre-existing music in the destination will be erased. 
        It duplicates all markings from the original and resets the current clef on each destination staff.

        By default this script doesn't respace the selected music after it completes. 
        If you want automatic respacing, hold down the `shift` or `alt` (option) key when selecting the script's menu item. 

        Alternatively, if you want the default behaviour to include spacing then create a `configuration` file:  
        If it does not exist, create a subfolder called `script_settings` in the folder containing this script. 
        In that folder create a plain text file  called `staff_explode.config.txt` containing the line: 

        ```
        fix_note_spacing = true -- respace music when the script finishes
        ```
        If you subsequently hold down the `shift` or `alt` (option) key, spacing will not be included.
    ]]
    return "Staff Explode", "Staff Explode", "Explode chords from one staff into single notes on consecutive staves"
end

local configuration = require("library.configuration")
local clef = require("library.clef")

local config = { fix_note_spacing = false }
configuration.get_parameters("staff_explode.config.txt", config)

function show_error(error_code)
    local errors = {
        need_more_staves = "There are not enough empty\nstaves to explode onto",
        only_one_staff = "Please select only one staff!",
        empty_region = "Please select a region\nwith some notes in it!",
        require_chords = "Chords must contain\nat least two pitches",
    }
    finenv.UI():AlertNeutral("script: " .. plugindef(), errors[error_code])
    return -1
end

function should_overwrite_existing_music()
    local alert = finenv.UI():AlertOkCancel("script: " .. plugindef(), "Overwrite existing music?")
    local should_overwrite = alert == 0
    return should_overwrite
end

function get_note_count(source_staff_region)
    local note_count = 0
    for entry in eachentry(source_staff_region) do
        if entry.Count > note_count then
            note_count = entry.Count
        end
    end
    if note_count == 0 then
        return show_error("empty_region")
    end
    if note_count < 2 then
        return show_error("require_chords")
    end
    return note_count
end

function ensure_score_has_enough_staves(slot, note_count)
    local staves = finale.FCStaves()
    staves:LoadAll()
    if note_count > staves.Count + 1 - slot then
        return false
    end
    return true
end

function staff_explode()
    if finenv.QueryInvokedModifierKeys and
    (finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT) or finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT))
        then
        config.fix_note_spacing = not config.fix_note_spacing
    end

    local source_staff_region = finale.FCMusicRegion()
    source_staff_region:SetCurrentSelection()
    if source_staff_region:CalcStaffSpan() > 1 then
        return show_error("only_one_staff")
    end
    local start_slot = source_staff_region.StartSlot
    local start_measure = source_staff_region.StartMeasure
    local end_measure = source_staff_region.EndMeasure
    local regions = {}
    regions[1] = source_staff_region

    local max_note_count = get_note_count(source_staff_region)
    if max_note_count <= 0 then
        return
    end

    if not ensure_score_has_enough_staves(start_slot, max_note_count) then
        show_error("need_more_staves")
        return
    end

    -- copy top staff to note_count lower staves (one-based index)
    local destination_is_empty = true
    for slot = 2, max_note_count do
        regions[slot] = finale.FCMusicRegion()
        regions[slot]:SetRegion(regions[1])
        regions[slot]:CopyMusic()
        local this_slot = start_slot + slot - 1 -- "real" slot number, indexed[1]
        regions[slot].StartSlot = this_slot
        regions[slot].EndSlot = this_slot

        if destination_is_empty then
            for entry in eachentry(regions[slot]) do
                if entry.Count > 0 then
                    destination_is_empty = false
                    break
                end
            end
        end
    end

    if destination_is_empty or should_overwrite_existing_music() then
        -- run through all staves deleting requisite notes in each entry
        for slot = 1, max_note_count do
            if slot > 1 then -- finish pasting a copy of the source music
                regions[slot]:PasteMusic()
                clef.restore_default_clef(start_measure, end_measure, regions[slot].StartStaff)
            end

            -- run the ENTRIES loop for current selection on staff copies
            local from_top = slot - 1 -- delete how many notes from the top?
            for entry in eachentrysaved(regions[slot]) do
                if entry:IsNote() then
                    local from_bottom = entry.Count - slot -- how many from the bottom?
                    if from_top > 0 then -- delete TOP notes
                        for i = 1, from_top do
                            entry:DeleteNote(entry:CalcHighestNote(nil))
                        end
                    end
                    if from_bottom > 0 then -- delete BOTTOM notes
                        for i = 1, from_bottom do
                            entry:DeleteNote(entry:CalcLowestNote(nil))
                        end
                    end
                end
            end
        end

        if config.fix_note_spacing then
            regions[1]:SetFullMeasureStack()
            regions[1]:SetInDocument()
            finenv.UI():MenuCommand(finale.MENUCMD_NOTESPACING)
            regions[1].StartSlot = start_slot
            regions[1].EndSlot = start_slot
        end
    end

    -- ALL DONE -- empty out the copied clip files
    for slot = 2, max_note_count do
        regions[slot]:ReleaseMusic()
    end
    regions[1]:SetInDocument()
end

staff_explode()
