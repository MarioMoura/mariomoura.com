+++
date = '2025-06-28T16:00:10-03:00'
draft = false
title = 'Neovimrc'
summary =  'My neovim config file'
[params]
    dotfile = true
+++

```lua
vim.g.mapleader = " "

vim.opt.number = true
vim.opt.clipboard = 'unnamedplus'
vim.opt.hidden = true
vim.opt.tabstop = 4
vim.opt.expandtab = false
vim.opt.shiftwidth = 4

vim.opt.smartindent = true
vim.opt.autoindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.hlsearch = true
vim.opt.encoding = "utf-8"
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.undofile = true

vim.opt.wildmenu = true
vim.opt.wildmode = "full"
vim.opt.wildignore = "*.o,*.obj,.terraform*,*.mov"
vim.opt.wildignorecase = true
vim.opt.wildoptions = "pum,tagfile,fuzzy"

vim.opt.mouse = "a"
vim.opt.conceallevel = 3
vim.opt.scrolloff = 999
vim.opt.cursorline = true
vim.opt.cursorlineopt = "both"
vim.opt.shortmess = "filnwxtToO"
vim.opt.ruler = true
vim.opt.signcolumn = "yes:2"

vim.opt.list = true
vim.opt.listchars = [[tab:┃ ]]

vim.opt.updatetime = 100

vim.cmd [[
colorscheme sorbet
highlight NonText ctermfg=245
highlight SpellBad cterm=underline ctermfg=11 ctermbg=16

filetype  plugin indent   on

highlight CurSearch           ctermfg = 255  ctermbg = 0
highlight Search              ctermfg = 11   ctermbg = 0
highlight IndentGuidesOdd                    ctermbg = 234
highlight IndentGuidesEven                   ctermbg = 233
highlight Conceal             ctermfg = 6    ctermbg  = 16
highlight Folded              ctermfg = 7    ctermbg  = 16
highlight Pmenu               ctermfg  = 255 ctermbg = 234
highlight jsObjectKey         ctermfg = 60
highlight jsObjectValue       ctermfg = 144
highlight jsxExpressionBlock  ctermfg = 144
highlight ExtraWhitespace                    ctermbg = red
match     ExtraWhitespace     /\s\+$/
]]

local ensure_packer = function()
	local fn = vim.fn
	local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
	if fn.empty(fn.glob(install_path)) > 0 then
		fn.system({ 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path })
		vim.cmd [[packadd packer.nvim]]
		return true
	end
	return false
end

local packer_bootstrap = ensure_packer()

require('packer').startup(function(use)
	use 'wbthomason/packer.nvim'

	use 'tpope/vim-fugitive'
	use 'lewis6991/gitsigns.nvim'
	use 'nvim-lualine/lualine.nvim'
	use 'neovim/nvim-lspconfig'
	use 'hashivim/vim-terraform'
	use {
		'nvim-telescope/telescope.nvim', tag = '0.1.8',
		requires = { { 'nvim-lua/plenary.nvim' } }
	}
	use({
		"iamcco/markdown-preview.nvim",
		run = function() vim.fn["mkdp#util#install"]() end,
	})

	-- Automatically set up your configuration after cloning packer.nvim
	-- Put this at the end after all plugins
	if packer_bootstrap then
		require('packer').sync()
	end
end)

-- GitSigns
require('gitsigns').setup {
	current_line_blame = true,
	signs = {
		add          = { text = '+' },
		change       = { text = '~' },
		delete       = { text = '-' },
		topdelete    = { text = '‾' },
		changedelete = { text = '~' },
		untracked    = { text = '┆' },
	},
}
vim.cmd [[
	highlight GitSignsAdd    ctermfg=10
	highlight GitSignsChange ctermfg=11
	highlight GitSignsDelete ctermfg=9
]]

require('lualine').setup {
	options = {
		theme = "gruvbox",
		always_show_tabline = true,
	},
	sections = {
		lualine_a = { 'mode' },
		lualine_b = { 'branch', 'diff', 'diagnostics' },
		lualine_c = { 'filename', 'filesize' },
		lualine_x = { 'encoding', 'fileformat', 'filetype' },
		lualine_y = { 'progress' },
		lualine_z = { 'location', 'searchcount' }
	},
	tabline = {
		lualine_a = { 'buffers' },
		lualine_b = {},
		lualine_c = {},
		lualine_x = {},
		lualine_y = { 'filename' },
		lualine_z = { 'tabs' }
	}
}


vim.diagnostic.config({
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = '',
			[vim.diagnostic.severity.WARN] = '',
			[vim.diagnostic.severity.HINT] = '',
		},
		numhl = {
			[vim.diagnostic.severity.WARN] = 'WarningMsg',
		},
	},
})
local lspconfig = require('lspconfig')
--vim.lsp.set_log_level 'debug'
lspconfig.lua_ls.setup {
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim" }
			}
		}
	}
}
lspconfig.harper_ls.setup {
	filetypes = {
		'gitcommit',
		'markdown',
		'text',
	},
	settings = {
		["harper-ls"] = {
			userDictPath = "~/.config/harper/dict.txt",
			diagnosticSeverity = "warning"
		}
	},
}
require 'lspconfig'.ltex.setup {
	filetypes = { 'tex' }
}
require 'lspconfig'.bashls.setup {}
require 'lspconfig'.pyright.setup {
	settings = {
		python = {
			pythonPath = '~/.local/python/bin/python' }
	}
}
require 'lspconfig'.ts_ls.setup {}
--require'lspconfig'.terraform_lsp.setup{}
require 'lspconfig'.terraformls.setup {}

vim.g.terraform_fmt_on_save = 1
vim.g.terraform_fold_sections = 1
vim.g.mkdp_auto_start = 1

vim.cmd(
	[[
function OpenMarkdownPreview (url)
endfunction
]]
)
--execute "silent ! firefox --new-window " . a:url
vim.g.mkdp_browserfunc = 'OpenMarkdownPreview'

vim.keymap.set('i', 'jk', '<esc>', { noremap = true })
vim.keymap.set('i', 'JK', '<esc>', { noremap = true })
vim.keymap.set('n', '<Leader><Space>', 'o<Esc>', { noremap = true })
vim.keymap.set('n', '<leader>l', '$', { noremap = true })
vim.keymap.set('n', '<leader>h', '^', { noremap = true })
vim.keymap.set('n', '<leader>q', ':bdelete<CR>', { noremap = true })
vim.keymap.set('n', '<leader>ss', ':up<CR>', { noremap = true })
vim.keymap.set('n', '<leader>tt', ':! st & disown<CR><CR>', { noremap = true })
vim.keymap.set('n', '<leader>pp', ':CtrlP<CR>', { noremap = true })
vim.keymap.set('n', '<leader>j', ':m .+1<CR>==', { noremap = true })
vim.keymap.set('n', '<leader>k', ':m .-2<CR>==', { noremap = true })
vim.keymap.set('i', '<C-j>', '<Esc>:m .+1<CR>==gi', { noremap = true })
vim.keymap.set('i', '<C-k>', '<Esc>:m .-2<CR>==gi', { noremap = true })
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv", { noremap = true })
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv", { noremap = true })

vim.keymap.set('n', '<C-l>', ":bn<CR>", { noremap = true })
vim.keymap.set('n', '<C-h>', ":bp<CR>", { noremap = true })

vim.keymap.set('o', 'q', [[i"]], { noremap = true })
vim.keymap.set('o', 'q', [[i"]], { noremap = true })
vim.keymap.set('o', 'l', [[$]], { noremap = true })
vim.keymap.set('o', 'h', [[^]], { noremap = true })
vim.keymap.set('o', 'p', [[i(]], { noremap = true })
vim.keymap.set('o', 'P', [[a(]], { noremap = true })
vim.keymap.set('o', 'b', [[i[]], { noremap = true })
vim.keymap.set('o', 'B', [[a[]], { noremap = true })
vim.keymap.set('o', 'c', [[i{]], { noremap = true })
vim.keymap.set('o', 'C', [[a{]], { noremap = true })

vim.keymap.set('n', 'ghr', [[:Gitsigns reset_hunk<CR>]], { noremap = true })
vim.keymap.set('n', 'ghs', [[:Gitsigns stage_hunk<CR>]], { noremap = true })
vim.keymap.set('n', 'ghu', [[:Gitsigns undo_stage_hunk<CR>]], { noremap = true })
vim.keymap.set('n', 'ghp', [[:Gitsigns nav_hunk prev<CR>]], { noremap = true })
vim.keymap.set('n', 'ghn', [[:Gitsigns nav_hunk next<CR>]], { noremap = true })

vim.keymap.set('n', '<C-g>s', [[:Git<CR>]], { noremap = true })
vim.keymap.set('n', '<C-g>l', [[:G gr<CR>]], { noremap = true })
vim.keymap.set('n', '<C-g>c', [[:G commit<CR>]], { noremap = true })
vim.keymap.set('n', '<C-g>w', [[:Gwrite<CR>]], { noremap = true })
vim.keymap.set('n', '<C-g>b', [[:G blame<CR>]], { noremap = true })
vim.keymap.set('n', '<C-g>ps', [[:G push<CR>]], { noremap = true })
vim.keymap.set('n', '<C-g>pl', [[:G pull<CR>]], { noremap = true })

vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', { noremap = true })
vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', { noremap = true })
vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', { noremap = true })
vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', { noremap = true })
vim.keymap.set('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>', { noremap = true })
vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', { noremap = true })
vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', { noremap = true })
vim.keymap.set('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>', { noremap = true })
vim.keymap.set({ 'n', 'x' }, '<F3>', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', { noremap = true })
vim.keymap.set('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>', { noremap = true })
vim.keymap.set('n', '<C-[>', '<cmd>lua vim.diagnostic.goto_prev()<CR>', { noremap = true })
vim.keymap.set('n', '<C-]>', '<cmd>lua vim.diagnostic.goto_next()<CR>', { noremap = true })

vim.keymap.set('n', '<leader>ff', '<cmd>Telescope find_files<cr>', { noremap = true })
vim.keymap.set('n', '<leader>fg', '<cmd>Telescope live_grep<cr>', { noremap = true })
vim.keymap.set('n', '<leader>fb', '<cmd>Telescope buffers<cr>', { noremap = true })
vim.keymap.set('n', '<leader>fh', '<cmd>Telescope help_tags<cr>', { noremap = true })

vim.cmd [[
inoreabbrev dont don't
inoreabbrev cant can't
inoreabbrev im i'm
inoreabbrev Im I'm
]]

vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = {
		"*.lua",
		"*.json",
		"*.ts",
		"*.tf"
	},
	callback = function()
		vim.lsp.buf.format()
	end
})

vim.cmd [[autocmd BufWritePost *.py silent! execute "!black " expand("%") " >/dev/null 2>&1" | redraw!]]

vim.cmd [[autocmd BufWritePost *.tex execute "!pdflatex " expand("%") ]]

vim.cmd [[autocmd BufWritePost *.json silent! execute "!prettier -w --parser json " expand("%") " >/dev/null 2>&1" | redraw!]]
```
