 params = {...}
local tnt = params[1]

local argcheck = require 'argcheck'

local TableMeter = tnt.TableMeter
if (not TableMeter) then
   TableMeter = torch.class('tnt.TableMeter', 'tnt.Meter', tnt)
end

TableMeter.__init = argcheck{
   doc = [[
<a name="TableMeter">
#### tnt.TableMeter(@ARGP)

The `tnt.TableMeter` allows you to take in outputs from a `nn.ConcatTable` construct
that instead of a tensor returns a table of tensors. This is useful when working with
multilabel classification tasks where there may be a varying number of outputs.

@ARGT

If `k` or `names` are omitted then the meters will be created at the first `add` call

]],
   noordered = true,
   {name="self", type="tnt.TableMeter"},
   {name="k", type="number", opt=true,
    doc="The number of subelements to the `nn.ConcatTable`, i.e. table length."},
   {name="class", type="table", check=function(val)
      return val.add and val.new and val.value end,
    doc="A class for the meter that should be applied to each table element, e.g. tnt.AverageValueMeter"},
   {name="classargs", type="table", default={},
    doc="Arguments for the meter class"},
   call = function(self, k, class, classargs)
      self.meters = {}
      self.class = class
      self.classargs = classargs

      if (k) then
         self:_createMeters(k)
      end
   end
}

TableMeter.__init = argcheck{
   doc = [[
You can also use a table with names instead of a number for the number of meters.

@ARGT

]],
   overload=TableMeter.__init,
   noordered = true,
   {name="self", type="tnt.TableMeter"},
   {name="class", type="table", check=function(val)
      return val.add and val.new and val.value end,
    doc="A class for the meter that should be applied to each table element, e.g. tnt.AverageValueMeter"},
   {name="classargs", type="table", default={},
    doc="Arguments for the meter class"},
   {name="names", type="table",
    doc="The names for the different outcomes"},
   call = function(self, class, classargs, names)
      self.meters = {}
      self.class = class
      self.classargs = classargs or {}
      assert(#names > 0, "The names have to be an array with at least one element")
      self.names = names

      if (self.names) then
         self:_createMeters{
           k = #self.names
         }
      end
   end
}

TableMeter._createMeters = argcheck{
   {name="self", type="tnt.TableMeter"},
   {name="names", type="table", opt=true},
   noordered=true,
   call=function(names)

   if (names) then
     assert(#names > 0, "The names have to be an array with at least one element")
     self.names = names
   else
     assert(self.names, "There must be either a number of meters or a table with names")
   end

   return TableMeter._createMeters(#self.names)
end}

TableMeter._createMeters = argcheck{
   {name="self", type="tnt.TableMeter"},
   {name="k", type="number"},
   overload=TableMeter._createMeters,
   call=function(self, k)
      assert(k > 0, "The number of meters must be positive")
      if (self.names) then
         assert(k == #self.names, "The names and the number of meters must match")
      end

      for i=1,k do
         -- Named arguments for consructor then classargs[1] is nil
         if (self.classargs[1] == nil) then
            self.meters[i] = self.class(self.classargs)
         elseif(unpack) then
            -- Hack for Lua version compatibility
            self.meters[i] = self.class(unpack(self.classargs))
         else
            self.meters[i] = self.class(table.unpack(self.classargs))
         end
      end
   end
}

TableMeter.reset = argcheck{
   doc = [[
<a name="TableMeter.reset">
#### tnt.TableMeter.reset(@ARGP)
@ARGT

Resets the all the table submeters

]],
   {name="self", type="tnt.TableMeter"},
   call = function(self)
      for i=1,#self.meters do
         self.meters[i]:reset()
      end
   end
}

TableMeter.add = argcheck{
   doc = [[
<a name="TableMeter.add">
#### tnt.TableMeter.add(@ARGP)
@ARGT

Add results to the meter

]],
   {name="self", type="tnt.TableMeter"},
   {name="output", type="table"},
   {name="target", type="torch.*Tensor"},
   call = function(self, output, target)
      assert(#output == target:size(1),
            ([[Size error:
            The output  length (%d) doesn't match the length of the tensor's
            second dimension (%d). The first dimension in the target should be
            the batch size for tensors.]]):format(#output, target:size(1)))

      local table_target = {}
      for i=1,#output do
         table_target[i] = target[{{i},{}}]:squeeze():clone()
      end

      return self:add(output, table_target)
   end
}

TableMeter.add = argcheck{
   doc = [[
@ARGT
]],
   {name="self", type="tnt.TableMeter"},
   {name="output", type="table"},
   {name="target", type="table"},
   overload=TableMeter.add,
   call = function(self, output, target)
      assert(#output == #target,
             ("The output size (%d) and the target (%d) don't match"):format(#output, #target))

      if (not self.meters[1]) then
         self:_createMeters(#output)
      end
      assert(#output == #self.meters,
            ("The output size (%d) and the number of meters that you've specified (%d) don't match"):format(#output, #target))

      for i=1,#self.meters do
         self.meters[i]:add(output[i], target[i])
      end

   end
}

TableMeter.get_name_pos = argcheck{
  doc = [[
<a name="TableMeter.get_name_pos">
#### TableMeter.get_name_pos(@ARGP)
@ARGT

retriev the position of the named outcome

_Return value_: integer
]],
  {name="self", type="tnt.TableMeter"},
  {name="name", type="string", doc="The name of the paramter"},
  {name="forceExist", type="boolean", doc="Assert that the name exists"},
  call=function(self, name)
  assert(self.names, "There are no names set for this TableMeter")

  local k = nil
  for i,n in ipairs(self.names) do
    if (n == name) then
      k = i
      break
    end
  end

  if (forceExist) then
    if (not k) then
      local available_names = self.names[1]
      for i=2,#self.names do
        available_names = available_names .. ", " .. self.names[i]
      end
      assert(k, "The name " .. name .. " wasn't found within the available names: " .. available_names)
    end
  end

  return k
end}

TableMeter.value = argcheck{
   doc = [[
<a name="TableMeter.value">
#### tnt.TableMeter.value(@ARGP)
@ARGT

Retrieve the meters' value(s).

If you don't specify which parameter you want the return value is a table and
and not a single meters return value. If you have provided outcome names table
indexed by names otherwise it is numerically indexed.

_Return value_: table or particular meter value.
]],
   {name="self", type="tnt.TableMeter"},
   {name="parameters", type="table", default={},
      doc="Parameters that should be passed to the underlying meter"},
   {name="pack", type="boolean", opt=true,
      doc="Meters may return multiple values. By specifying pack=true then the values are packed using `table.pack`"},
   call = function(self, parameters, pack)
   if (parameters.pack and pack == nil) then
     pack = parameters.pack
     parameters = parameters.parameters
   end

   local value = {}
   for meter_no=1,#self.meters do
      if (pack) then
        value[meter_no] = table.pack(self:get_single_meter{
          k = meter_no,
          parameters = parameters
        })
      else
        value[meter_no] = self:get_single_meter{
          k = meter_no,
          parameters = parameters
        }
      end
   end

   if (not self.names) then
      return value
   end

   -- Add names to output
   ret = {}
   for meter_no=1,#self.meters do
      ret[self.names[meter_no]] = value[meter_no]
   end
   return ret
end}

TableMeter.get_single_meter = argcheck{
   doc = [[
<a name="TableMeter.get_single_meter">
#### TableMeter.get_single_meter(@ARGP)

Retrieves a single meter's value(s)

@ARGT

]],
   {name="self", type="tnt.TableMeter"},
   {name="name", type="string"},
   {name="parameters", type="table", opt=true,
      doc="Parameters that should be passed to the underlying meter"},
   call = function(self, name, parameters)
   -- Get the position of the name - throw error if not found
   local k = self:get_name_pos{
     name = name,
     forceExist = true
   }

   -- Run the true get_single_meter function
   if (parameters) then
     return self:get_single_meter{
       k = k,
       parameters = parameters
     }
   end

   return self:get_single_meter{
     k = k
   }
end}

TableMeter.get_single_meter = argcheck{
   doc = [[

@ARGT

]],
   {name="self", type="tnt.TableMeter"},
   {name="k", type="number"},
   {name="parameters", type="table", opt=true,
      doc="Parameters that should be passed to the underlying meter"},
   overload=TableMeter.get_single_meter,
   call = function(self, k, parameters)

  -- Odd hack as argcheck seems to encapsulate parameters inside its own table
  if (parameters and parameters.parameters) then
     parameters = parameters.parameters
  end

  assert(self.meters[k],
       ('invalid k (%d), i.e. there is no output corresponding to this meter'):format(k))

  if (not parameters) then
    return self.meters[k]:value()
  elseif (parameters[1] == nil) then
    return self.meters[k]:value(parameters)
  elseif(unpack) then
    -- Hack for Lua version compatibility
    return self.meters[k]:value(unpack(parameters))
  else
    return self.meters[k]:value(table.unpack(parameters))
  end
end}
