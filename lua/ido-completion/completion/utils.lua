local cmd = require("ido-completion.cmd")

local M = {}

function M.find_substring_completion(prospects, matching_positions)
  -- Check if any matching is due to flexible matching
  -- For any list of matches position, if its a substring
  -- it is consecutive (i.e.: 1, 2, 3) with no gap.
  local prospects_length = #prospects

  -- Null check because it is nil when pattern is empty
  if matching_positions then
    for i = 1, prospects_length do
      local prospect_matching_positions = matching_positions[i]

      local prospect_matching_positions_length = #prospect_matching_positions - 1
      for j = 1, prospect_matching_positions_length do
        if prospect_matching_positions[j] + 1 ~= prospect_matching_positions[j + 1] then
          -- Flexible matching does not support substring matching
          return ""
        end
      end
    end
  end

  local common_substring = ""

  for offset = 1, math.huge do
    for i = 1, prospects_length do
      local prospect_character_index

      if matching_positions then
        prospect_character_index = matching_positions[i][#(matching_positions[i])] + offset + 1
      else
        prospect_character_index = offset
      end

      local prospect_character = prospects[i].tail:sub(prospect_character_index, prospect_character_index)
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

function M.get_directory_pattern(pattern)
  local path_head = vim.fn.fnamemodify(pattern, ":h")

  local completion_pattern = ""

  if path_head ~= "." and path_head ~= "" then
    completion_pattern = path_head .. "/"
  end

  return completion_pattern
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
