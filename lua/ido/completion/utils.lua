local cmd = require("ido.cmd")

local M = {}

local PATH_COMPL_TYPES = { "arglist", "dir", "dir_in_path", "file", "file_in_path", "runtime", "scriptnames",
  "tag_listfiles", "shellcmd", "shellcmdline", "buffer" }

function M.is_path_completion_type(completion_type)
  return vim.tbl_contains(PATH_COMPL_TYPES, completion_type)
end

function M.find_common_substring_completion(prospects, matching_positions)
  -- Check if any matching is due to flexible matching
  -- For any list of matches position, if its a substring
  -- it is consecutive (i.e.: 1, 2, 3) with no gap.

  -- Null check because it is nil when pattern is empty
  if matching_positions then
    for _, prospect_matching_positions in ipairs(matching_positions) do
      for j = 1, #prospect_matching_positions - 1 do
        if prospect_matching_positions[j] + 1 ~= prospect_matching_positions[j + 1] then
          -- Flexible matching does not support substring matching
          return ""
        end
      end
    end
  end

  local common_substring = ""

  for offset = 1, math.huge do
    for i = 1, #prospects do
      local prospect_character_index

      if matching_positions then
        prospect_character_index = matching_positions[i][#(matching_positions[i])] + offset + 1
      else
        prospect_character_index = offset
      end

      local prospect_character = prospects[i]:sub(prospect_character_index, prospect_character_index)
      local common_character = common_substring:sub(offset, offset)

      local prospect_character_blank = prospect_character == ""
      local common_character_blank = common_character == ""

      -- If the current character is blank the substring
      -- is constrained by the length of the current prospect
      if prospect_character_blank then
        -- If the common character for this offset has already been
        -- defined, we remove it as it does not match with this string
        if not common_character_blank then
          common_substring = common_substring:sub(1, -2)
        end

        -- Common match cannot be any longer so we early return
        return common_substring
      end

      -- Prospect character is defined

      -- If the common character has not been defined yet, we define it
      if common_character_blank then
        common_substring = common_substring .. prospect_character
      else
        -- If common character for this offset is defined, we check
        -- that the prospect character matches. Otherwise, we remove it
        -- as it does not match with this prospect and we early returns
        -- as the common match cannot be any longer.
        if prospect_character ~= common_character then
          common_substring = common_substring:sub(1, -2)
          return common_substring
        end

        -- Prospect character matches common character, so we do nothing
      end
    end
  end

  return common_substring
end

function M.get_path_patterns(pattern)
  -- To avoid native completion filtering automatically, we set
  -- the most generic pattern possible.
  local completion_pattern = ""

  -- If there is a complete path before the last
  -- part of the path, use it so that the completer
  -- can get all the items in the current dir
  local path_head = vim.fn.fnamemodify(pattern, ":h")
  if path_head ~= "" and path_head ~= "." then
    path_head = path_head .. "/"
    completion_pattern = path_head
  end

  -- If tail starts with dot, assumes user is looking for dotfiles
  local path_tail = vim.fn.fnamemodify(pattern, ":t")
  if path_tail:sub(1, 1) == "." then
    completion_pattern = completion_pattern .. ".*"
  end

  -- TODO: handle spaces
  -- For matching, we just resolve the actual path (in case there are /../, etc.)
  local matching_pattern = vim.loop.fs_realpath(path_head) .. path_tail

  -- Return full path because it matches better for
  -- certain things (i.e.: buffers)
  return vim.fn.fnamemodify(completion_pattern, ":p"), matching_pattern
end

function M.get_completion_type_checked()
  local completion_type = vim.fn.getcmdcompltype()

  -- If no completion type matches, it is not supported
  -- by neovim's autocompletion, therefore do not complete.
  -- This is the case with vim options values, although native
  -- completion supports it.  ¯\_(ツ)_/
  if completion_type == "" then
    cmd.remove_completion()
    return "Completion type not supported"
  end

  return nil, completion_type
end

return M
