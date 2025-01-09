# `vimnotes`

## Installation and configuration

For example, using `junegunn/vim-plug`:

    Plug 'lseem/vimnotes'

And then `:PlugInstall`.

It would be worth adding something like the following to initiate the plug-in on a command; this is where the plugin is configured.

    function loadVN()
        require('vimnotes').setup({
            -- this is where the configuration goes, the following are the defaults
            -- required for pandoc
            homeDir = os.getenv("HOME"),
            notesPath = os.getenv("HOME") .. "/docs/notes",
            templatePath = os.getenv("HOME") .. "/docs/notes/tools/template.html",
            cslPath = os.getenv("HOME") .. "/docs/notes/tools/style.csl",
            -- copied over during creation of site
            cssPath = os.getenv("HOME") .. "/docs/notes/tools/style.css",
            searchNotesPath = os.getenv("HOME") .. "/docs/notes/tools/searchNotes.js",
            bibPath = os.getenv("HOME") .. "/docs/notes/tools/biblio.bib",
            -- further information about notes folder
            mdIndex = "index.md",
            port = "8000",
            browser = "firefox --new-window",
	        keymap_toggleCC = "<leader>lc",
            keymap_view = "<leader>lv"
        })
    end

    vim.api.nvim_create_user_command('VimNotes', loadVN, {})

## Usage

By default, `<leader>lc` begins the compiler and the HTTP server, and `<leader>lv` begins the browser.

## Licence

See `LICENSE`...
