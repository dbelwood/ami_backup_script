This toolset contains 4 scripts:
#provision
Provisions an analagous copy of the referred instance in a different region.  ***NOTE*** This only works with AMIs listed in the conf/images.yml file.  ***All options are required***
```bash
./bin/provision -instance-id=<instance-id> -source-region=<source-region> -target-region=<target-region> -target-az=<avalability-zone> -os=<os> -key_name=<key_pair_name>
```

#backup
Backs up all running instances with a tag of 'backup-count' in the designated region.  ***All options are required***
```bash
./bin/backup --region=<region>
```

#generate_keys
Generate shared key and install in provided regions. Run only once.  ***All options are required***
```bash
./bin/generate_keys --regions=<comma separated list of aws regions>
```

#sync - Currently Unfinishedc
Synchronize changes from one instance in source_region to target_region via rsync.  ***All options are required***
```bash
./bin/sync --instance_id=<instance_id> --source_region=<source_region> --target_region=<target_region>
```
