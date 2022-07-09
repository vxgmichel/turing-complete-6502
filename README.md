6502 computer in Turing Complete
================================

This repo contains the test programs I wrote for a 6502 computer in the game [Turing Complete](https://turingcomplete.game). This design is available in the in-game schematic hub.

Use [customasm](https://github.com/hlorenzi/customasm) to assemble the programs:
```shell
± customasm hello_world.asm
customasm v0.11.15 (x86_64-unknown-linux-gnu)
assembling `hello_world.asm`...
writing `hello_world.bin`...
success after 2 iterations
```

The design of this computer is inspired by the [Eater 6502 computer](https://eater.net/6502) and the code is mostly taken from one of other projects, [eater6502-uart-edition](https://github.com/vxgmichel/eater6502-uart-edition/).