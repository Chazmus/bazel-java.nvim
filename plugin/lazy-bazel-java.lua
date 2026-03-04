if vim.g.loaded_lazy_bazel_java then
  return
end
vim.g.loaded_lazy_bazel_java = 1

vim.api.nvim_create_user_command("BazelJavaInstall", function()
  require("lazy-bazel-java.install").install()
end, { desc = "Download and install the Bazel Java extension JARs" })
