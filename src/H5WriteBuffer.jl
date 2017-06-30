module H5WriteBuffer
using HDF5
import Base.push!,
       Base.close,
       HDF5.flush

export FileBackedBuffer,
       push!,
       dset,
       flush,
       close

### This type is designed to streamline appending, in the
### single most-major dimension, to an array backed by an
### HDF5 file. It is not designed to work for appending to
### an array of dimension 1, because that's not useful for
### its original purpose, but it wouldn't be difficult to
### extend that.
type FileBackedBuffer{T,N}
    handle               # Keep HDF5 file handle.
    take_ownership       # Take ownership of file handle.
    A                    # Reference to array inside.
    selectall            # A tuple of colons to select inner dims.
    bsize::Int           # Present size of in-memory buffer.
    bcapacity::Int       # Present capacity of in-memory buffer.
    b::Array{T,N}        # Buffer.
end
function FileBackedBuffer(hdf5_handle, dset_name::String,
                          T::Type, inner_size::Tuple, buffer_size::Int;
                          take_ownership=false)
    if exists(hdf5_handle, dset_name)
        A = d_open(hdf5_handle, dset_name)
    else
        initial_size = (inner_size..., buffer_size)
        max_size = (inner_size..., -1)
        A = d_create(hdf5_handle, dset_name, T,
                     (initial_size, max_size),
                     "chunk", (inner_size...,buffer_size))
        set_dims!(A, (inner_size...,0))
    end
    FileBackedBuffer(hdf5_handle, take_ownership, A,
                     (Colon() for i=1:length(size(A))-1),
                     0, buffer_size,
                     Array(T, (inner_size...,buffer_size)))
end
function FileBackedBuffer(fname::String, dset_name::String,
                          T::Type, inner_size::Tuple, buffer_size::Int)
    handle = h5open(fname, isfile(fname) && (filesize(fname)>0) ? "r+" : "w")
    FileBackedBuffer(handle, dset_name::String,
                     T::Type, inner_size::Tuple, buffer_size::Int;
                     take_ownership=true)
end
function close{T}(this::FileBackedBuffer{T})
    if this.take_ownership
        close(this.handle)
    end
end
function push!{T}(this::FileBackedBuffer{T}, x)
    this.bsize += 1
    this.b[this.selectall...,this.bsize] = x

    if this.bsize == this.bcapacity
        flush(this)
    end
end

# Return a reference to the dataset backing this buffer.
function dset{T}(this::FileBackedBuffer{T})
    flush(this)
    return this.A
end

# Write in-memory buffer to file and clear it.
function flush{T}(this::FileBackedBuffer{T})
    set_dims!(this.A, (size(this.A)[1:end-1]..., size(this.A)[end]+this.bsize))
    this.A[this.selectall...,end-this.bsize+1:end] = this.b[this.selectall...,1:this.bsize]
    flush(this.handle)
    _clear!(this)
end

# Clear in-memory buffer.
function _clear!{T}(this::FileBackedBuffer{T})
    this.bsize = 0
end

end # module
