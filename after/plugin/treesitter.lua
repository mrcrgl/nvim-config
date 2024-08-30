require("nvim-treesitter.install").prefer_git = true

-- local parser_path = vim.fn.stdpath("data") .. "/treesitter"
require'nvim-treesitter.configs'.setup {
  -- A list of parser names, or "all" (the five listed parsers should always be installed)
  ensure_installed = { "typescript", "javascript", "c", "lua", "rust", "vim", "vimdoc", "query" },

  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,

  -- Automatically install missing parsers when entering buffer
  -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
  auto_install = true,

  -- List of parsers to ignore installing (or "all")
  ignore_install = { },

  ---- If you need to change the installation directory of the parsers (see -> Advanced Setup)
  -- parser_install_dir = parser_path, 
  -- Remember to run vim.opt.runtimepath:append("/some/path/to/store/parsers")!
  --
  modules = {},

  highlight = {
    enable = true,

    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = false,
  },
}
-- vim.opt.runtimepath:append(parser_path)
