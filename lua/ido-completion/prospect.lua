local M = {}

-- Handles duplicate names within different directories (i.e.: buffers)
local function set_prospects_labels(prospects)
  local prospects_length = #prospects
  local fnamemodify = vim.fn.fnamemodify

  for i = 1, prospects_length do
    -- Longest tail
    local prospect = prospects[i]

    if not prospect.is_file then goto continue_prospect end

    local tail = prospect.tail
    local expanded_path = prospect.expanded_path

    local label = prospect.label or tail

    for j = i + 1, prospects_length do
      local next_prospect = prospects[j]
      local next_tail = next_prospect.tail

      if tail ~= next_tail then goto continue_next end

      local next_expanded_path = next_prospect.expanded_path

      local depth = 1

      while tail == next_tail do
        local mods = string.rep(":h", depth) .. ":t"
        tail = fnamemodify(expanded_path, mods) .. "/" .. tail
        next_tail = fnamemodify(next_expanded_path, mods) .. "/" .. next_tail
        depth = depth + 1
      end

      if #tail > #label then
        label = tail
      end

      if #next_tail > #next_prospect.label then
        next_prospect.label = next_tail
      end

      ::continue_next::
    end

    if prospect.label ~= label then
      prospect.label = label
    end

    ::continue_prospect::
  end
end


local function get_last_component(prospect)
  -- Extract last part of completion.
  -- If command -> entire command
  -- If dir -> last dir
  -- If file path -> file name
  -- Regarding paths, we just need the last part
  -- as the current input is in their cwd.

  -- Check if folder.
  -- Check if it is substring to avoid: lu[a]{init.lua | lua/} matching the folder.
  if prospect:sub(-1) == "/" and vim.fn.isdirectory(prospect) == 1 then
    -- If is directory, return last directory (tail of head)
    return vim.fn.fnamemodify(prospect, ":h:t") .. "/"
  else
    -- Otherwise, if file return just tail
    return vim.fn.fnamemodify(prospect, ":t")
  end
end

-- Create prospect with full path and tail (for display and matching)
function M.create_prospect(raw_prospect)
  local expanded = vim.fn.expand(raw_prospect)

  if expanded ~= "" and expanded:sub(-2) ~= "./" and raw_prospect:sub(-3) ~= "../" then
    expanded = vim.fn.fnamemodify(expanded, ":p")
  else
    expanded = raw_prospect
  end

  local tail = get_last_component(expanded or raw_prospect)

  local prospect = {
    raw = raw_prospect,
    -- Useful for vim.fn.isdirectory() with ~
    expanded_path = expanded,
    tail = tail,
    -- For duplicates
    label = tail,
    is_file = vim.fn.filereadable(expanded) == 1
  }

  return prospect
end

function M.create_prospects(raw_prospects)
  local prospects = {}

  local raw_prospects_length = #raw_prospects
  for i = 1, raw_prospects_length do
    table.insert(prospects, M.create_prospect(raw_prospects[i]))
  end

  set_prospects_labels(prospects)

  return prospects
end

function M.get_prospects_labels(prospects)
  local results = {}

  local prospects_length = #prospects
  for i = 1, prospects_length do
    table.insert(results, prospects[i].label)
  end

  return results
end

return M
