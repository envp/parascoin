# ParasCoin

> Paras (पारस) (pārasa  paarasa) the hindi equivalent of midas or the philosopher's stone

This project creates a cryptocurrency miner network that looks for strings whose `SHA256` has `k` leading zeros, `k` being fixed for each network

## Building the code

Use `mix escript.build` to generate a local escript called `project1`

## Discussion

* Work unit size:

```
@TODO
```

* Output of `./project1 4`:
```
$ ./project1 4
vyenaman;7P33   0000d9d41ef9a43600d7b68d5da894a3a742ab3d537ab2b891c9495615d462d3
vyenaman;9jf    0000c579d6e3192f246c878f4677009b43810f1eb226d00d13105df1f81ef1e1
vyenaman;13wW   00005c23b92b2014fa7f1e5b23d8e439b6e8bd062552329e743d59c9ca15ccd6
vyenaman;38Gc   00005e2ca9dc57215e6b7b0a0a71789cc5f344da7c8d86a91008e5be5e1a97c1
vyenaman;23kG   0000c3119ef5acf8544fb171901e89304792ba5e0a72ab633b5f97906395d125
vyenaman;44hq   0000f9f0ff04a46c936daad283bb00d235166a60d696e6278927df843b708f41
vyenaman;1yZI   0000b0ca35d295506dcc276c02678e07a3f673eafd5971ea813218a3cdc45236
vyenaman;3vdy   00001e8148d1064236c27b732db94f35bb29aedd3f03c23a7e4769d2713b3149
vyenaman;jIG    000020da1264d27e70445c34d8ffb2135f5868adb984c4bf543f3dfbde42a5d7
vyenaman;3nTq   000063a8b050ec898693210429ad6b4a19ea7309343b8dd60d502786014f76fc
vyenaman;20Ot   00009952cccea79519607608f20c03d9446e4181f7350ceb353e4f9409621250
vyenaman;1mAC   0000a6c23fd7e2bee126422e93ad70ea27c7ebce3136096b5ef6caecf976ddfe
vyenaman;1xsE   0000f29d6f8592ad49a03fa468d107d6f4c9723bb1e97fba26af203742e31a9c
vyenaman;d5x7   00002dd38f58c64e7a2edb2d0ee887c6d791199ef82a5e3720d899d67e15c6d0
```

* Running time of `./project1 4` with CPU and Real time ratios:
I ran the binary for exactly 60s (using the `timeout` command) to get the following results:
```
$ time timeout -sHUP 60s ./project1 4 > /dev/null

real    1m.009s
user    7m47.740s
sys     0m2.700s
```

* The ratio of CPU time to REAL time is: `467 / 60 ~ 7.78`
* The same technique was used over 20 runs to provide the following mean CPU time measurements:
  - Mean CPU time for 60s of execution:
*

## Architecture

This section talks about the high level structure of the network and what summarizes each node does

## Decisions
This section goes over the various decisions that were made with regards to ambiguities in the project description

* **Coin format**: `<gator_id>;<base62_suffix>`

* **Space enumeration**: The server linearly enumerates over the space in blocks of size 1024, I found this to be a good value to use for local and remote nodes so that processes do not idle as much
