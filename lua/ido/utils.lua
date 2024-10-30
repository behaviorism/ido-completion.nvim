local cmd = require("ido.cmd")

local M = {}

function M.remove_common_prefixes(strings, pattern)
  local results = {}

  -- This mainly pertains to paths, so if the pattern does not
  -- have a path, we just ignore
  local path_head = vim.fn.fnamemodify(pattern, ":h")

  if path_head == "" or path_head == "." then
    return strings
  end

  path_head = path_head .. "/"

  for _, str in ipairs(strings) do
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

function M.shorten_paths_to_cwd(absolute_paths)
  local shortened_paths = {}
  local cwd = vim.fn.getcwd()

  for _, absolute in ipairs(absolute_paths) do
    -- Match and extract the part of the path after cwd
    local shortened_path = absolute:match("^" .. vim.pesc(cwd) .. "/(.*)")

    -- If a match is found, use it; otherwise, keep the original path
    table.insert(shortened_paths, shortened_path or absolute)
  end

  return shortened_paths
end

return M
