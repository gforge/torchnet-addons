<a name="TableMeter">
#### tnt.TableMeter(self[, k], class[, classargs])

The `tnt.TableMeter` allows you to take in outputs from a `nn.ConcatTable` construct
that instead of a tensor returns a table of tensors. This is useful when working with
multilabel classification tasks where there may be a varying number of outputs.

```
{
   self      = tnt.TableMeter  -- 
  [k         = number]         -- The number of subelements to the `nn.ConcatTable`, i.e. table length.
   class     = table           -- A class for the meter that should be applied to each table element, e.g. tnt.AverageValueMeter
  [classargs = table]          -- Arguments for the meter class [has default value]
}
```

If `k` or `names` are omitted then the meters will be created at the first `add` call

You can also use a table with names instead of a number for the number of meters.

```
{
   self      = tnt.TableMeter  -- 
   class     = table           -- A class for the meter that should be applied to each table element, e.g. tnt.AverageValueMeter
  [classargs = table]          -- Arguments for the meter class [has default value]
   names     = table           -- The names for the different outcomes
}
```

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
<a name="TableMeter.get_name_pos">
#### TableMeter.get_name_pos(self, name, forceExist)
```
({
   self       = tnt.TableMeter  -- 
   name       = string          -- The name of the paramter
   forceExist = boolean         -- Assert that the name exists
})
```

retriev the position of the named outcome

_Return value_: integer
<a name="TableMeter.value">
#### tnt.TableMeter.value(self[, parameters][, pack])
```
({
   self       = tnt.TableMeter  -- 
  [parameters = table]          -- Parameters that should be passed to the underlying meter [has default value]
  [pack       = boolean]        -- Meters may return multiple values. By specifying pack=true then the values are packed using `table.pack`
})
```

Retrieve the meters' value(s).

If you don't specify which parameter you want the return value is a table and
and not a single meters return value. If you have provided outcome names table
indexed by names otherwise it is numerically indexed.

_Return value_: table or particular meter value.
<a name="TableMeter.get_single_meter">
#### TableMeter.get_single_meter(self, name[, parameters])

Retrieves a single meter's value(s)

```
({
   self       = tnt.TableMeter  -- 
   name       = string          -- 
  [parameters = table]          -- Parameters that should be passed to the underlying meter
})
```


```
({
   self       = tnt.TableMeter  -- 
   k          = number          -- 
  [parameters = table]          -- Parameters that should be passed to the underlying meter
})
```

