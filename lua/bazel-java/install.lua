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

  local last_percentage = -1
  local notify_record = nil

  local function update_progress(percentage)
    -- Throttle notifications to every 10% to avoid spamming
    if percentage >= last_percentage + 10 or percentage >= 100 then
      last_percentage = percentage
      local msg = string.format("Downloading Bazel Java extension: %d%%", percentage)
      -- If nvim-notify is available, it supports 'replace' to update the same notification
      notify_record = vim.notify(msg, vim.log.levels.INFO, {
        title = "Bazel Java",
        replace = notify_record,
      })
    end
  end

  vim.notify("Starting download...", vim.log.levels.INFO, { title = "Bazel Java" })

  vim.fn.jobstart({ "curl", "-L", "--compressed", "--progress-bar", "-o", zip_file, url }, {
    on_stderr = function(_, data)
      for _, line in ipairs(data) do
        local p = line:match("(%d+%.?%d*)%%")
        if p then
          update_progress(math.floor(tonumber(p)))
        end
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code ~= 0 then
        vim.notify("Failed to download Bazel extension (exit code: " .. exit_code .. ")", vim.log.levels.ERROR)
        return
      end

      vim.notify("Extracting extension...", vim.log.levels.INFO, { title = "Bazel Java", replace = notify_record })
      
      vim.fn.jobstart({ "unzip", "-o", zip_file, "-d", install_dir }, {
        on_exit = function(_, unzip_exit_code)
          if unzip_exit_code ~= 0 then
            if vim.fn.isdirectory(init.server_path) == 1 then
               vim.fn.delete(zip_file)
               vim.notify("Bazel Java extension installed! (Note: unzip reported warnings)", vim.log.levels.WARN)
               return
            end
            vim.notify("Failed to extract Bazel extension (exit code: " .. unzip_exit_code .. ")", vim.log.levels.ERROR)
            return
          end

          vim.fn.delete(zip_file)
          
          if vim.fn.isdirectory(init.server_path) == 1 then
            vim.notify("Bazel Java extension installed successfully! Please restart Neovim.", vim.log.levels.INFO, { title = "Bazel Java" })
          else
            vim.notify("Extraction appeared successful, but " .. init.server_path .. " was not found.", vim.log.levels.ERROR)
          end
        end,
      })
    end,
  })
end

return M
