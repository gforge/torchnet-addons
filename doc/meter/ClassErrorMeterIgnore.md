<a name="ClassErrorMeterIgnore">
#### tnt.ClassErrorMeterIgnore(self[, topk][, accuracy][, ignore])
```
{
   self     = tnt.ClassErrorMeterIgnore  -- 
  [topk     = table]                     --  [has default value]
  [accuracy = boolean]                   --  [default=false]
  [ignore   = number]                    --  [default=0]
}
```

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
