
# Xid for Nim lang

> NOTE:
> Would be disordered in a second when counter overflow 3bytes.
> Not applicable to scenarios where ordered data is imported in batches.
> A simple solution: 
> Compare the id generated each time with the last one. If it is less than the last generated id, wait for a while and try again.


## Resources

- [xid go](https://github.com/rs/xid)
- [xid rust](https://github.com/kazk/xid-rs)


## Run tests

```sh
nimble test
```


## Run bench

```sh
nimble bench
```
