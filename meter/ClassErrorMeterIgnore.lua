--[[
   Copyright (c) 2016-present, Facebook, Inc.
   All rights reserved.

   This source code is licensed under the BSD-style license found in the
   LICENSE file in the root directory of this source tree. An additional grant
   of patent rights can be found in the PATENTS file in the same directory.
]]--

local tnt = require 'torchnet.env'
local argcheck = require 'argcheck'

local ClassErrorMeterIgnore = torch.class('tnt.ClassErrorMeterIgnore', 'tnt.Meter', tnt)

ClassErrorMeterIgnore.__init = argcheck{
   doc = [[
<a name="ClassErrorMeterIgnore">
#### tnt.ClassErrorMeterIgnore(@ARGP)
@ARGT

The `tnt.ClassErrorMeterIgnore` measures the classification error (in %) of
classification models (zero-one loss). The meter can also measure the error of
predicting the correct label among the top-k scoring labels (for instance, in
the Imagenet competition, one generally measures classification@5 errors).

At initialization time, it takes to optional parameters: (1) a table
`topk` that contains the values at which the classification@k errors should be
measures (default = {1}); and (2) a boolean `accuracy` that makes the meter
output accuracies instead of errors (accuracy = 1 - error).

The `add(output, target)` method takes as input an NxK-tensor `output` that
contains the output scores for each of the N examples and each of the K classes,
and an N-tensor `target` that contains the targets corresponding to each of the
N examples (targets are integers between 1 and K). If only one example is
`add`ed, `output` may also be a K-tensor and target a 1-tensor.

Please note that `topk` (if specified) may not contain values larger than K.

The `value()` returns a table with the classification@k errors for all values
at k that were specified in `topk` at initialization time. Alternatively,
`value(k)` returns the classification@k error as a number; only values of `k`
that were element of `topk` are allowed. If `accuracy` was set to `true` at
initialization time, the `value()` method returns accuracies instead of errors.

The ignore parameter is the number for which the meter should skip analysis. By
default this is 0 since the output space is 1 -> no_classes.
]],
   noordered = true,
   {name="self", type="tnt.ClassErrorMeterIgnore"},
   {name="topk", type="table", default={1}},
   {name="accuracy", type="boolean", default=false},
   {name="ignore", type="number", default=0},
   call =
      function(self, topk, accuracy, ignore)
         self.topk = torch.LongTensor(topk):sort():totable()
         self.accuracy = accuracy
         self.ignore = ignore
         self:reset()
      end
}

ClassErrorMeterIgnore.reset = argcheck{
   {name="self", type="tnt.ClassErrorMeterIgnore"},
   call =
      function(self)
         self.sum = {}
         for _,k in ipairs(self.topk) do
            self.sum[k] = 0
         end
         self.n = 0
      end
}

ClassErrorMeterIgnore.add = argcheck{
   {name="self", type="tnt.ClassErrorMeterIgnore"},
   {name="output", type="torch.*Tensor"},
   {name="target", type="torch.*Tensor"},
   call =
      function(self, output, target)
         -- We need to keep track if variables should be converted to cuda-mode
         local inCudaMode = false
         if (torch.type(target):match("torch.Cuda")) then
           inCudaMode = true
         end

         -- For some reason the cuda functions arent always attached to the
         -- Tensor objects
         if (target.squeeze == nil) then
            assert(inCudaMode, "The squeeze function on the target tensor is missing - this should only happen in cuda")
            target = target:cuda()
            output = output:cuda()
         end
         target = target:squeeze()
         output = output:squeeze()
         if output:nDimension() == 1 then
            output = output:view(1, output:size(1))
            assert(
               type(target) == 'number',
               'target and output do not match')
            target = torch.Tensor(1):fill(target)
         else
            assert(
               output:nDimension() == 2,
               'wrong output size (1D or 2D expected)')
            assert(
               target:nDimension() == 1,
               'target and output do not match')
         end
         assert(
            target:size(1) == output:size(1),
            'target and output do not match')

         -- Calculate and apply the ignore mask for the data
         local mask = target:clone()
         if (mask.apply == nil) then
           assert(inCudaMode, "The apply function on the target tensor is missing - this should only happen in cuda")
           mask = mask:cuda()
         end
         mask:apply(function(var)
            if (var == self.ignore) then
               return 0
            else
               return 1
            end
         end)

         -- Convert mask to bytes
         if (inCudaMode) then
           mask = mask:cudaByte()
         else
           mask = mask:byte()
         end

         -- If you get: ....: invalid arguments: CudaTensor CudaByteTensor
         --             expected arguments: [*CudaTensor*] CudaTensor CudaTensor
         -- You may be running an old cuda-version (< 8)
         target = target:maskedSelect(mask)
         -- If all are missing then skip all calculations
         if (#target:size() == 0) then
            return
         end
         mask = mask:view(output:size(1), 1):expandAs(output)

         local rows = target:size(1)
         if (#output:size() < 2) then
            assert(false, "The output had too few dimensions")
         end
         local cols = output:size(2)
         output = output:maskedSelect(mask):resize(rows, cols)

         local topk = self.topk
         local maxk = topk[#topk]
         local no = output:size(1)
         local _, pred = output:double():topk(maxk, 2, true, true)
         local correct = pred:typeAs(target):eq(
            target:view(no, 1):expandAs(pred))

         for _,k in ipairs(topk) do
            self.sum[k] = self.sum[k] + no - correct:narrow(2, 1, k):sum()
         end
         self.n = self.n + no
      end
}

ClassErrorMeterIgnore.value = argcheck{
   {name="self", type="tnt.ClassErrorMeterIgnore"},
   {name="k", type="number", opt=true},
   call =
      function(self, k)
         if k then
            assert(self.sum[k], 'invalid k (this k was not provided at construction time)')
            return self.accuracy and (1-self.sum[k] / self.n)*100 or self.sum[k]*100 / self.n
         else
            local value = {}
            for _,k in ipairs(self.topk) do
               value[k] = self:value(k)
            end
            return value
         end
      end
}
