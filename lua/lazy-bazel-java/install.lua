local M = {}

function M.install()
  local url = "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/guw/vsextensions/bazel-eclipse-vscode/1.5.0/vspackage"
  local install_dir = require("lazy-bazel-java").install_dir
  local zip_file = install_dir .. "/extension.zip"

  if vim.fn.executable("curl") == 0 or vim.fn.executable("unzip") == 0 then
    vim.notify("curl and unzip are required for installation", vim.log.levels.ERROR)
    return
  end

  if vim.fn.isdirectory(install_dir) == 0 then
    vim.fn.mkdir(install_dir, "p")
  end

  vim.notify("Downloading Bazel Java extension...", vim.log.levels.INFO)

  vim.fn.jobstart({ "curl", "-L", "-o", zip_file, url }, {
    on_exit = function(_, exit_code)
      if exit_code ~= 0 then
        vim.notify("Failed to download Bazel extension (exit code: " .. exit_code .. ")", vim.log.levels.ERROR)
        return
      end

      vim.notify("Extracting extension...", vim.log.levels.INFO)
      -- Unzip and overwrite (-o)
      local out = vim.fn.system({ "unzip", "-o", zip_file, "-d", install_dir })
      if vim.v.shell_error ~= 0 then
        vim.notify("Failed to extract Bazel extension: " .. out, vim.log.levels.ERROR)
        return
      end

      vim.fn.delete(zip_file)
      vim.notify("Bazel Java extension installed successfully! Please restart Neovim.", vim.log.levels.INFO)
    end,
  })
end

return M
