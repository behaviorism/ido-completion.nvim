local M = {}

function M.remove_common_prefixes(strings, pattern)
  local results = {}

  -- This mainly pertains to paths, so if the pattern does not
  -- have a path, we just ignore
  local path_head = vim.fn.fnamemodify(pattern, ":h")

  if path_head == "" then
    return strings
  end

  for i = 1, #strings do
    local str = strings[i]
    -- Check if the string starts with the pattern path head
    if str:sub(1, #path_head) == path_head then
      -- Map to suffix
      local mapped_str = str:sub(#path_head + 1)
      table.insert(results, mapped_str)
    else
      table.insert(results, str)
    end
  end

  return results
end

return M
