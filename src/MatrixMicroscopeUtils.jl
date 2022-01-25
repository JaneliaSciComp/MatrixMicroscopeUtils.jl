module MatrixMicroscopeUtils

using HDF5
using UInt12Arrays
using Mmap
using LightXML
using Printf
using ArgParse
using Distributed

export MatrixMetadata
export resave_uint12_stack_as_uint16_hdf5
export resave_uint16_stack_as_uint16_hdf5
export resave_stack_as_uint16_hdf5
export batch_resave_stacks_as_hdf5

# HDF5 v0.16 has a HDF5.API module
# For HDF5 v0.15, just use HDF5
#const HDF5API = HDF5.API
const HDF5API = HDF5

const XYZ = (:X, :Y, :Z)

mutable struct MatrixMetadata
    version::String
    software_version::String
    data_header::String
    specimen_name::String
    tile_XYZ_um::NamedTuple{XYZ, NTuple{3,Float64}}
    sampling_XYZ_um::NamedTuple{XYZ, NTuple{3,Float64}}
    roi_XY::NamedTuple{(:left, :top, :width, :height), NTuple{4,Int}}
    channel::Int
    wavelength_nm::Float64
    laser_power::NamedTuple{(:percent, :mW), NTuple{2,Float64}}
    frame_exposure_time_ms::Float64
    detection_filter::String
    dimensions_XYZ::NamedTuple{XYZ, NTuple{3,Int}}
    stack_direction::String
    planes::UnitRange{Int}
    timepoints::Integer
    bit_depth::Integer
    defect_correction::String
    experiment_notes::String
    cam::Int
    metadata_file::String
    xml::String
    MatrixMetadata() = new()
end

function Base.show(io::IO, ::MIME"text/plain", md::MatrixMetadata)
    println(io, "MatrixMetadata with the following field values.")
    names = fieldnames(MatrixMetadata)
    #max_field_length = maximum([length(string(n)) for n in names])
    #padding = max_field_length + 4
    for f in names
        # skip xml field
        if f == :xml
            continue
        end
        v = getfield(md, f)
        fn = string(f)
        @printf(io, "%26s: %s\n", fn, v)
    end
end

function Base.:(==)(a::MatrixMetadata, b::MatrixMetadata)
    for f in fieldnames(MatrixMetadata)
        if f == :xml
            continue
        end
        @debug f
        if getfield(a, f) != getfield(b, f)
            return false
        end
    end
    return true
end


raw"""
    resave_uint12_stack_as_uint16_hdf5(filename, [array_size]; h5_filename, split_timepoints, metadata, ...)

Resave a raw UInt12 stack as a UInt16 HDF5 for maximum compatability.
* `filename` is a path to a file to convert. Using the absolute path is recommended. The file extension must be ".stack".
If the filename is of the format, "TM0000000CM1.stack" then timepoint and camera information will be parsed from the name.
Timepoint information will be used to create the dataset name.
Camera number information will be used to locate a metadata file such as "cam1.xml".
* `array_size` are the dimensions of the array as a tuple. Typically (X, Y, Z). If the `array_size` is not provided,
then it will be determined by finding the `dimensions_XYZ`` property in the metadata XML file.

# Keywords
* `h5_filename` is the name of the HDF5 file to create. "_uint16" is appended to the name and the extension is changed to h5 from stack
* `split_timepoints` determines whether to split timepoints into separate datasets in the HDF5 file. The default is `true` to split the timepoints.
   If `false`, a single 4D dataset will be saved with dimensions XYZT.
* `metadata` an optional `MatrixMetadata`

# Additional Keywords
Additional keywords are passed on to `HDF5.create_dataset`. Some examples of HDF5 keywords include
* `chunk` is a tuple of integers describing the chunk size. This needs to be specified to use HDF5 filters.
* `deflate` is an integer that determines the level of the standard HDF5 compression.
* `shuffle` is usually just an empty tuple `()` which indicates to do shuffle filtering.
See also the `HDF5` package for additional filters.

# Examples
```
julia> resave_uint12_stack_as_uint16_hdf5("TM0000000_CM5.stack")
┌ Info: Inferred the number of time points from the file size being a multiple of the number of expected bytes
│   array_size = (2304, 816, 17, 44)
└   expected_bytes = 47941632

julia> resave_uint12_stack_as_uint16_hdf5("TM0000044_CM5.stack", chunk = (288, 102, 17), shuffle=(), deflate=1)
┌ Info: Inferred the number of time points from the file size being a multiple of the number of expected bytes
│   array_size = (2304, 816, 17, 44)
└   expected_bytes = 47941632

julia> filename = raw"C:\Users\kittisopikulm\Documents\Keller_Lab\AgaroseBeads_561nm15pct_17Planes5umStep_20211011_113516\TM0000000_CM5.stack"
"C:\\Users\\kittisopikulm\\Documents\\Keller_Lab\\AgaroseBeads_561nm15pct_17Planes5umStep_20211011_113516\\TM0000000_CM5.stack"

julia> resave_uint12_stack_as_uint16_hdf5(filename, chunk = (288, 102, 17), shuffle=(), deflate=1)
┌ Info: Inferred the number of time points from the file size being a multiple of the number of expected bytes
│   array_size = (2304, 816, 17, 44)
└   expected_bytes = 47941632

julia> filename = raw"\\Keller-S10\Data\Matrix\RC_21-10-11\AgaroseBeads_561nm15pct_17Planes5umStep_20211011_113516\TM0000088_CM5.stack"
"\\\\Keller-S10\\Data\\Matrix\\RC_21-10-11\\AgaroseBeads_561nm15pct_17Planes5umStep_20211011_113516\\TM0000088_CM5.stack"

julia> resave_uint12_stack_as_uint16_hdf5(filename, chunk = (288, 102, 17), shuffle=(), deflate=1)
┌ Info: Inferred the number of time points from the file size being a multiple of the number of expected bytes
│   array_size = (2304, 816, 17, 44)
└   expected_bytes = 47941632
```
"""
function resave_uint12_stack_as_uint16_hdf5(filename::AbstractString,
                                            array_size;
                                            h5_filename = rename_file_as_h5(filename; suffix="uint16"),
                                            split_timepoints::Bool = true,
                                            timepoint_range = 0:typemax(Int)-1,
                                            metadata::Union{MatrixMetadata, Nothing} = nothing,
                                            kwargs...)
    A = Mmap.mmap(filename, Vector{UInt8})
    # 12-bit depth, 8 bits per byte
    expected_bytes = prod(array_size)* 12 ÷ 8
    if length(A) != expected_bytes
        if mod(length(A), expected_bytes) == 0
            # Calculate the number of timepoints 
            array_size = (array_size..., length(A) ÷ expected_bytes)
            @info "Inferred the number of time points from the file size being a multiple of the number of expected bytes" array_size expected_bytes
        end
    end
    A12 = UInt12Array{UInt16, typeof(A), length(array_size)}(A, array_size)
    A16 = convert(Array{UInt16}, A12)
    if metadata === nothing
        metadata = try_metadata(filename)
    end
    dataset_name, _ = Base.Filesystem.splitext(basename(filename))
    save_uint16_array_as_hdf5(A16, dataset_name; h5_filename, split_timepoints, timepoint_range, metadata, kwargs...)
end

# Locate the metadata file to determine the file size
function resave_uint12_stack_as_uint16_hdf5(filename::AbstractString; kwargs...)
    try
        md = metadata(filename)
        @assert md.bit_depth == 12 "Bit depth is not 12 according to metadata XML file"
        resave_uint12_stack_as_uint16_hdf5(filename, Tuple(md.dimensions_XYZ); metadata = md, kwargs...)
    catch err
        throw(ErrorException("Cannot determine array size in $filename"))
    end
end

function resave_uint16_stack_as_uint16_hdf5(filename::AbstractString,
                                            array_size;
                                            h5_filename = rename_file_as_h5(filename),
                                            split_timepoints::Bool = true,
                                            timepoint_range = 0:typemax(Int)-1,
                                            metadata::Union{MatrixMetadata, Nothing} = nothing,
                                            kwargs...)
    A16 = Mmap.mmap(filename, Vector{UInt16})
    # 16-bit depth, 8 bits per byte
    expected_bytes = prod(array_size)* 16 ÷ 8
    if sizeof(A16) != expected_bytes
        if mod(sizeof(A16), expected_bytes) == 0
            # Calculate the number of timepoints 
            array_size = (array_size..., sizeof(A16) ÷ expected_bytes)
            @info "Inferred the number of time points from the file size being a multiple of the number of expected bytes" array_size expected_bytes
        end
    end
    A16 = reshape(A16, array_size)
    if metadata === nothing
        metadata = try_metadata(filename)
    end
    dataset_name, _ = Base.Filesystem.splitext(basename(filename))
    save_uint16_array_as_hdf5(A16, dataset_name; h5_filename, split_timepoints, timepoint_range, metadata, kwargs...)
end

# Locate the metadata file to determine the file size
function resave_uint16_stack_as_uint16_hdf5(filename; kwargs...)
    try
        md = metadata(filename)
        @assert md.bit_depth == 16 "Bit depth is not 16 according to metadata XML file"
        resave_uint16_stack_as_uint16_hdf5(filename, Tuple(md.dimensions_XYZ); metadata = md, kwargs...)
    catch err
        throw(ErrorException("Cannot determine array size in $filename"))
    end
end

function resave_stack_as_uint16_hdf5(filename; kwargs...)
    md = nothing
    try
        md = metadata(filename)
    catch err
        throw(ErrorException("Cannot read metadata for $filename to determine bit_depth or array_size"))
    end
    if !isa(md, MatrixMetadata)
        return nothing
    end
    if md.bit_depth == 16
        resave_uint16_stack_as_uint16_hdf5(filename, Tuple(md.dimensions_XYZ); metadata = md, kwargs...)
    elseif md.bit_depth == 12
        resave_uint12_stack_as_uint16_hdf5(filename, Tuple(md.dimensions_XYZ); metadata = md, kwargs...)
    else
        error("Do not know how to resave bit depth of $(md.bit_depth) to an UInt16 HDF5 file")
    end
end

# Consider these arguments to be UNSTABLE
# Can we simplify this by removing the filename argument?
# 1. We need the dataset_name
# 2. We need the raw XML
function save_uint16_array_as_hdf5(A16::AbstractArray{UInt16},
                                   dataset_name;
                                   h5_filename = rename_file_as_h5(dataset_name*".stack"),
                                   split_timepoints::Bool = true,
                                   timepoint_range = 0:typemax(Int)-1,
                                   metadata::Union{MatrixMetadata, Nothing} = nothing,
                                   kwargs...)
    @info "Saving file as $h5_filename"
    f = h5open(h5_filename, "w")

    # Check if the file name format is "TM[ttttttt]_CM[c]"
    # where ttttttt is the time point and c is the camera number
    m = match(r"TM(\d+)_CM(\d+)", dataset_name)
    parent = f
    t = 0
    if m !== nothing
        # Create a dataset named after the timepoint
        dataset_name = "TM" * first(m.captures)
        t = parse(Int, first(m.captures))
        # Create a group named after the camera
        parent = create_group(f, "CM" * last(m.captures))
    end
    timepoint_range = max(t, first(timepoint_range)):min(t+size(A16,4)-1, last(timepoint_range))

    try
        if split_timepoints
            # Each timepoint will be in a separate dataset
            last_t = last(timepoint_range)
            for slice in eachslice(A16, dims = 4)
                dataset_name = @sprintf "TM%07d" t
                d, dtype = create_dataset(parent, dataset_name, slice; kwargs...)
                write_dataset(d, dtype, slice)
                if metadata !== nothing
                    # HDF5 Vibez Plugin for FIJI
                    s = metadata.sampling_XYZ_um
                    write_attribute(d, "element_size_um", [s.Z, s.Y, s.X])
                end
                t = t + 1
                if t > last_t
                    break;
                end
            end
        else
            # There will be one dataset with the name matching the filename
            data = A16
            if size(data, 4) != length(timepoint_range)
                data = data[:, :, :, begin : begin+length(timepoint_range-1)]
            end
            d, dtype = create_dataset(parent, dataset_name, A16; kwargs...)
            if metadata !== nothing
                # HDF5 Vibez Plugin for FIJI
                write_attribute(d, "element_size_um", reverse([Tuple(metadata.sampling_XYZ_um)...]))
            end
            write_dataset(d, dtype, A16)
        end
    finally
        close(f)
    end
end


# Create a UInt24 external link to an existing stack file
# This will work with h5py but not with the FIJI HDF5 readers, yet
# This also requires HDF5.jl v0.16 to work properly
#=
function link_uint12_stack_to_uint24_hdf5(filename::AbstractString,
                                          array_size;
                                          h5_filename = rename_file_as_h5(filename; suffix="ext_uint24"),
                                          split_timepoints::Bool = true,
                                          metadata::Union{MatrixMetadata, Nothing} = nothing,
                                          kwargs...)
    expected_bytes = prod(array_size)* 12 ÷ 8
    fsz = filesize(filename)
    if fsz != expected_bytes
        if mod(fsz, expected_bytes) == 0
            # Calculate the number of timepoints 
            array_size = (array_size..., fsz ÷ expected_bytes)
            @info "Inferred the number of time points from the file size being a multiple of the number of expected bytes" array_size expected_bytes
        end
    end

    dataset_name, _ = Base.Filesystem.splitext(basename(filename))

    f = h5open(h5_filename, "w")
    # Check if the file name format is "TM[ttttttt]_CM[c]"
    # where ttttttt is the time point and c is the camera number
    m = match(r"TM(\d+)_CM(\d+)", dataset_name)
    parent = f
    t = 0
    if m !== nothing
        dataset_name = "TM" * first(m.captures)
        t = parse(Int, first(m.captures))
        parent = create_group(f, "CM" * last(m.captures))
    end

    dt = HDF5API.h5t_copy(HDF5API.H5T_STD_U32LE)
    HDF5API.h5t_set_size(dt, 3) # set size to three bytes
    try
        try
            md_fn = metadata_filename(filename)
            md_str = read(md_fn, String)
            write_attribute(parent, "xml_metadata", md_str)
            metadata_dict = parse_info_xml_to_dict(LightXML.parse_string(md_str))
            for (key,value) in metadata_dict
                write_attribute(parent, key, value)
            end
            if metadata === nothing
                metadata = parse_info_xml(metadata_dict, extract_cam_number(md_fn))
            end
        catch err
            rethrow(err)
            @warn "Could not load metadata XML file for $filename" err
        end
        base_filename = abspath(filename)
        uint24_sz = (array_size[1]÷2, array_size[2:4]...,)
        if split_timepoints
            for ti in 0:array_size[4]-1
                dataset_name = @sprintf "TM%07d" t
                offset = ti*expected_bytes
                d = create_dataset(parent, dataset_name, HDF5.Datatype(dt), dataspace(uint24_sz[1:3]); external=(base_filename, offset, prod(uint24_sz[1:3])*3))

                t = t + 1
                if metadata !== nothing
                    # HDF5 Vibez Plugin for FIJI
                    write_attribute(d, "element_size_um", reverse([Tuple(metadata.sampling_XYZ_um)...]))
                end
            end
        else
            d = create_dataset(parent, dataset_name, HDF5.Datatype(dt), dataspace(uint24_sz); external=(base_filename, 0, prod(uint24_sz)*3))
        end
    finally
        close(f)
    end
end
=#

function batch_resave_stacks_as_hdf5(in_path, out_path; mock = false, kwargs...)
    @assert isdir(in_path) "$in_path is not an existing directory"
    in_stacks = [file for file in readdir(in_path) if endswith(file, ".stack")]
    mkpath(out_path)
    @debug kwargs
    @sync @distributed for stack in in_stacks
        try
            stack_full_path = joinpath(in_path, stack)
            md = metadata(stack_full_path)
            if md.bit_depth == 12
                h5_filename = replace(stack, ".stack" => "_uint16.h5")
                h5_filename = joinpath(out_path, h5_filename)
                println("Resaving $stack_full_path to $h5_filename")
                if !mock
                    resave_uint12_stack_as_uint16_hdf5(stack_full_path, Tuple(md.dimensions_XYZ);
                        h5_filename, metadata=md, kwargs...)
                end
            elseif md.bit_depth == 16
                h5_filename = replace(stack, ".stack" => ".h5")
                h5_filename = joinpath(out_path, h5_filename)
                println("Resaving $stack_full_path to $h5_filename")
                if !mock
                    resave_uint16_stack_as_uint16_hdf5(stack_full_path, Tuple(md.dimensions_XYZ);
                        h5_filename, metadata=md, kwargs...)
                end
            else
                error("Do not know how to resave bit depth of $(md.bit_depth) to an UInt16 HDF5 file")
            end
        catch err
            @warn "Could not resave $stack in $in_path. Continuing..." err
        end
    end
end

function batch_resave_stacks_as_hdf5(; kwargs...)
    s = ArgParseSettings(
        prog="scripts/batch_resave.jl",
        description="Resave a raw .stack file as a HDF5 file"
    )

    @add_arg_table! s begin
        "--mock", "-n"
            help = "Flag for a mock run. Do nothing."
            action = :store_true
        "--deflate"
            help = "Deflate compression level"
            arg_type = Int
            default = 0
        "--shuffle"
            help = "Do byte shuffle"
            action = :store_true
        "--chunk"
            help = "Chunk size"
            arg_type = Tuple{Int, Int, Int}
            default = (128, 128, 32)
        "in_path"
            help = "Directory with .stack files"
            required = true
        "out_path"
            help = "Directory to store .h5 files"
            required = true
    end

    a = parse_args(ARGS, s)
    mock = a["mock"]
    shuffle = a["shuffle"] ? (shuffle = (),) : ()
    deflate = a["deflate"] == 0 ? () : (deflate = a["deflate"],)
    chunk = a["chunk"] == (0,0,0) ? () : (chunk = a["chunk"],)

    @debug a

    batch_resave_stacks_as_hdf5(a["in_path"], a["out_path"]; mock, chunk..., shuffle..., deflate..., kwargs...)
end

function ArgParse.parse_item(::Type{Tuple{Int, Int, Int}}, x::AbstractString)
    strs = split(x, ","; keepempty = false)
    if isempty(strs)
        return (0,0,0)
    else
        @assert length(strs) == 3 "chunk must consist of three comma-separated integers"
        return (parse.(Int, strs)...,)
    end
end

precompile(batch_resave_stacks_as_hdf5, ())
precompile(batch_resave_stacks_as_hdf5, (String, String))

function rename_file_as_h5(filename, hdf5_ext="h5"; suffix="")
    @assert endswith(filename, ".stack") "Input file name must be a .stack file"
    filename = abspath(filename)
    if isempty(suffix)
    else
        suffix = "_" * suffix
    end
    replace(filename, ".stack" => suffix*"."*hdf5_ext)
end

"""
    metadata_filename(filename::String)

Determine the filename of the metadata based on the filename.
This works by looking for CM[x].stack at the end of the file
and then looks for cam[x].xml.
"""
function metadata_filename(filename::AbstractString)
    m = match(r".*CM(\d+).stack$", filename)
    if m === nothing || length(m.captures) != 1
        error("Cannot parse a camera number from $filename.")
    end
    cam = parse(Int, first(m.captures))
    dir = dirname(filename)
    xmlfile = joinpath(dir, "cam$cam.xml")
    if !isfile(xmlfile)
        error("Cannot find $xmlfile.")
    end
    xmlfile
end

function metadata(filename::AbstractString)
    md_fn = metadata_filename(filename)
    metadata = parse_info_xml(md_fn)
end

function try_metadata(filename::AbstractString)
    md = nothing
    try
        md = metadata(filename)
    catch err
        @warn "Could not load metadata XML file for $filename" err
    end
    md
end

function num_timepoints(filename::AbstractString)
    # get file size in bytes
    fsz = filesize(filename)
    # parse the metadata
    md = metadata(filename)
    num_timepoints(fsz, md)
end

function num_timepoints(filesize::Integer, metadata::MatrixMetadata)
    # get the number of bytes per stack from dimensions_XYZ
    nbytes_per_stack = bytes_per_stack(metadata)
    # check that the number of bytes in the file is a multiple of the number of bytes per XYZ stack
    @assert mod(filesize, nbytes_per_stack) == 0 "The file size is not a multiple of the number of bytes per stack" filesize nbytes_per_stack
    # the number of timepoints is the file size divided by 
    filesize ÷ nbytes_per_stack
end

function bytes_per_stack(info::MatrixMetadata)
    prod(info.dimensions_XYZ) * info.bit_depth ÷ 8
end

function parse_info_xml_to_dict(xmlfilename::AbstractString)
    xmlstr = read(xmlfilename, String)
    xml = parse_string(xmlstr)
    dict = parse_info_xml_to_dict(xml)
    dict["metadata_file"] = xmlfilename
    dict["xml"] = xmlstr
    dict["cam"] = string(extract_cam_number(xmlfilename))
    dict
end

function parse_info_xml_to_dict(xml::XMLDocument)
    r = root(xml)
    dict = attributes_dict(r)
    for e in child_elements(r)
        @assert name(e) == "info" "An XML element not named \"info\" was detected."
        attrs = attributes_dict(e)
        merge!(dict, attrs)
    end
    dict
end

function parse_info_xml(xml, cam = extract_cam_number(xml))
    dict = parse_info_xml_to_dict(xml)
    parse_info_xml(dict, cam)
end

function parse_info_xml(dict::Dict{AbstractString, AbstractString}, cam = extract_cam_number(dict))
    s = MatrixMetadata()
    if haskey(dict, "cam")
        dcam = parse(Int, dict["cam"])
        @assert dcam == cam || cam === nothing "Camera number does not match `cam` argument."
        if cam  === nothing
            s.cam = dcam
        else
            s.cam = cam
        end
    end
    s.version = dict["version"]
    s.software_version = dict["software_version"]
    s.data_header = dict["data_header"]
    s.specimen_name = dict["specimen_name"]
    m = match(r"X?=?(.*)_Y?=?(.*)_Z?=?(.*)", dict["tile_XYZ_um"])
    s.tile_XYZ_um = NamedTuple{(:X, :Y, :Z)}( (parse.(Float64, m.captures)...,) )
    m = match(r"(.*)_(.*)_(.*)", dict["sampling_XYZ_um"])
    if m === nothing
        m = match(r"(.*), (.*), (.*)", dict["sampling_XYZ_um"])
    end
    s.sampling_XYZ_um = NamedTuple{(:X, :Y, :Z)}( (parse.(Float64, m.captures)...,) )
    if haskey(dict, "roi_XY")
        m = match(r"(.*)_(.*)_(.*)_(.*)", dict["roi_XY"])
    else
        m = match(r"(.*)_(.*)_(.*)_(.*)", dict["roi_XY_cam$cam"])
    end
    s.roi_XY = NamedTuple{(:left, :top, :width, :height)}( (parse.(Int, m.captures)...,) )
    s.channel = parse.(Int, get(dict, "channel", "0"))
    s.wavelength_nm = parse.(Float64, dict["wavelength_nm"])
    m = match(r"(.*)%_(.*)mW", dict["laser_power"])
    s.laser_power = NamedTuple{(:percent, :mW)}( (parse.(Float64, m.captures)...,) )
    if haskey(dict, "frame_exposure_time_ms")
        s.frame_exposure_time_ms = parse(Float64, dict["frame_exposure_time_ms"])
    else
        s.frame_exposure_time_ms = parse(Float64, dict["exposure_time_ms"])
    end
    s.detection_filter = dict["detection_filter"]
    if haskey(dict, "dimensions_XYZ")
        m = match(r"(.*)_(.*)_(.*)", dict["dimensions_XYZ"])
    else
        m = match(r"(.*)x(.*)x(.*)", dict["dimensions_XYZ_cam$cam"])
    end
    s.dimensions_XYZ = NamedTuple{(:X, :Y, :Z)}( (parse.(Int, m.captures)...,) )
    s.stack_direction = dict["stack_direction"]
    m = match(r"(\d+)-?_?(\d+)", dict["planes"])
    plane_endpoints = parse.(Int, m.captures)
    s.planes = first(plane_endpoints):last(plane_endpoints)
    s.timepoints = parse(Int, dict["timepoints"])
    s.bit_depth = parse(Int, dict["bit_depth"])
    s.defect_correction = dict["defect_correction"]
    s.experiment_notes = dict["experiment_notes"]
    s.metadata_file = get(dict, "metadata_file", "")
    # Capture the original XML file
    s.xml = get(dict, "xml", xml_string(s))
    s
end

function extract_cam_number(xmlfilename::AbstractString)
    m = match(r"cam(\d+).xml", basename(xmlfilename))
    @assert length(m.captures) == 1
    parse(Int, m.captures[1])
end

function extract_cam_number(xml::XMLDocument)
    nothing
end

function generate_xml(metadata::MatrixMetadata)
    xdoc = XMLDocument()
    xroot = create_root(xdoc, "push_config")
    set_attribute(xroot, "version", metadata.version)
    info_node(xroot, "software_version", metadata.software_version)
    info_node(xroot, "data_header", metadata.data_header)
    info_node(xroot, "specimen_name", metadata.specimen_name)
    info_node(xroot, "tile_XYZ_um", @sprintf("%f_%f_%f", metadata.tile_XYZ_um...))
    info_node(xroot, "sampling_XYZ_um", @sprintf("%f_%f_%f", metadata.sampling_XYZ_um...))
    info_node(xroot, "roi_XY", @sprintf("%d_%d_%d_%d", metadata.roi_XY...))
    info_node(xroot, "channel", metadata.channel)
    info_node(xroot, "wavelength_nm", metadata.wavelength_nm)
    info_node(xroot, "laser_power", @sprintf("%1.2f%%_%1.2fmW", metadata.laser_power...))
    info_node(xroot, "frame_exposure_time_ms", @sprintf("%2.2f", metadata.frame_exposure_time_ms))
    info_node(xroot, "detection_filter", metadata.detection_filter)
    info_node(xroot, "dimensions_XYZ", @sprintf("%d_%d_%d", metadata.dimensions_XYZ...))
    info_node(xroot, "stack_direction", metadata.stack_direction)
    info_node(xroot, "planes", @sprintf("%d_%d", first(metadata.planes), last(metadata.planes)))
    info_node(xroot, "timepoints", metadata.timepoints)
    info_node(xroot, "bit_depth", metadata.bit_depth)
    info_node(xroot, "defect_correction", metadata.defect_correction)
    info_node(xroot, "experiment_notes", metadata.experiment_notes)
    info_node(xroot, "cam", metadata.cam)
    xdoc
end

function info_node(xroot, name, value)
    info_node = new_child(xroot, "info")
    set_attribute(info_node, name, value)
end

function save_xml(metadata::MatrixMetadata, file)
    save_file(generate_xml(metadata), file)
end

function xml_string(metadata::MatrixMetadata)
    string(generate_xml(metadata))
end

end # module MatrixMicroscopeUtils