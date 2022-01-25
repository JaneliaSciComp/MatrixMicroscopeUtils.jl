# Batch resave stack files to HDF5 files
# Two or three command line args are read: [-n | --mock] in_path out_path
using Pkg
Pkg.activate(dirname(@__DIR__))

using MatrixMicroscopeUtils
batch_resave_stacks_as_hdf5(; deflate=1, chunk=(128, 128, 32))