local cmd = require("ido-completion.cmd")
local completion = require("ido-completion.completion")

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

local forced_return = false

function M.setup()
  -- Hijack autocompletion keys
  vim.keymap.set("c", "<Tab>", completion.select_next_prospect, { noremap = true })
  vim.keymap.set("c", "<S-Tab>", completion.select_previous_prospect, { noremap = true })

  -- Hijack submit for return matching
  vim.keymap.set("c", "<CR>", function()
    -- Reset forced return
    if forced_return then
      forced_return = false
      return "<CR>"
    end

    local submit = completion.handle_return()

    if submit then
      return "<CR>"
    end
  end, { noremap = true, expr = true })

  -- Forces return
  vim.keymap.set("c", "<C-g>", function()
    forced_return = true
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

  -- Show completion when opening cmdline
  vim.api.nvim_create_autocmd("CmdlineEnter", {
    callback = function()
      check_debounce()
      debounce_timer = vim.defer_fn(completion.update_completion, 10)
    end
  })

  vim.api.nvim_create_autocmd("CmdlineLeave", {
    callback = function()
      -- Nothing to overwrite.
      -- Also happens with keymaps commands.
      if cmd.is_empty() then return end

      completion.cleanup()
      -- Remove completion before submitting command
      cmd.cleanup()
    end
  })
end

return M
