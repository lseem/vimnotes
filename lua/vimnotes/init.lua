local utils = require("vimnotes.utils")
local config = require("vimnotes.config")

local M = {}

M.uservars = nil

M.compiler_group_id = nil
M.compiler_running = false
M.last_compile_job_id = nil

M.temp_dir = nil

function M.setup(user_config)
	config.setup(user_config)
	M.uservars = config.options
	vim.keymap.set("n", M.uservars.keymap_toggleCC, M.toggleCC, { desc = "Start vimnotes continuous compiler", noremap = true, silent = true })
	vim.keymap.set("n", M.uservars.keymap_view, M.view, { desc = "View notes in browser", noremap = true, silent = true })

	-- create the directory structure
	M.temp_dir = vim.fn.tempname()
	vim.loop.fs_mkdir(M.temp_dir, 493)
	local success, err = pcall(function()
		vim.loop.fs_mkdir(M.temp_dir .. "/site/", 493)	-- 493 is equivalent to '755' permissions
	end)
	if not success then
		print("Error creating directory: " .. err)
	else
		print("Directory created successfully!")
	end
end

function M.toggleCC()
	-- if it's on, turn it off
	if M.compiler_group_id ~= nil then
		vim.api.nvim_del_augroup_by_id(M.compiler_group_id)
		M.compiler_group_id = nil
		if M.compiler_running and M.last_compile_job_id then
			local success, result = pcall(vim.fn.jobwait, {last_compile_job_id}, 5000)
			if not success then
				print("Job wait failed or timed out.")
			end
		end
		return
	end
	-- otherwise, compile and turn it on
	M.notesCompiler()
	M.compiler_group_id = vim.api.nvim_create_augroup("CompilerGroup", {clear = true})
	vim.api.nvim_create_autocmd("BufWritePost", {
		group = M.compiler_group_id,
		callback = function()
			-- vim.fn.expand('%:t') is e.g. 'index.md' currently open buffer
			M.notesCompiler(vim.fn.expand('%:t'))
		end
	})
	print("Compiler started. Will recompile on file save.")
end

function M.startServer()
	vim.fn.jobstart("darkhttpd " .. M.temp_dir .. "/site --port " .. M.uservars.port)
end

function M.view()
	M.startServer()
	vim.fn.jobstart("firefox --new-window " .. "http://localhost:" .. M.uservars.port)
end

function M.mdToHTML(mdFilename, listItems)
	if mdFilename == nil then
		return
	else
		local htmlFilename = vim.fn.systemlist("basename " .. mdFilename .. " .md")[1] .. ".html"
		local htmlFilePath = M.temp_dir .. "/site/" .. htmlFilename
		local creationDate = vim.fn.system("cd " .. M.uservars.notesPath .. " && git log --follow --format='%ad' --date=short -- " .. mdFilename .. " | tail -n 1")
		local latestUpdateDate = vim.fn.system("cd " .. M.uservars.notesPath .. " && git log -n 1 --format='%ad' --date=short -- " .. mdFilename)
		local revisionNumber = vim.fn.system("cd " .. M.uservars.notesPath .. " && git rev-list HEAD --count -- " .. mdFilename)
		utils.copy_file(M.uservars.templatePath, M.temp_dir .. "/template.html")
		utils.replace_in_file(M.temp_dir .. "/template.html", "{creationDate}", creationDate)
		utils.replace_in_file(M.temp_dir .. "/template.html", "{latestUpdateDate}", latestUpdateDate)
		utils.replace_in_file(M.temp_dir .. "/template.html", "{revisionNumber}", revisionNumber)
		utils.replace_in_file(M.temp_dir .. "/template.html", "{listItems}", listItems)

		if utils.touch(M.temp_dir .. "/pandoc.log") == 0 then
			os.execute("pandoc --quiet -t html -s --toc --katex -N -M link-citations=true --citeproc --csl " .. M.uservars.cslPath .. " -o " .. htmlFilePath .. " " .. M.uservars.notesPath .. "/" .. mdFilename .. " --template=" .. M.temp_dir .. "/template.html --bibliography=" .. M.uservars.bibPath .. " ")
		else
			os.execute("pandoc --quiet -t html -s --toc --katex -N -M link-citations=true --citeproc --csl " .. M.uservars.cslPath .. " -o " .. htmlFilePath .. " " .. M.uservars.notesPath .. "/" .. mdFilename .. " --template=" .. M.temp_dir .. "/template.html --bibliography=" .. M.uservars.bibPath .. " ")
		end
		local notesList = "<ul>\n" .. listItems .. "\n</ul>"
		utils.replace_in_file(htmlFilePath, "{notesList}", notesList)
	end
end

function M.notesCompiler(priorityFile)
	if priorityFile == "index.md" then
		priorityFile = nil
	end
	local jsNotesList = "[\n"
	local listItemsPartialHTML = ""
	local mdFiles = {}
	local handle, err = vim.loop.fs_opendir(M.uservars.notesPath)
	if not handle then
		print("Error! Couldn't open directory " .. M.uservars.notesPath .. ": " .. err)
		return
	end
	local all_entries = {}
	while true do
		local entries, err = vim.loop.fs_readdir(handle)
		if err then
			print("Error reading directory: " .. err)
			break
		end
		if not entries or #entries == 0 then break end
		for _, entry in ipairs(entries) do
			if entry.name ~= priorityFile then
				table.insert(all_entries, entry)
			end
		end
	end
	if priorityFile ~= nil then	
		table.insert(all_entries, 1, { name = priorityFile })
	end
	local entries = all_entries
	for _, mdFile in ipairs(entries) do
		if mdFile.name ~= mdIndex and mdFile.name ~= "README.md" and mdFile.type == "file" then
			table.insert(mdFiles, mdFile.name)
			local creationDate = vim.fn.systemlist("cd " .. M.uservars.notesPath .. " && git log --follow --format='%ad' --date=short -- " .. mdFile.name .. " | tail -n 1")[1] or "N/A"
			local latestUpdateDate = vim.fn.systemlist("cd " .. M.uservars.notesPath .. " && git log -n 1 --format='%ad' --date=short -- " .. mdFile.name)[1] or "N/A"
			local noteBaseName = vim.fn.systemlist("basename " .. mdFile.name .. " .md")[1]
			local htmlLink = "/" .. noteBaseName .. ".html"
			local mdFileTitle = vim.fn.systemlist("awk '/^---$/ {flag = !flag; next} flag && /title:/ {sub(/^title: /, \"\"); print}' " .. mdFile.name)[1]
			jsNotesList = jsNotesList .. "{title: '" .. mdFileTitle .. "', href: '" .. htmlLink .. "', creationDate: '" .. creationDate .. "', latestUpdateDate: '" .. latestUpdateDate .. "' },\n"

			listItemsPartialHTML = listItemsPartialHTML .. "<li><a href=" .. htmlLink .. ">" .. mdFileTitle .. "</a><small>[created: " .. creationDate .. ", latest update: " .. latestUpdateDate .. "]</small></li>\n"
		end
	end

	vim.loop.fs_closedir(handle)
	jsNotesList = jsNotesList .. "];"

	for _, mdFilename in ipairs(mdFiles) do
		M.mdToHTML(mdFilename, listItemsPartialHTML)
	end

	M.mdToHTML(mdIndex, listItemsPartialHTML)
	utils.copy_file(M.uservars.cssPath, M.temp_dir .. "/site/style.css")
	utils.copy_file(M.uservars.searchNotesPath, M.temp_dir .. "/site/searchNotes.js")
	utils.replace_in_file(M.temp_dir .. "/site/searchNotes.js", "{jsNotesList}", jsNotesList)
end

return M
