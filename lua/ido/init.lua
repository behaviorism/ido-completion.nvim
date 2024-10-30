local config = require("ido.config")
local events = require("ido.events")

local M = {}

local initialized = false

function M.isInitialized() return initialized end

function M.setup(user_config)
  -- Only allow single initialization
  if initialized then
    error("Plugin already initialized")
  end

  initialized = true

  config.configuration = vim.tbl_deep_extend("force", config.default_options, user_config or {})
  events.setup()
end

return M
