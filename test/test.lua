local init_file = paths.thisfile():gsub("test/test.lua$", "init.lua")
local tnt = paths.dofile(init_file)

local tester = torch.Tester()
tester:add(paths.dofile('meters.lua')(tester))

function tnt.test(tests)
   tester:run(tests)
   return tester
end

if #arg > 0 then
   tnt.test(arg)
else
   tnt.test()
end
