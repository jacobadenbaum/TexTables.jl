
"""
```

```
"""
function Table(args...)
    return TableCol(args...) |> IndexedTable
end
