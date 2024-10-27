local cmd = require("ido.cmd")
local utils = require("ido.utils")

local M = {}

local PATH_CMD_TYPES = { "arglist", "dir", "dir_in_path", "file", "file_in_path", "runtime", "scriptnames",
  "tag_listfiles", "shellcmd", "shellcmdline" }

local current_prospects = {}
local current_prospect_index = -1

local function get_completion_type_checked()
  local completion_type = vim.fn.getcmdcompltype()

  -- If no completion type matches, it is not supported
  -- by neovim's autocompletion, therefore do not complete.
  -- This is the case with vim options values, although native
  -- completion supports it.
  if completion_type == "" then
    cmd.remove_completion()
    return "Completion type not supported"
  end

  return nil, completion_type
end

local function get_search_pattern(pattern, completion_type)
  local search_pattern = ""

  -- To avoid native completion filtering automatically, we set
  -- the most generic pattern possible. For paths, this means the
  -- head of the path.
  if vim.tbl_contains(PATH_CMD_TYPES, completion_type) then
    -- Is complete path
    if pattern:sub(-1) == "/" then
      search_pattern = pattern
    else
      -- If there is a complete path before the last
      -- part of the path, use it so that the completer
      -- can get all the items in the current dir
      local path_head = vim.fn.fnamemodify(pattern, ":h")
      local is_directory = vim.fn.isdirectory(path_head)

      if is_directory and path_head ~= "." then
        search_pattern = path_head .. "/"
      end

      -- Check if tail starts with dot, assumes user is
      -- looking for dotfiles
      local path_tail = vim.fn.fnamemodify(pattern, ":t")

      if path_tail:sub(1, 1) == "." then
        search_pattern = search_pattern .. ".*"
      end
    end
  end

  return search_pattern
end

function M.update_completion()
  local update_cmd_error = cmd.update_command_checked()
  if update_cmd_error then return end

  local get_completion_type_error, completion_type = get_completion_type_checked()
  if get_completion_type_error then return end

  -- Pattern for actual filtering
  local pattern = cmd.strip_completion(vim.fn.getcmdcomplpat())
  -- Pattern to get all possible items
  local search_pattern = get_search_pattern(pattern, completion_type)

  current_prospects = vim.fn.getcompletion(search_pattern, completion_type, true)

  -- Match completions using matchfuzzy.
  -- Only works with an non blank pattern.
  if #pattern > 0 then
    current_prospects = vim.fn.matchfuzzy(current_prospects, pattern)
  end

  -- If there is only one prospect, and that is the pattern itself, remove
  -- it as otherwise it would later display it as matched, although it is the
  -- pattern itself
  if #current_prospects == 1 and current_prospects[1] == pattern then
    current_prospects = {}
  end

  -- Reset index on completion reset
  current_prospect_index = -1

  -- Map prospects to show only differences from pattern
  local mapped_prospects = utils.remove_common_prefixes(current_prospects, pattern)
  -- Display prospects on cmdlineg
  cmd.display_prospects(mapped_prospects, current_prospect_index)
end

function M.attempt_confirm()
  if #current_prospects == 1 then
    local previous_prospect = cmd.strip_completion(vim.fn.getcmdcomplpat())
    cmd.match_completion(current_prospects[1], previous_prospect)
  end
end

function M.cycle(offset)
  -- If no prospects, nothing to cycle
  if #current_prospects == 0 then return end

  local previous_prospect

  -- If no completion has been selected yet
  -- set "prospect" to be replaced as pattern
  if current_prospect_index == -1 then
    previous_prospect = cmd.strip_completion(vim.fn.getcmdcomplpat())

    -- If 1 prospect, then match it
    -- and update completion
    if #current_prospects == 1 then
      cmd.match_completion(current_prospects[1], previous_prospect)
      M.update_completion()
      return
    end

    -- Adjust current index so that it offsets
    -- correctly
    current_prospect_index = 0
  else
    -- If user selects 0 index (nil), defaults to no completion
    previous_prospect = current_prospects[current_prospect_index] or ""
  end

  -- Previous of 0th is the last element
  if current_prospect_index == 0 and offset == -1 then
    current_prospect_index = #current_prospects
    -- Next of last is nil
  elseif current_prospect_index == #current_prospects and offset == 1 then
    current_prospect_index = 0
  else
    current_prospect_index = current_prospect_index + offset
  end

  local new_prospect = current_prospects[current_prospect_index] or ""

  -- Map prospects to show only differences from pattern
  local mapped_prospects = utils.remove_common_prefixes(current_prospects, new_prospect)

  cmd.update_completion(previous_prospect, new_prospect, mapped_prospects, current_prospect_index)
end

return M
