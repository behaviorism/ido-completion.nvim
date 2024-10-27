# ido.nvim

An Emacs-inspired Interactively Do Things (IDO) plugin for neovim. This plugin enhances the neovim command line by allowing interactive, fuzzy completion on the command-line prompt with customizable settings for command-specific behavior and display options.

## Installation

You can install this plugin using popular neovim plugin managers, such as Packer, vim-plug, or lazy.nvim. Here’s how to install with each:

### Using [Packer](https://github.com/wbthomason/packer.nvim)

```lua
use 'behaviorism/ido.nvim'
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'behaviorism/ido.nvim'
```

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'behaviorism/ido.nvim',
  config = function()
    require('ido').setup()
  end
}
```

After installing the plugin, restart neovim and run `:PackerSync`, `:PlugInstall`, or `:Lazy sync` depending on the plugin manager you use.

## Configuration

### Available Configuration Options

- **`max_prospects`** *(default: 12)*: Sets the maximum number of suggestions to display at once.
  
  ```lua
  -- Example: Limit suggestions to 8 options
  require('ido').setup {
      max_prospects = 8
  }
  ```

- **`active_commands`** *(default: `{}`)*: A list of specific commands where ido will be active. If left blank, it activates on all commands.

  ```lua
  -- Example: Enable ido only on `:buffer ` and `:e ` commands
  require('ido').setup {
      active_commands = { ':buffer ', ':e ' }
  }
  ```

- **`return_submits_commands`** *(default: `{}`)*: A list of commands where pressing Return will auto-complete and execute the command if there’s a matched suggestion.

  ```lua
  -- Example: Automatically submit commands for `:buffer` and `:bdelete`
  require('ido').setup {
      return_submits_commands = { ':buffer', ':bdelete' }
  }
  ```

### Keybindings

The default keybindings for cycling through ido suggestions are:
- **`Tab`** to select the next suggestion
- **`Shift-Tab`** to select the previous suggestion

These can be customized if needed by setting up your own key mappings within neovim.

### Full Example

```lua
require('ido').setup {
    max_prospects = 12,
    active_commands = { ':buffer ', ':e ' },
    return_submits_commands = { ':buffer' }
}
```

