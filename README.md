# paf2delta
Convert paf to delta format.
This script relay on the `cs` tags in the paf to determine the postions of indels.
Hence, the mapping commond should contain `--cs`:
```
minimap2 --cs target.fa query.fa > query_vs_target.paf
```

Then run:
```
perl paf2delta.pl query_vs_target.paf > query_vs_target.delta
```

The delta file generated can be used for `delta-filter`:
```
delta-filter -r -q -l 5000 query_vs_target.delta > query_vs_target.rq.delta
```


