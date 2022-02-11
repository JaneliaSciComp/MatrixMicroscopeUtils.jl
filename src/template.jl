"""
    simple_hdf5_template(h5_filename, dataset_name, datatype, dataspace)

Create or append a HDF5 file with a newly allocated contiguous dataset. The byte offset to the dataset
is returned.

This function is meant to quickly create a HDF5 file and have an external program fill in the data
at a specific location (offset) at a later time.

The software filling in the data does not need to load the HDF5 library. It only needs to seek to
a specific position in the file and start writing data.
"""
function simple_hdf5_template(
    h5_filename::AbstractString,
    dataset_name::AbstractString,
    dt::HDF5.Datatype,
    ds::HDF5.Dataspace
)
    h5open(h5_filename, "cw") do h5f
        d = create_dataset(h5f, dataset_name, dt, ds; layout = :contiguous, alloc_time = :early)
        HDF5.API.h5d_get_offset(d.id)
    end
end
function simple_hdf5_template(
    h5_filename::AbstractString,
    dataset_name::AbstractString,
    dt::Type,
    ds::Dims
)
    simple_hdf5_template(h5_filename, dataset_name, datatype(dt), dataspace(ds))
end