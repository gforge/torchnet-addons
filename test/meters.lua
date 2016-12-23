local tnt = require 'torchnet.env'

-- CUDA testing on Travis is just painful...
if not os.getenv("TRAVIS_TEST") then
   require 'cutorch'
end

local tester
local test = torch.TestSuite()

function test.AverageValueMeter()
   local mtr = tnt.AverageValueMeter()

   mtr:add(1)
   local avg, var = mtr:value()

   tester:eq(avg, 1)
   tester:assert(var ~= var, "Variance for a single value is undefined")

   mtr:add(3)
   avg, var = mtr:value()

   tester:eq(avg, 2)
   tester:eq(var, math.sqrt(2))
end

function test.ClassErrorMeter()
   local mtr = tnt.ClassErrorMeter{topk = {1}}

   local output = torch.Tensor({{1,0,0},{0,1,0},{0,0,1}})
   local target = torch.Tensor({1,2,3})
   mtr:add(output, target)
   local error = mtr:value()

   tester:eq(error, {0}, "All should be correct")

   target[1] = 2
   target[2] = 1
   target[3] = 1
   mtr:add(output, target)

   error = mtr:value()
   tester:eq(error, {50}, "Half, i.e. 50%, should be correct")
end

function test.ClassErrorMeterIgnore()
   local mtr = tnt.ClassErrorMeterIgnore{topk = {1}, ignore=0}

   local output = torch.Tensor({{1,0,0},{0,1,0},{0,0,1}})
   local target = torch.Tensor({1,2,3})
   mtr:add(output, target)
   local error = mtr:value()

   tester:eq(error, {0}, "All should be correct")

   target[1] = 2
   target[2] = 1
   target[3] = 1
   mtr:add(output, target)

   error = mtr:value()
   tester:eq(error, {50}, "Half, i.e. 50%, should be wrong")

   -- Now add ignore
   mtr:reset()
   local output = torch.Tensor({{1,0,0},{1,0,0},{0,0,1}})
   local target = torch.Tensor({1,0,3})
   mtr:add(output, target)
   local error = mtr:value()

   tester:eq(error, {0}, "All should be correct")

   target[1] = 0
   target[2] = 1 -- correct
   target[3] = 1 -- wrong
   mtr:add(output, target)

   error = mtr:value()
   tester:eq(error, {(1)/(1+1+1+1)*100},
             "Half, i.e. 25%, should be wrong")


   target[1] = 0
   target[2] = 0 -- correct
   target[3] = 0 -- wrong
   mtr:add(output, target)

   error = mtr:value()
   tester:eq(error, {(1)/(1+1+1+1)*100},
             "All ignore should not change results, i.e. 25%, should be wrong")

   if not os.getenv("TRAVIS_TEST") then

      mtr:reset()
      local output = torch.Tensor({{1,0,0},{1,0,0},{0,0,1}}):cuda()
      local target = torch.Tensor({1,0,3}):cudaDouble()
      mtr:add(output, target)
      local error = mtr:value()

      tester:eq(error, {0}, "All should be correct in cuda mode")

      target[1] = 0
      target[2] = 1
      target[3] = 1
      mtr:add(output, target)

      error = mtr:value()
      tester:eq(error, {(1)/(1+1+1+1)*100},
                "Half, i.e. 25%, should be wrong in cuda mode")
   end
end

function test.TableMeter()
   local mtr = tnt.TableMeter{
      class =  tnt.ClassErrorMeter,
      classargs = {topk = {1}}
   }

   local output = {
      torch.Tensor{
         {1,0,0},
         {0,1,0},
         {0,0,1}
      },
      torch.Tensor{
         {1,0},
         {0,1},
         {0,1}
      }
   }

   local target = torch.Tensor{
      {1,2,3},
      {1,2,2}
   }

   mtr:add(output, target)
   local error = mtr:value()
   tester:eq(error, {{0}, {0}}, "All should be correct")

   target = torch.Tensor{
      {2,1,2},
      {2,1,1}
   }
   mtr:add(output, target)

   error = mtr:value()
   tester:eq(error, {{50}, {50}}, "Half should be correct")

   error = mtr:value{parameters = {k = 1}}
   tester:eq(error, {50, 50}, "Should be able to pass parameters to sub-meter")

   -- Test with names
   local mtr = tnt.TableMeter{
      class =  tnt.ClassErrorMeter,
      classargs = {topk = {1}},
      names = {"one", "two"}
   }

   target = torch.Tensor{
      {1,2,3},
      {1,2,2}
   }

   mtr:add(output, target)
   local error = mtr:value()
   tester:eq(error, {
     one = {0},
     two = {0}}, "Failed to produce named meters")

   tester:eq(mtr:value{pack=true},{
     one = {{0}, n= 1},
     two = {{0}, n= 1}}, "Failed to produce packed named meters")
end

return function(_tester_)
   tester = _tester_
   return test
end
