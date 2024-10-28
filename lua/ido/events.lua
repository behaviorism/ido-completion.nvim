local cmd = require("ido.cmd")
local config = require("ido.config")
local completion = require("ido.completion")

local M = {}

local debounce_timer = nil

local function check_debounce()
  -- Debounce so that rapid fire changes
  -- can be collected.
  -- Important for keymaps commands, which execute
  -- one character at a time.
  if debounce_timer and not debounce_timer:is_closing() then
    debounce_timer:stop()
    debounce_timer:close()
  end
end

function M.setup()
  -- Hijack autocompletion keys
  vim.keymap.set("c", "<Tab>", function() completion.cycle(1) end, { noremap = true })
  vim.keymap.set("c", "<S-Tab>", function() completion.cycle(-1) end, { noremap = true })

  -- Hijack submit for return matching
  vim.keymap.set("c", "<CR>", function()
    local completed = false

    -- Attempt matching submit
    if cmd.some_command_active(config.configuration.return_submits_commands) then
      completed = completion.attempt_confirm_match()
    end

    -- Attempt confirm prospect selection
    if not completed then
      -- If successful, prevent command submission
      -- with early return
      if completion.attempt_confirm() then
        return
      end
    end


    return "<CR>"
  end, { noremap = true, expr = true })

  -- Perform completion when typing in cmdline
  vim.api.nvim_create_autocmd("CmdlineChanged", {
    callback = function()
      -- Prevent recursion from editing completion on cmdline
      if cmd.is_editing() then return end

      check_debounce()

      debounce_timer = vim.defer_fn(completion.update_completion, 10)
    end
  })

  vim.api.nvim_create_autocmd("CmdlineLeave", {
    callback = function()
      -- Nothing to overwrite.
      -- Also happens with keymaps commands.
      if cmd.is_empty() then return end

      -- Cleanup completion before submitting command
      cmd.cleanup()
    end
  })
end

return M
