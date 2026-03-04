local M = {}

M.install_dir = vim.fn.stdpath("data") .. "/bazel-java"
-- The .vsix is actually just a zip, it will extract into an 'extension' folder
M.server_path = M.install_dir .. "/extension/server/"

function M.get_bundles()
  local java_extensions = {
    "org.eclipse.equinox.event.jar",
    "com.github.ben-manes.caffeine.jar",
    "org.apache.velocity.engine-core.jar",
    "org.jsr-305.jar",
    "org.fusesource.jansi.jar",
    "com.google.protobuf.jar",
    "com.salesforce.bazel.importedsource.jar",
    "com.salesforce.bazel.sdk.jar",
    "com.salesforce.bazel.eclipse.core.jar",
    "com.salesforce.bazel.eclipse.jdtls.jar",
  }

  local bundles = {}
  for _, jar in ipairs(java_extensions) do
    local jar_path = M.server_path .. jar
    if vim.fn.filereadable(jar_path) == 1 then
      table.insert(bundles, jar_path)
    end
  end
  return bundles
end

function M.setup_jdtls(opts)
  -- Support both LazyVim (opts.jdtls) and standard nvim-jdtls (opts)
  local target = opts.jdtls or opts

  -- 1. Add Bundles
  target.init_options = target.init_options or {}
  target.init_options.bundles = target.init_options.bundles or {}
  
  local bundles = M.get_bundles()
  if #bundles == 0 then
    -- Only notify if we are likely in a Java file within a Bazel project
    local markers = { "WORKSPACE", "MODULE.bazel", "BUILD.bazel", "BUILD" }
    local is_bazel = #vim.fs.find(markers, { upward = true, stop = vim.uv.os_homedir() }) > 0
    if is_bazel and vim.bo.filetype == "java" then
      vim.notify("Bazel Java JARs not found. Please run :BazelJavaInstall", vim.log.levels.WARN)
    end
  else
    -- Merge our bundles with any existing ones (like DAP/Test)
    for _, bundle in ipairs(bundles) do
      if not vim.tbl_contains(target.init_options.bundles, bundle) then
        table.insert(target.init_options.bundles, bundle)
      end
    end
  end

  -- 2. Register Bazel Commands
  target.init_options.extendedClientCapabilities = vim.tbl_deep_extend(
    "force",
    target.init_options.extendedClientCapabilities or {},
    {
      commands = {
        "java.bazel.syncProjects",
        "java.bazel.updateClasspaths",
        "java.bazel.syncDirectoriesOnly",
      },
    }
  )

  -- 3. Bazel Settings
  target.settings = vim.tbl_deep_extend("force", target.settings or {}, {
    java = {
      import = {
        bazel = { enabled = true, disabled = false },
      },
    },
    bazel = {
      projectview = { open = true },
    },
  })

  -- 4. Add Keymaps via autocmd to avoid signature issues
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and client.name == "jdtls" then
        local ok, wk = pcall(require, "which-key")
        if ok then
          wk.add({
            { mode = "n", buffer = args.buf, { "<leader>jb", group = "bazel" } },
            {
              "<leader>jbs",
              function()
                require("jdtls.util").execute_command({ command = "java.bazel.syncProjects" })
              end,
              desc = "Sync Projects",
              buffer = args.buf,
            },
            {
              "<leader>jbu",
              function()
                require("jdtls.util").execute_command({ command = "java.bazel.updateClasspaths" })
              end,
              desc = "Update Classpaths",
              buffer = args.buf,
            },
            {
              "<leader>jbd",
              function()
                require("jdtls.util").execute_command({ command = "java.bazel.syncDirectoriesOnly" })
              end,
              desc = "Sync Directories Only",
              buffer = args.buf,
            },
          })
        end
      end
    end,
  })
end

return M
