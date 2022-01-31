#=
The functions here take advantage of HDF5's ability to use external links.
There are two separate features that allow for this.
    1. External datasets: These allow dataset data to be stored in an
    external file. Currently, this must be continguous and therefore
    unfiltered data.
    2. Dataset links between HDF5 files: These allow datasets to
    actually be datasets in other HDF5 files and act as external
    links.
Together these features allow us to create meta-HDF5 files which themselves
may not contain any actual data, but allow us to describe or collect
the data in external datafiles.
=#

"""
    link_external_raw_16bit_data(filename; kwargs...)

Create a HDF5 file with links that point into a raw stack on a per timepoint basis.
`filename` is the name of the raw stack file.
"""
function link_external_raw_16bit_data(
    filename::AbstractString;
    h5_filename = rename_file_as_h5(filename; suffix =  "link"),
    rethrow_errors::Bool = false,
    force::Bool = false,
    timepoint_range::AbstractRange = 0:typemax(Int)-1,
    metadata::MatrixMetadata = try_metadata(filename; rethrow_errors)
    )
    @assert metadata.bit_depth == 16 "Bit depth must be 16 for $filename to link"
    _bytes_per_stack = bytes_per_stack(metadata)
    ntp = num_timepoints(filesize(filename), metadata)
    check_file_existence(h5_filename; force)
    @info "Creating link HDF5 file: $h5_filename "
    f = h5open(h5_filename, "w")
    filename = basename(filename)
    try
        # Check if the file name format is "TM[ttttttt]_CM[c]"
        m = match(r"TM(\d+)_CM(\d+)", filename)
        parent = f
        t = 0
        if m !== nothing
            # Create a dataset named after the timepoint
            dataset_name = "TM" * first(m.captures)
            t = parse(Int, first(m.captures))
            # Create a group named after the camera
            parent = create_group(f, "CM" * last(m.captures))
        end
        data_range = t : t + ntp - 1
        timepoint_range = intersect(timepoint_range, data_range)

        # Capture metadata and copy it into the HDF5 file
        write_cam_metadata_to_hdf5(parent, metadata)
        e = get_element_size_um_ZYX(metadata)
        for (ti, t) in zip(0:ntp-1, timepoint_range)
            dataset_name = @sprintf("TM%07d", ti)
            d = HDF5.create_external_dataset(parent, dataset_name, filename, UInt16, Tuple(metadata.dimensions_XYZ), _bytes_per_stack*ti)
            write_attribute(d, "element_size_um", e)
        end
    catch err
        rethrow(err)
    finally
        close(f)
    end
end