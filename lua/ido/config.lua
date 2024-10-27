local M = {}

M.default_options = {
  -- Max number of suggestions to be displayed.
  max_prospects = 12,
  -- Commands where ido will be active (i.e.: ":buffer ").
  -- If blank, ido will be active on every command.
  active_commands = {},
  -- Commands where if pressing return, if there is a matched
  -- prospect, ido will autocomplete it and submit the command.
  -- Useful for buffers (":buffer").
  return_submits_commands = {}
}

return M
