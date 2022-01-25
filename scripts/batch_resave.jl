# Batch resave stack files to HDF5 files
# Two or three command line args are read: [-n | --mock] in_path out_path
using Distributed

@everywhere begin
    using Pkg
    Pkg.activate(dirname(@__DIR__))
    using MatrixMicroscopeUtils
end

batch_resave_stacks_as_hdf5()