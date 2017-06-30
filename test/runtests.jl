using HDF5
using H5WriteBuffer
using Base.Test

mktemp() do p,f
    f2 = h5open(p, "w")
    wb = FileBackedBuffer(f2, "A", Float64, (3,4), 5)
    wb2 = FileBackedBuffer(f2, "B", Float64, (2,), 5)
    @test wb.bsize == 0
    @test size(wb.A) == (3,4,0)
    push!(wb, ones(3,4))
    @test wb.bsize == 1
    @test size(wb.A) == (3,4,0)
    for i=1:3 push!(wb, ones(3,4)) end
    @test wb.bsize == 4
    @test size(wb.A) == (3,4,0)
    push!(wb, ones(3,4))
    @test wb.bsize == 0
    @test size(wb.A) == (3,4,5)

    # Test interleaved writes to different dsets in the same file.
    for i=1:10 push!(wb2, 2*ones(2)) end
    @test d_open(f2, "B")[:,:] == 2*ones(2,10)

    for i=1:5 push!(wb, ones(3,4)) end
    @test wb.bsize == 0
    @test size(wb.A) == (3,4,10)

    @test d_open(f2, "A")[:,:,:] == ones(3,4,10)
end

# Test constructor taking filename.
mktempdir() do d
    cd(d) do
        fname = "somefile.h5"

        # Test new file.
        wb = FileBackedBuffer(fname, "A", Float64, (3,4), 5)
        for i=1:10 push!(wb, ones(3,4)) end
        h5open(fname) do f
            @test d_open(f, "A")[:,:,:] == ones(3,4,10)
        end
        close(wb)
        
        # Test existing file.
        wb = FileBackedBuffer(fname, "A", Float64, (3,4), 5)
        for i=1:5 push!(wb, ones(3,4)) end
        h5open(fname) do f
            @test d_open(f, "A")[:,:,:] == ones(3,4,15)
        end
        close(wb)

        # Test flush.
        wb = FileBackedBuffer(fname, "A", Float64, (3,4), 5)
        for i=1:4 push!(wb, ones(3,4)) end
        h5open(fname) do f
            @test d_open(f, "A")[:,:,:] == ones(3,4,15)
        end
        flush(wb)
        h5open(fname) do f
            @test d_open(f, "A")[:,:,:] == ones(3,4,19)
        end

        # Test dset function, returning a handle to the underlying data.
        @test read(dset(wb)) == ones(3,4,19)
        close(wb)

        # Test existing empty file.
        rm(fname)
        touch(fname)
        wb = FileBackedBuffer(fname, "A", Float64, (3,4), 5)
        for i=1:5 push!(wb, ones(3,4)) end
        h5open(fname) do f
            @test d_open(f, "A")[:,:,:] == ones(3,4,5)
        end
        close(wb)
    end
end
