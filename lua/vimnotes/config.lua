local M = {}

M.defaults = {
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
}

function M.setup(user_config)
	M.options = vim.tbl_deep_extend("force", M.defaults, user_config or {})
end

return M
