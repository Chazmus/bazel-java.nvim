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
  -- 1. Add Bundles
  opts.jdtls = opts.jdtls or {}
  opts.jdtls.init_options = opts.jdtls.init_options or {}
  opts.jdtls.init_options.bundles = opts.jdtls.init_options.bundles or {}
  
  local bundles = M.get_bundles()
  if #bundles == 0 then
    vim.notify("Bazel Java JARs not found. Please run :BazelJavaInstall", vim.log.levels.WARN)
    return
  end
  
  -- Merge our bundles with any existing ones (like DAP/Test)
  for _, bundle in ipairs(bundles) do
    if not vim.tbl_contains(opts.jdtls.init_options.bundles, bundle) then
      table.insert(opts.jdtls.init_options.bundles, bundle)
    end
  end

  -- 2. Register Bazel Commands
  opts.jdtls.init_options.extendedClientCapabilities = vim.tbl_deep_extend(
    "force",
    opts.jdtls.init_options.extendedClientCapabilities or {},
    {
      commands = {
        "java.bazel.syncProjects.command",
        "java.bazel.updateClasspaths.command",
        "java.bazel.syncDirectoriesOnly.command",
      },
    }
  )

  -- 3. Bazel Settings
  opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, {
    java = {
      import = {
        bazel = { enabled = true, disabled = false },
      },
    },
    bazel = {
      projectview = { open = true },
    },
  })

  -- 4. Add Keymaps
  local on_attach = opts.on_attach
  opts.on_attach = function(args)
    if on_attach then
      on_attach(args)
    end
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == "jdtls" then
      local ok, wk = pcall(require, "which-key")
      if ok then
        wk.add({
          { mode = "n", buffer = args.buf, { "<leader>jb", group = "bazel" } },
          {
            "<leader>jbs",
            function()
              require("jdtls.util").execute_command({ command = "java.bazel.syncProjects.command" })
            end,
            desc = "Sync Projects",
            buffer = args.buf,
          },
          {
            "<leader>jbu",
            function()
              require("jdtls.util").execute_command({ command = "java.bazel.updateClasspaths.command" })
            end,
            desc = "Update Classpaths",
            buffer = args.buf,
          },
          {
            "<leader>jbd",
            function()
              require("jdtls.util").execute_command({ command = "java.bazel.syncDirectoriesOnly.command" })
            end,
            desc = "Sync Directories Only",
            buffer = args.buf,
          },
        })
      end
    end
  end
end

return M
