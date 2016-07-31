<a name="TableMeter">
#### tnt.TableMeter(self[, k], class[, classargs])
```
{
   self      = tnt.TableMeter  -- 
  [k         = number]         -- The number of subelements to the `nn.ConcatTable`, i.e. table length.
   class     = table           -- A class for the meter that should be applied to each table element, e.g. tnt.AverageValueMeter
  [classargs = table]          -- Arguments for the meter class [has default value]
}
```

The `tnt.TableMeter` allows you to take in outputs from a `nn.ConcatTable` construct
that instead of a tensor returns a table of tensors. This is useful when working with
multilabel classification tasks where there may be a varying number of outputs.

If `k` is omitted then the meters will be created at the first `add` call

<a name="TableMeter.reset">
#### tnt.TableMeter.reset(self)
```
({
   self = tnt.TableMeter  -- 
})
```

Resets the all the table submeters

<a name="TableMeter.add">
#### tnt.TableMeter.add(self, output, target)
```
({
   self   = tnt.TableMeter  -- 
   output = table           -- 
   target = torch.*Tensor   -- 
})
```

Add results to the meter

```
({
   self   = tnt.TableMeter  -- 
   output = table           -- 
   target = table           -- 
})
```
<a name="TableMeter.value">
#### tnt.TableMeter.value(self[, k][, parameters])
```
({
   self       = tnt.TableMeter  -- 
  [k          = number]         -- 
  [parameters = table]          -- Parameters that should be passed to the underlying meter
})
```

Retrieve the individual meters' values as a table

_Return value_: table
