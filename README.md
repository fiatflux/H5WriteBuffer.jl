[![Build Status](https://travis-ci.org/fiatflux/H5WriteBuffer.jl.svg?branch=master)](https://travis-ci.org/fiatflux/H5WriteBuffer.jl)

# H5WriteBuffer
Simplifies the interface of buffered appends to
an HDF5-backed array.

## Example
```julia
scratch = Array(Float64, 3,4)
buffer = FileBackedBuffer(fname, "A", Float64, (3,4), 100)
for i=1:1000
    compute_something!(scratch)
    push!(buffer, scratch)
end
close(buffer)
```
