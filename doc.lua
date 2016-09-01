local argdoc = require 'argcheck.doc'
local paths = require 'paths'
local tnt = require 'torchnet'

local base_path = paths.thisfile():gsub("doc.lua$", "?.lua")

-- Make utils available to all
local utils_file = base_path:gsub("?", "utils")
assert(loadfile(utils_file))()

if (not paths.dirp("doc")) then
  paths.mkdir("doc")
end

for _,type in pairs({"dataset", "engine", "log", "meter", "utils"}) do
  -- Load all extensions, i.e. .lua files in extensions directory
  local tnt_path = base_path:gsub("[^/]+$", "") ..  type .. "/"
  if (paths.dirp(tnt_path)) then

    local doc_type_path =  "doc/" .. type .. "/"
    if (not paths.dirp(doc_type_path)) then
      paths.mkdir(doc_type_path)
    end

    local tnt_files = paths.get_sorted_files(tnt_path)
    for _, file_name in pairs(tnt_files) do
      if (file_name:match("[.]lua$")) then
        local full_path = tnt_path .. file_name

        -- Documentation
        local doc_filename = file_name:gsub(".lua",".md")
        local doc_file = io.open(doc_type_path .. doc_filename, "w")
        argdoc.record()

        assert(loadfile(full_path))(tnt)

        content = argdoc.stop()

        doc_file:write(content)
        doc_file:close()
      end
    end
  end
end
