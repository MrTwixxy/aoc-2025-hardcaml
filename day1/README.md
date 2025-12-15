# Day 1: Secret Entrance

## File structure

```
.
├── lib
│   ├── datapath.ml
│   └── dune
├── test
│   ├── dune
│   └── test.ml
├── tests
│   └── input files
├── dune
├── dune-project
├── logic.cpp
├── verilog.ml
└── verilog.v
```

## Running

### Running Tests

To run tests first build the project by running

```
dune build
```

then run

```
dune test
```

Test inputs are imported and parsed in `test/test.ml`, while the actual input files are located in the `tests` directory

### Generating Verilog

To generate the Verilog code (of which a precompiled version is available in the file verilog.v) first build the project by running

```
dune build
```

then run

```
dune exec ./verilog.ml
```

## Logic

The main circuit logic is located in `lib/datapath.ml`

A C++ script with simular logic is located in `logic.cpp`

The circuit essentially copies the C++ script, but has a few modifications to be suitable for hardware. Most significant are the division and modulo operations in the C++ script. Because division is tricky in hardware and we always divide by the same amount, we can use division by constants. For example, multiplying something by `0.01` is the same as dividing by `100`.

The division function currently multiplies by `671089` and then bitshifts 26 times to the right. This causes the result to be the input times `671089/(2^26)` which is very close to `0.01`. Since the value is so close to `0.01` it is accurate until around 180 million.

The circuit currently uses 16 bit integers for the main logic, of which the most significant bit is currently used to show negative overflow. Realistically, the input of a single turn in one of the directions can be at most `(2^15)-100` which is far below 180 million. If higher numbers are required, the amount of bits can easily be increased, although make sure to use an even better constant when the maximum value becomes higher then 180 million.

Each clock cycle, 2 main signals are inputted into the circuit, `positive` and `value`. Positive is 1 when the rotation direction is right and 0 otherwise. Value is the amount of steps to actually go into that direction. Based on the input signal `part` the result is updated every clock cycle. When `part` is `0`, it returns the result for part 1 of the task and when `part` is `1`, it returns the result for part 2 of the task.

Since the result is updated every clock cycle, it is very fast and easy to observe or log the intermediate values.
