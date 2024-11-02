local config = require("ido-completion.config")
local get_prospects_labels = require("ido-completion.prospect").get_prospects_labels

local M = {}

-- Track user input
local command_type = ""
local input = ""
local position = 1

-- Global completion area str
local completion_str = ""


local editing_cmdline = false

local function set_cmdline(cmd, pos)
  editing_cmdline = true
  vim.fn.setcmdline(cmd, pos or 1)
  editing_cmdline = false
end

function M.remove_completion()
  if completion_str ~= "" then
    set_cmdline(input, position)
    completion_str = ""
  end
end

function M.some_command_active(commands, commandline_type)
  -- Give opportunity of providing prefetched cmdtype
  -- for efficiency
  if not commandline_type then
    commandline_type = vim.fn.getcmdtype()
  end

  local commands_length = #commands

  if commands_length > 0 then
    local full_current_command_str = commandline_type .. input

    for i = 1, commands_length do
      local active_command = commands[i]

      -- If current command matches at least one active command, return true
      if full_current_command_str:sub(1, #active_command) == active_command then
        return true
      end
    end
  end

  return false
end

local function check_config_inactive_commands()
  local inactive_commands = config.configuration.inactive_commands

  -- If there are no inactive commands we assume ido is
  -- always enabled
  if #inactive_commands > 0 then
    if M.some_command_active(inactive_commands, command_type) then
      return "An inactive command"
    end
  end
end

local function check_config_active_commands()
  local active_commands = config.configuration.active_commands

  -- If there are no active commands we assume ido is
  -- always enabled
  if #active_commands > 0 then
    if not M.some_command_active(active_commands, command_type) then
      return "Not an active command"
    end
  end
end

local function check_command_type()
  -- If incsearch is enabled, prevent completion
  -- with highlighting commands, as real time search
  -- would also include the completion
  if vim.o.incsearch then
    -- Searches
    if command_type == "?" or
        command_type == "/" or
        -- Substitution
        (command_type == ":" and input:match("^[%%'<,>]*s/"))
    then
      return "Search or substitution mode while incsearch is enabled are not allowed"
    end
  end
end

local function check_command()
  local command_type_error = check_command_type()
  if command_type_error then return command_type_error end

  local active_command_error = check_config_active_commands()
  if active_command_error then return active_command_error end

  local inactive_command_error = check_config_inactive_commands()
  if inactive_command_error then return inactive_command_error end
end

local function get_input_checked(cmdline)
  -- Only new command is present in cmdline
  if #completion_str == 0 then
    return nil, cmdline
  end

  -- Completion has not been touched
  local completion_area = cmdline:sub(- #completion_str)
  if completion_area == completion_str then
    -- Separate actual new command from old completion
    return nil, cmdline:sub(1, - #completion_str - 1)
  end

  -- If the input area has also been touched, it is assumed
  -- that it is due to special features (i.e.: history change)
  -- and that completion is not present.
  local input_area = cmdline:sub(1, #input)
  if input_area ~= input then
    return nil, cmdline
  end

  -- However, if the previous command in the history is the same
  -- as the current command, this check would fail, so we add another
  -- check. The check consists in checking that the command size has
  -- only changed by more than 1 absolute unit, which should not be
  -- possible with natural user editing.
  if math.abs(#cmdline - (#input + #completion_str)) > 1 then
    return nil, cmdline
  end

  return "User attempted editing completion area"
end

local function check_position()
  -- Ignore keymaps commands
  if position == 0 then
    return "Keymap command"
  end
end

function M.update_command_checked()
  position = vim.fn.getcmdpos()

  local position_error = check_position()
  if position_error then return position_error end

  command_type = vim.fn.getcmdtype()
  local cmdline = vim.fn.getcmdline()

  local get_input_error, new_input = get_input_checked(cmdline)

  if get_input_error then
    -- If user tried editing just the completion area
    -- This messes up everything, so we just reset
    set_cmdline(input .. completion_str, #input + 1)
    return get_input_error
  end

  input = new_input

  local command_error = check_command()

  if command_error then
    M.remove_completion()
    return command_error
  end
end

function M.display_prospects(prospects, substring_prospect)
  completion_str = ""

  local prospects_length = #prospects

  -- Or because it is an optional argument
  if (substring_prospect or "") ~= "" then
    completion_str = completion_str .. "[" .. substring_prospect .. "]"
  end

  if prospects_length == 1 then
    completion_str = completion_str .. "[" .. prospects[1].label .. "] [Matched]"
  elseif prospects_length > 1 then
    local prospects_labels = get_prospects_labels(prospects)

    completion_str = completion_str .. "{" ..
        table.concat(prospects_labels, " | ", 1, math.min(prospects_length, config.configuration.max_prospects))

    if prospects_length > config.configuration.max_prospects then
      completion_str = completion_str .. " | ..."
    end

    completion_str = completion_str .. "}"
  else
    completion_str = " [No match]"
  end

  set_cmdline(input .. completion_str, position)
end

function M.get_completion_target()
  local raw_pattern = vim.fn.getcmdcomplpat()

  local completion_area = raw_pattern:sub(- #completion_str)

  if completion_area == completion_str then
    return raw_pattern:sub(1, - #completion_str - 1)
  end

  return raw_pattern
end

function M.match_prospect(prospect)
  local current_target_tail = vim.fn.fnamemodify(M.get_completion_target(), ":t")

  local command_str_with_no_pattern = input:sub(1, #input - #current_target_tail)

  input = command_str_with_no_pattern .. prospect.label

  -- Update completion str
  completion_str = ""

  -- Update current cursor position
  position = #input + 1

  set_cmdline(input, position)
end

function M.simulate_return()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", true)
end

function M.cleanup()
  M.remove_completion()
  input = ""
end

function M.is_empty()
  return input == "" and completion_str == ""
end

function M.is_editing()
  return editing_cmdline
end

return M
