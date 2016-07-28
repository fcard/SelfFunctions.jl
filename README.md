# SelfFunctions

## Instalation

```julia
  Pkg.clone("https://github.com/fcard/SelfFunctions.jl")
```

## Introduction

This package allows the creation of functions that have easier interaction with a given type, by
having an instance of it as an implicit argument and having access to its fields directly.

## Usage

### Use preexisting type

```julia
  using SelfFunctions

  type MyType
    x::Int
  end
  @selftype self MyType
```

### Define and then use type

```julia
  using SelfFunctions

  @selftype self type MyType
    x::Int
  end
```

### Usage of the generated macro

```julia
  @self function inc()
    x += 1
  end

  @self function inc2()
    inc()
    inc()
  end

  const mt = MyType(0)

  inc(mt)  # mt.x: 0 -> 1
  inc2(mt) # mt.x: 1 -> 3
```

## TODO

* Support `global` and `local` function declarations.
* Support anonymous functions.
* Add utilities.
* Add documentation to `@selftype` and it macros generated by it.

