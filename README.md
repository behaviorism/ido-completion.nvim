# ido-completion.nvim

An Emacs-inspired [Interactively Do Things (IDO)](https://www.gnu.org/software/emacs/manual/html_mono/ido.html) completion plugin for neovim. This plugin enhances the neovim command line by allowing interactive, fuzzy completion on the command-line prompt with customizable settings for command-specific behavior and display options.

## Installation

You can install this plugin using popular neovim plugin managers, such as Packer, vim-plug, or lazy.nvim. Here’s how to install with each:

### Using [Packer](https://github.com/wbthomason/packer.nvim)

```lua
use 'behaviorism/ido-completion.nvim'
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'behaviorism/ido-completion.nvim'
```

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'behaviorism/ido-completion.nvim',
  config = function()
    require('ido-completion').setup()
  end
}
```

After installing the plugin, restart neovim and run `:PackerSync`, `:PlugInstall`, or `:Lazy sync` depending on the plugin manager you use.

## Configuration

### Available Configuration Options

- **`max_prospects`** *(default: 12)*: Sets the maximum number of suggestions to display at once.
  
  ```lua
  -- Example: Limit suggestions to 8 options
  require('ido-completion').setup {
      max_prospects = 8
  }
  ```

- **`active_commands`** *(default: `{}`)*: A list of specific commands where IDO will be active. If left blank, it activates on all commands.

  ```lua
  -- Example: Enable IDO only on `:buffer ` and `:e ` commands
  require('ido-completion').setup {
      active_commands = { ':buffer ', ':e ' }
  }
  ```

- **`inactive_commands`** *(default: `{}`)*: A list of commands where IDO will be inactive. If left blank, IDO will be active on every command except for inactive commands.

  ```lua
  -- Example: Disable IDO on the `:help` command
  require('ido-completion').setup {
      inactive_commands = { ':help' }
  }
  ```

- **`match_submits_commands`** *(default: `{" :find", ":e", ":buffer"}`)*: A list of commands where pressing Return or Tab when there is a single prospect will auto-complete and execute the command (except for directories). Useful for buffers and files.

  ```lua
  -- Example: Automatically submit commands for `:find` and `:edit`
  require('ido-completion').setup {
      match_submits_commands = { ":find", ":e" }
  }
  ``` 

### Keybindings

The default keybindings for cycling through ido suggestions are:
- **`Tab`** to select the next suggestion
- **`Shift-Tab`** to select the previous suggestion
- **`RET`** to confirm the current selection or submit if there are no other matches
- **`Ctrl-g`** to force submission of current command (i.e.: directories instead of files)

### Matching Behavior

Three of the four types of ido matching are supported by default:

1. [**Interactive Substring Matching**](https://www.gnu.org/software/emacs/manual/html_node/ido/Interactive-Substring-Matching.html): Allows to match substrings within the input dynamically as they type.

2. [**Prefix Matching**](https://www.gnu.org/software/emacs/manual/html_node/ido/Prefix-Matching.html): Matches suggestions that start with the given input.

3. [**Flexible Matching**](https://www.gnu.org/software/emacs/manual/html_node/ido/Flexible-Matching.html): Enables more lenient matching criteria, allowing to find suggestions even if they don’t match the input exactly.

While interactive substring matching should perform reliably, the behavior of prefix and flexible matching may vary depending on neovim's internal function [`matchfuzzy`](https://neovim.io/doc/user/builtin.html#matchfuzzy).

### Additional Notes

- **Color Highlighting Limitations**: Currently, neovim does not support color or style highlighting for individual segments within the command line text itself. As a result, highlighting in the command line is not supported.

