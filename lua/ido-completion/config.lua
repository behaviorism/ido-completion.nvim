local M = {}

M.default_options = {
  -- Max number of suggestions to be displayed.
  max_prospects = 12,
  -- Commands where ido will be active (i.e.: ":buffer ").
  -- If blank, ido will be active on every command (except for inactive commands).
  active_commands = {},
  -- Commands where ido will be inactive.
  -- If blank, ido will be active on every command (except if active commands are specified).
  inactive_commands = {},
  -- Commands where matching (return or tab when there is a single prospect)
  -- a prospect will autocomplete and submit the command (except for directories).
  -- Useful for buffers (":buffer") and files (":edit"; ":find").
  match_submits_commands = { ":find", ":e", ":buffer" }
}

return M
