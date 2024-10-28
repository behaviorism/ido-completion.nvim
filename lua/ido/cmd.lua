local config = require("ido.config")

local M = {}

local editing_cmdline = false
local current_command_str = ""
local current_completion_str = ""
local current_position = 1

local function set_cmdline(cmd, pos)
  editing_cmdline = true
  vim.fn.setcmdline(cmd, pos or 1)
  editing_cmdline = false
end

local function get_current_command_str_checked(cmdline)
  -- Only new command is present in cmdline
  if #current_completion_str == 0 then
    return nil, cmdline
  end

  -- Completion has not been touched
  local completion_area = cmdline:sub(- #current_completion_str)
  if completion_area == current_completion_str then
    -- Separate actual new command from old completion
    return nil, cmdline:sub(1, - #current_completion_str - 1)
  end

  -- If the command area has also been touched, it is assumed
  -- that it is due to special features (i.e.: history change)
  -- and that completion is not present.
  local command_area = cmdline:sub(1, #current_command_str)
  if command_area ~= current_command_str then
    return nil, cmdline
  end

  -- However, if the previous command in the history is the same
  -- as the current command, this check would fail, so we add another
  -- check. The check consists in checking that the command size has
  -- only changed by more than 1 absolute unit, which should not be
  -- possible with natural user editing.
  if math.abs(#cmdline - (#current_command_str + #current_completion_str)) > 1 then
    return nil, cmdline
  end

  -- If user tried editing just the completion area
  -- This messes up everything, so we just reset
  set_cmdline(current_command_str .. current_completion_str,
    #current_command_str + 1)
  return "User attempted editing completion area"
end

function M.remove_completion()
  -- If completion is displayed, remove from cmdline and
  -- set state to nil
  if current_completion_str ~= "" then
    set_cmdline(current_command_str, current_position)
    current_completion_str = ""
  end
end

local function check_command(cmd)
  local commandline_type = vim.fn.getcmdtype()

  -- If incsearch is enabled, prevent completion
  -- with highlighting commands, as real time search
  -- would also include the completion
  if vim.o.incsearch then
    -- Searches
    if commandline_type == "?" or
        commandline_type == "/" or
        -- Substitution
        (commandline_type == ":" and cmd:match("^[%%'<,>]*s/"))
    then
      M.remove_completion()
      return "Search or substitution mode"
    end
  end

  local active_commands = config.configuration.active_commands

  -- If there are no active commands we assume ido is
  -- always enabled
  if #active_commands > 0 then
    -- If no active command matches, remove completion
    if not M.some_command_active(active_commands, commandline_type) then
      M.remove_completion()
      return "Not an active command"
    end
  end
end

function M.update_command_checked()
  current_position = vim.fn.getcmdpos()

  -- Ignore keymaps commands
  if current_position == 0 then
    return "Keymap command"
  end

  local cmdline = vim.fn.getcmdline()

  -- Gets new command or checks if completion area has been edited
  local get_current_command_str_error, new_command_str = get_current_command_str_checked(cmdline)
  if get_current_command_str_error then return get_current_command_str_error end

  current_command_str = new_command_str

  -- Check if completion should run for the command
  local command_error = check_command(cmdline)
  if command_error then return command_error end
end

local function get_display_prospects(prospects, current_prospect_index, current_substring_prospect)
  local completion_str = ""

  local prospects_length = #prospects

  -- Or because it is an optional argument
  if (current_substring_prospect or "") ~= "" then
    completion_str = completion_str .. "[" .. current_substring_prospect .. "]"
  end

  if prospects_length == 1 then
    completion_str = completion_str .. "[" .. prospects[1] .. "] [Matched]"
  elseif prospects_length > 1 then
    -- 0 index based page
    local page = 0

    if current_prospect_index > 0 then
      page = math.ceil(current_prospect_index / config.configuration.max_prospects) - 1
    end

    -- Only display items on current page, containing N prospects = configuration.max_prospects
    local page_start = (page * config.configuration.max_prospects) + 1
    local page_end = page_start + config.configuration.max_prospects - 1

    completion_str = completion_str .. "{" ..
        table.concat(prospects, " | ", page_start, math.min(prospects_length, page_end))

    if prospects_length > config.configuration.max_prospects then
      completion_str = completion_str .. " | ..."
    end

    completion_str = completion_str .. "}"
  else
    completion_str = " [No match]"
  end

  return completion_str
end

function M.display_prospects(prospects, current_prospect_index, current_substring_prospect)
  current_completion_str = get_display_prospects(prospects, current_prospect_index, current_substring_prospect)
  set_cmdline(current_command_str .. current_completion_str, current_position)
end

function M.some_command_active(commands, commandline_type)
  -- Give opportunity of providing prefetched cmdtype
  -- for efficiency
  if not commandline_type then
    commandline_type = vim.fn.getcmdtype()
  end

  if #commands > 0 then
    local full_current_command_str = commandline_type .. current_command_str

    for i = 1, #commands do
      local active_command = commands[i]

      -- If current command matches at least one active command, return true
      if full_current_command_str:sub(1, #active_command) == active_command then
        return true
      end
    end
  end

  return false
end

function M.match_completion(prospect, pattern)
  -- Update command str
  local command_str_with_no_pattern = current_command_str:sub(1, #current_command_str - #pattern)
  current_command_str = command_str_with_no_pattern .. prospect

  -- Update completion str
  current_completion_str = ""

  -- Update current cursor position
  current_position = #current_command_str + 1

  set_cmdline(current_command_str, current_position)
end

function M.update_completion(previous_prospect, new_prospect, new_prospects, current_prospect_index)
  -- Update command str
  local command_str_with_no_pattern = current_command_str:sub(1, #current_command_str - #previous_prospect)
  current_command_str = command_str_with_no_pattern .. new_prospect

  -- Update completion str
  current_completion_str = get_display_prospects(new_prospects, current_prospect_index)

  -- Update current cursor position
  current_position = #current_command_str + 1

  set_cmdline(current_command_str .. current_completion_str, current_position)
end

function M.strip_completion(str)
  local completion_area = str:sub(- #current_completion_str)

  if completion_area == current_completion_str then
    return str:sub(1, - #current_completion_str - 1)
  end

  return str
end

function M.cleanup()
  M.remove_completion()
  current_command_str = ""
end

function M.is_empty()
  return current_command_str == "" and current_completion_str == ""
end

function M.is_editing()
  return editing_cmdline
end

return M
