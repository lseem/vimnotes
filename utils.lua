local M = {}

function M.replace_in_file(filepath, old, new)
-- Read the file
	local file = io.open(filepath, "r")
	if not file then
		print("Could not open file: " .. filepath)
		return
	end
	local content = file:read("*all")
	file:close()

	-- Perform the replacement
	content = content:gsub(old, new)

	-- Write the updated content back to the file
	file = io.open(filepath, "w")
	if not file then
		print("Could not write to file: " .. filepath)
		return
	end
	file:write(content)
	file:close()
end

function M.copy_file(source_path, dest_path)
	-- Open the source file in read mode
	local source_file = io.open(source_path, "rb")  -- "rb" for reading in binary mode
	if not source_file then
		print("Error: Could not open source file: " .. source_path)
		return
	end

	-- Read the entire content of the source file
	local content = source_file:read("*all")
	source_file:close()

	-- Open the destination file in write mode
	local dest_file = io.open(dest_path, "wb")  -- "wb" for writing in binary mode
	if not dest_file then
		print("Error: Could not open destination file: " .. dest_path)
		return
	end

	-- Write the content to the destination file
	dest_file:write(content)
	dest_file:close()
end

function M.touch(filename)
	local file = io.open(filename, "a")
	if file then
		file:close()
		return 0	-- success
	else
		error("Failed to create log for pandoc")
		return 1	-- fail
	end
end

return M
