# bazel-java.nvim

A Neovim plugin to automatically set up Bazel support for Java using `nvim-jdtls`. This plugin downloads the necessary JARs from the `bazel-eclipse-vscode` extension and configures `jdtls` to use them.

## Features
- Automatic downloading and extraction of Bazel Java extensions.
- Registers Bazel commands (Sync, Update Classpaths, etc.).
- Adds keymaps via `which-key` (if available).
- Seamless integration with LazyVim's Java extra.

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "Chazmus/bazel-java.nvim",
},
{
  "mfussenegger/nvim-jdtls",
  dependencies = { "Chazmus/bazel-java.nvim" },
  opts = function(_, opts)
    -- jdtls requires Java 21+, specify the path if it's not your system default
    -- table.insert(opts.cmd, "--java-executable=/path/to/java-21/bin/java")

    require("bazel-java").setup_jdtls(opts)
  end,
}
```

## Setup

After installing the plugin, you need to download the required JARs by running:

```vim
:BazelJavaInstall
```

This will download the extension from the VS Code Marketplace and extract it to your Neovim data directory.

## Keymaps (if `which-key` is installed)

- `<leader>jbs`: Sync Projects
- `<leader>jbu`: Update Classpaths
- `<leader>jbd`: Sync Directories Only

## Acknowledgments
- [guw.bazel-eclipse-vscode](https://marketplace.visualstudio.com/items?itemName=guw.bazel-eclipse-vscode) for the underlying Bazel support.
- [nvim-jdtls](https://github.com/mfussenegger/nvim-jdtls) for the Java LSP client.
