local cmd = require("ido.cmd")
local utils = require("ido.utils")
local completion_utils = require("ido.completion.utils")

local M = {}

local current_prospects = {}
local current_prospect_index = -1
local current_substring_prospect = ""

local initial_pattern = ""

function M.update_completion()
  local update_cmd_error = cmd.update_command_checked()
  if update_cmd_error then return end

  local get_completion_type_error, completion_type = completion_utils.get_completion_type_checked()
  if get_completion_type_error then return end

  local is_path_completion_type = completion_utils.is_path_completion_type(completion_type)

  -- Actual user input
  initial_pattern = cmd.strip_completion(vim.fn.getcmdcomplpat())
  -- Pattern to get all values or head directory values
  local completion_pattern = ""
  local matching_pattern = initial_pattern

  if is_path_completion_type then
    -- Adjust pattern for paths
    completion_pattern, matching_pattern = completion_utils.get_path_patterns(matching_pattern)
  end

  current_prospects = vim.fn.getcompletion(completion_pattern, completion_type, true)

  -- Match completions using matchfuzzy.
  -- Only works with an non blank pattern.
  local matches_positions

  if initial_pattern ~= "" then
    local matches = vim.fn.matchfuzzypos(current_prospects, matching_pattern)
    current_prospects = matches[1]
    matches_positions = matches[2]
  end

  if is_path_completion_type then
    -- Shorten to cwd for coinciseness
    current_prospects = utils.shorten_paths_to_cwd(current_prospects)
  end

  -- Reset substring prospect
  current_substring_prospect = ""

  if #current_prospects > 1 then
    current_substring_prospect = completion_utils.find_common_substring_completion(current_prospects, matches_positions)
  end

  -- If there is only one prospect, and that is the pattern itself, remove
  -- it as otherwise it would later display it as matched, although it is the
  -- pattern itself
  if #current_prospects == 1 and current_prospects[1] == initial_pattern then
    current_prospects = {}
  end

  -- Reset index on completion reset
  current_prospect_index = -1

  -- TODO fix removing prefix for resolved paths with /../
  -- Map prospects to show only differences from pattern
  local mapped_prospects = utils.remove_common_prefixes(current_prospects, initial_pattern)

  -- Display prospects on cmdlineg
  cmd.display_prospects(mapped_prospects, current_prospect_index, current_substring_prospect)
end

function M.try_confirm()
  if #current_prospects > 0 and current_prospect_index > 0 then
    M.update_completion()
    return true
  end
end

function M.try_confirm_match()
  if #current_prospects == 1 then
    local previous_prospect = cmd.strip_completion(vim.fn.getcmdcomplpat())
    cmd.match_completion(current_prospects[1], previous_prospect)
    return true
  end
end

local function cycle(previous_prospect)
  -- If user selects 0 index (nil), defaults to no initial pattern
  local new_prospect = current_prospects[current_prospect_index] or initial_pattern

  -- Map prospects to show only differences from pattern
  local mapped_prospects = utils.remove_common_prefixes(current_prospects, new_prospect)

  cmd.update_completion(previous_prospect, new_prospect, mapped_prospects, current_prospect_index)
end

local function get_or_select_previous_prospect_checked()
  -- If no prospects, nothing to cycle
  if #current_prospects == 0 then return "No prospects available" end

  local previous_prospect

  -- If no completion has been selected yet
  -- set pattern as the "prospect" to be replaced
  if current_prospect_index == -1 then
    previous_prospect = cmd.strip_completion(vim.fn.getcmdcomplpat())

    -- If 1 prospect, then match it and update completion
    if #current_prospects == 1 then
      cmd.match_completion(current_prospects[1], previous_prospect)
      M.update_completion()
      return "Already matched"
    end

    -- If common substring prospect is defined, match it and update completion
    if current_substring_prospect ~= "" then
      cmd.match_completion(previous_prospect .. current_substring_prospect, previous_prospect)
      M.update_completion()
      return "Already matched"
    end

    -- Adjust current index so that it offsets correctly
    current_prospect_index = 0
  else
    -- If user selects 0 index (nil), defaults to no initial pattern
    previous_prospect = current_prospects[current_prospect_index] or initial_pattern
  end

  return nil, previous_prospect
end

function M.select_next_prospect()
  local error, previous_prospect = get_or_select_previous_prospect_checked()

  if error then return end

  -- Next of last is nil
  if current_prospect_index == #current_prospects then
    current_prospect_index = 0
  else
    current_prospect_index = current_prospect_index + 1
  end

  cycle(previous_prospect)
end

function M.select_previous_prospect()
  local error, previous_prospect = get_or_select_previous_prospect_checked()

  if error then return end

  if current_prospect_index == 0 then
    current_prospect_index = #current_prospects
  else
    current_prospect_index = current_prospect_index - 1
  end

  cycle(previous_prospect)
end

return M
