## What's this ?

A library for reload a lua service.

## Build

Modify the Makefile, change SKYNET_PATH to your path of skynet. The default path is $(HOME)/skynet .

```
cd skynet-reload
make 'PLATFORM'  # PLATFORM can be linux, macosx, freebsd now
```


## Test

```
$(HOME)/skynet test/config
```
