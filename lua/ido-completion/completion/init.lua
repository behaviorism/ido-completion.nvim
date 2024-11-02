local cmd = require("ido-completion.cmd")
local prospect = require("ido-completion.prospect")
local config = require("ido-completion.config")
local completion_utils = require("ido-completion.completion.utils")

local M = {}

local prospects = {}
local substring_prospect = ""

function M.cleanup()
  prospects = {}
  substring_prospect = ""
end

function M.update_completion()
  local update_cmd_error = cmd.update_command_checked()
  if update_cmd_error then return M.cleanup() end

  local get_completion_type_error, completion_type = completion_utils.get_completion_type_checked()
  if get_completion_type_error then return M.cleanup() end

  -- Pattern to get all values or head directory values
  local completion_target = cmd.get_completion_target()
  -- Tail of it used for matching
  local completion_target_tail = vim.fn.fnamemodify(completion_target, ":t")

  -- Set target to the head of path for directories
  local broad_target = completion_utils.get_directory_pattern(completion_target)

  local candidates = vim.list_extend(
    vim.fn.getcompletion(broad_target, completion_type, true),        -- Normal
    vim.fn.getcompletion(broad_target .. ".*", completion_type, true) -- Dotfiles
  )

  -- Create prospects items (with tails used for matching)
  candidates = prospect.create_prospects(candidates)

  -- Match completions using matchfuzzy
  local matches_positions

  -- Only works with an non blank pattern
  if completion_target_tail ~= "" then
    local matches = vim.fn.matchfuzzypos(
      candidates,
      completion_target_tail,
      { text_cb = function(candidate) return candidate.label end }
    )
    prospects = matches[1]
    matches_positions = matches[2]
  else
    -- Otherwise just assign all candidates
    prospects = candidates
  end

  -- Reset substring prospect in case there is none
  substring_prospect = ""

  if #prospects > 1 and completion_target_tail ~= "" then
    substring_prospect = completion_utils.find_substring_completion(prospects,
      matches_positions)
  end

  -- If there is only one prospect, and that is the pattern itself, remove
  -- it as otherwise it would later display it as matched, although it is the
  -- pattern itself
  if #prospects == 1 and prospects[1].raw == completion_target then
    prospects = {}
  end

  cmd.display_prospects(prospects, substring_prospect)
end

local function confirm_current_prospect()
  -- Prospect is already selected
  cmd.match_prospect(prospects[1])
  M.update_completion()
end

function M.handle_return()
  -- If there are no prospects, return has default behavior
  if #prospects == 0 then
    return true
  end

  -- Attempt submitting current prospect
  if cmd.some_command_active(config.configuration.match_submits_commands) then
    if vim.fn.isdirectory(prospects[1].expanded_path) ~= 1 then
      cmd.match_prospect(prospects[1])
      return true
    end
  end

  -- Attempt confirm prospect selection
  -- If trying to confirm already selected prospect (only possible with commands),
  -- submit by returning false
  if cmd.get_completion_target() == prospects[1].raw then
    return true
  end

  confirm_current_prospect()
  -- Prevent return after confirming prospect
  return false
end

local function try_select_match()
  -- If no prospects, nothing to cycle
  if #prospects == 0 then return "No prospects available" end

  -- If 1 prospect, then match it
  if #prospects == 1 then
    if cmd.some_command_active(config.configuration.match_submits_commands) then
      cmd.match_prospect(prospects[1])
      cmd.simulate_return()
      return
    end

    confirm_current_prospect()
    return "Already matched"
  end

  -- If common substring prospect is defined, match it and update completion
  if substring_prospect ~= "" then
    cmd.match_prospect(prospect.create_prospect(cmd.get_completion_target() .. substring_prospect))
    M.update_completion()
    return "Already matched"
  end
end

function M.select_next_prospect()
  local error = try_select_match()
  if error then return end

  -- Rotate forward
  table.insert(prospects, table.remove(prospects, 1))

  cmd.display_prospects(prospects)
end

function M.select_previous_prospect()
  local error = try_select_match()
  if error then return end

  -- Rotate backward
  table.insert(prospects, 1, table.remove(prospects))

  cmd.display_prospects(prospects)
end

return M
