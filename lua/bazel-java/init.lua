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

  local markers = { "WORKSPACE", "MODULE.bazel", "BUILD.bazel", "BUILD" }
  
  -- Use current buffer's directory or cwd to find bazel root
  local search_path = vim.fn.expand("%:p:h")
  if search_path == "" or not vim.uv.fs_stat(search_path) then
    search_path = vim.fn.getcwd()
  end
  local bazel_match = vim.fs.find(markers, { path = search_path, upward = true, stop = vim.uv.os_homedir() })
  local is_bazel = #bazel_match > 0
  local bazel_root = is_bazel and vim.fs.dirname(bazel_match[1]) or nil

  vim.notify("[bazel-java] is_bazel detected as: " .. tostring(is_bazel), vim.log.levels.INFO)

  -- 1. Add Bundles
  target.init_options = target.init_options or {}
  target.init_options.bundles = target.init_options.bundles or {}
  
  local bundles = M.get_bundles()
  if #bundles == 0 then
    -- Only notify if we are likely in a Java file within a Bazel project
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

  -- 3. Bazel Settings & Root Dir
  local import_settings = {
    bazel = { enabled = true, disabled = false },
  }

  if is_bazel then
    -- Prioritize Bazel by disabling competing build systems
    import_settings.maven = { enabled = false }
    import_settings.gradle = { enabled = false }
    vim.notify("[bazel-java] Disabled Maven and Gradle imports in jdtls settings", vim.log.levels.INFO)

    -- Force the root_dir to the bazel workspace to prevent jdtls from anchoring to a pom.xml
    if bazel_root then
      local orig_root_dir = target.root_dir
      target.root_dir = function(path)
        -- Still allow dynamic resolution, but prioritize bazel markers
        local root = vim.fs.root(path, markers)
        if root then return root end
        if type(orig_root_dir) == "function" then
          return orig_root_dir(path)
        elseif orig_root_dir then
          return orig_root_dir
        end
        return bazel_root
      end
    end

    -- Disable build configuration updates that might trigger maven
    target.settings = target.settings or {}
    target.settings.java = target.settings.java or {}
    target.settings.java.configuration = target.settings.java.configuration or {}
    target.settings.java.configuration.updateBuildConfiguration = "disabled"
  end

  target.settings = vim.tbl_deep_extend("force", target.settings or {}, {
    java = {
      import = import_settings,
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
