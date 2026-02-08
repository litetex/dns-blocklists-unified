# Unified DNS blocklists

Build:
``docker build -t dblu .``

Run:
```
docker network create --ipv6 blocklists-net || echo "Already exists"
docker run --rm -it -v %cd%\source:/workdir -v %cd%\source_cached_remote_lists:/source_cached_remote_lists -v %cd%\out\blocklists:/out -e OUT_FILE=/out/unified-hosts-blocklist.txt --network=blocklists-net dblu
docker network rm blocklists-net || echo "Failed to remove"
```
