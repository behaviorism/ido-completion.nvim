# ido.nvim

An Emacs-inspired [Interactively Do Things (IDO)](https://www.gnu.org/software/emacs/manual/html_mono/ido.html) plugin for neovim. This plugin enhances the neovim command line by allowing interactive, fuzzy completion on the command-line prompt with customizable settings for command-specific behavior and display options.

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

### Full Example

```lua
require('ido').setup {
    max_prospects = 12,
    active_commands = { ':buffer ', ':e ' },
    return_submits_commands = { ':buffer' }
}
```

### Keybindings

The default keybindings for cycling through ido suggestions are:
- **`Tab`** to select the next suggestion
- **`Shift-Tab`** to select the previous suggestion

These can be customized if needed by setting up your own key mappings within neovim.

### Matching Behavior

`ido.nvim` supports three of the four types of ido matching by default:

1. [**Interactive Substring Matching**](https://www.gnu.org/software/emacs/manual/html_node/ido/Interactive-Substring-Matching.html): Allows users to match substrings within the input dynamically as they type.

2. [**Prefix Matching**](https://www.gnu.org/software/emacs/manual/html_node/ido/Prefix-Matching.html): Matches suggestions that start with the given input.

3. [**Flexible Matching**](https://www.gnu.org/software/emacs/manual/html_node/ido/Flexible-Matching.html): Enables more lenient matching criteria, allowing you to find suggestions even if they don’t match the input exactly.

While interactive substring matching should perform reliably, the behavior of prefix and flexible matching may vary depending on neovim's internal function `matchfuzzy`.

### Additional Notes

- **Dotfiles Recognition**: When using a path segment that begins with a dot (e.g., `dotfiles/.dotfile`), ido.nvim will automatically look for dotfiles.
  
- **Color Highlighting Limitations**: Currently, neovim does not support color or style highlighting for individual segments within the command line text itself. As a result, highlighting in the command line is not supported.

