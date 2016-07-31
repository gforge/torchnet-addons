local tnt = require 'torchnet'
local doc = require 'argcheck.doc'

local params = {...}
local skip_load = params[1]

-- The README file is generated here
doc[[
[![Build Status](https://travis-ci.org/gforge/torchnet-addons.svg)](https://travis-ci.org/gforge/torchnet-addons)

# torchnet-addons

The torchnet-addons package contains extensions to the [torchnet](https://github.com/torchnet/torchnet).

## The documentation

The documentation is generated via the `doc.lua` script. Note that this has to be
invoked with `> /dev/null` in order to avoid sundown-ascii codes to appear:

`th doc.lua > /dev/null`

]]

-- This is a solution that allows the doc.lua to run the loader twice
if (not skip_load and not __TORCHNET_ADDONS_INIT__) then
  local base_path = paths.thisfile():gsub("init.lua$", "?.lua")

  local utils_file = base_path:gsub("?", "utils")
  assert(loadfile(utils_file))()

  for _,type in pairs({"dataset", "engine", "log", "meter", "utils"}) do
    -- Load all extensions, i.e. .lua files in extensions directory
    local tnt_path = base_path:gsub("[^/]+$", "") ..  type .. "/"
    if (paths.dirp(tnt_path)) then

      local tnt_files = paths.get_sorted_files(tnt_path)
      for _, file_name in pairs(tnt_files) do
        if (file_name:match("[.]lua$")) then
          local full_path = tnt_path .. file_name

          assert(loadfile(full_path), "Failed to load: " .. full_path)(tnt)

        end
      end -- end for each file in subdir

    end
  end-- end for dir

end
__TORCHNET_ADDONS_INIT__ = true

return tnt
