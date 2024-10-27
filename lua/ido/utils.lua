local M = {}

-- Generated with ChatGPT
function M.remove_common_prefixes(strings, pattern)
  local results = {}

  local last_slash_pos = pattern:find("/[^/]*$")

  local common_prefix
  if last_slash_pos then
    common_prefix = pattern:sub(1, last_slash_pos - 1)
  else
    common_prefix = pattern
  end

  for i = 1, #strings do
    local str = strings[i]
    if str:find(common_prefix) == 1 then
      local mapped_str = str:sub(#common_prefix + 1)
      mapped_str = mapped_str:gsub("^/+", "")
      results[#results + 1] = mapped_str
    else
      results[#results + 1] = str
    end
  end

  return results
end

return M
