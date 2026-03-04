local M = {}

function M.install()
  local url = "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/guw/vsextensions/bazel-eclipse-vscode/1.5.0/vspackage"
  local init = require("bazel-java")
  local install_dir = init.install_dir
  local zip_file = install_dir .. "/extension.zip"

  if vim.fn.executable("curl") == 0 or vim.fn.executable("unzip") == 0 then
    vim.notify("curl and unzip are required for installation", vim.log.levels.ERROR)
    return
  end

  if vim.fn.isdirectory(install_dir) == 0 then
    vim.fn.mkdir(install_dir, "p")
  end

  vim.notify("Downloading Bazel Java extension...", vim.log.levels.INFO)

  -- Use --compressed to handle the Marketplace's gzip response
  vim.fn.jobstart({ "curl", "-L", "--compressed", "-o", zip_file, url }, {
    on_exit = function(_, exit_code)
      if exit_code ~= 0 then
        vim.notify("Failed to download Bazel extension (exit code: " .. exit_code .. ")", vim.log.levels.ERROR)
        return
      end

      vim.notify("Extracting extension...", vim.log.levels.INFO)
      
      -- VS Code extensions are actually zips. They usually contain an 'extension' folder.
      -- Unzip directly into the install_dir.
      vim.fn.jobstart({ "unzip", "-o", zip_file, "-d", install_dir }, {
        on_exit = function(_, unzip_exit_code)
          if unzip_exit_code ~= 0 then
            -- Fallback: check if the file is actually a zip despite potential errors
            if vim.fn.isdirectory(init.server_path) == 1 then
               vim.fn.delete(zip_file)
               vim.notify("Bazel Java extension installed! (Note: unzip reported warnings)", vim.log.levels.WARN)
               return
            end
            vim.notify("Failed to extract Bazel extension (exit code: " .. unzip_exit_code .. ")", vim.log.levels.ERROR)
            return
          end

          vim.fn.delete(zip_file)
          
          -- Verify the expected directory exists
          if vim.fn.isdirectory(init.server_path) == 1 then
            vim.notify("Bazel Java extension installed successfully! Please restart Neovim.", vim.log.levels.INFO)
          else
            vim.notify("Extraction appeared successful, but " .. init.server_path .. " was not found.", vim.log.levels.ERROR)
          end
        end,
      })
    end,
  })
end

return M
