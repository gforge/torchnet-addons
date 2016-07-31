argcheck = require 'argcheck'
paths = require 'paths'

-- Fix for earlier Lua version incompatibility
if (unpack) then
  table.unpack = unpack
end

paths.get_sorted_files  = argcheck{
	doc=[[
<a name="paths.get_sorted_lua_files">
### paths.get_sorted_lua_files(@ARGP)

Calls the `paths.files()` with the directory and sorts the files according to
name.

@ARGT

_Return value_: table with sorted file names
]],
	{name="path", type="string",
	 doc="The directory path"},
	{name="match_str", type="string", default="[.]lua$",
	 doc="The file matching string to search for. Defaults to lua file endings."},
	call=function(path, match_str)
	local files = {}
	for f in paths.files(path) do
	  if (f:match(match_str)) then
	    files[#files + 1] = f
	  end
	end

	table.sort(files)

	return files
end}
