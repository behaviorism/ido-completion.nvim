local config = require("ido.config")
local events = require("ido.events")

local M = {}

M.initialized = false

function M.setup(user_config)
  -- Only allow single initialization
  if M.initialized then
    error("Plugin already initialized")
  end

  M.initialized = true

  config.configuration = vim.tbl_deep_extend("force", config.default_options, user_config or {})
  events.setup()
end

return M
