module BinaryTemplates

using HDF5
using Printf
using CRC32c

import ..MatrixMicroscopeUtils
import ..MatrixMicroscopeUtils: MatrixMetadata

export offsets, chunks, expected_file_size
export simple_hdf5_template, create_template, apply_template
export get_template, get_uint24_template
export translate

abstract type AbstractBinaryTemplate end

struct HeaderOnlyBinaryTemplate <: AbstractBinaryTemplate
    expected_file_size::Int
    header::Vector{UInt8}
end
offsets(::HeaderOnlyBinaryTemplate) = [0]
chunks(t::HeaderOnlyBinaryTemplate) = [t.header]
expected_file_size(t::HeaderOnlyBinaryTemplate) = t.expected_file_size

struct BinaryTemplate <: AbstractBinaryTemplate
    expected_file_size::Int
    offsets::Vector{Int}
    chunks::Vector{Vector{UInt8}}
end
offsets(t::BinaryTemplate) = t.offsets
chunks(t::BinaryTemplate) = t.chunks
expected_file_size(t::BinaryTemplate) = t.expected_file_size

struct ZeroTemplate <: AbstractBinaryTemplate
    header_size::Int
    num_timepoints::Int
    bytes_per_timepoint::Int
end
ZeroTemplate(;
    header_size = 2048,
    num_timepoints = 44,
    bytes_per_timepoint = prod((3456, 816, 17))
) = ZeroTemplate(header_size, num_timepoints, bytes_per_timepoint)
ZeroTemplate(m::MatrixMetadata) = ZeroTemplate(m.header_size, m.timepoints_per_stack, prod(Tuple(m.dimensions_XYZ)) * m.bit_depth ÷ 8)
offsets(t::ZeroTemplate) = (0:t.num_timepoints) .* (t.header_size + t.bytes_per_timepoint) |> collect
chunks(t::ZeroTemplate) = [zeros(UInt8, t.header_size) for tp in 1:t.num_timepoints]
expected_file_size(t::ZeroTemplate) = (t.header_size + t.bytes_per_timepoint)*t.num_timepoints

function Base.convert(::Type{BinaryTemplate}, t::AbstractBinaryTemplate)
    return BinaryTemplate(
        expected_file_size(t),
        offsets(t),
        chunks(t)
    )
end

function Base.convert(::Type{HeaderOnlyBinaryTemplate}, t::AbstractBinaryTemplate)
    @assert offsets(t) == [0] "Template does not have only one chunk at offset 0. Cannot convert to HeaderOnlyBinaryTemplate"
    return HeaderOnlyBinaryTemplate(
        expected_file_size(t),
        first(chunks(t))
    )
end

function Base.:(==)(x::AbstractBinaryTemplate, y::AbstractBinaryTemplate)
    expected_file_size(x) == expected_file_size(y) &&
    chunks(x) == chunks(y) &&
    offsets(x) == offsets(y)
end

function Base.show(io::IO, ::MIME"text/plain", t::AbstractBinaryTemplate)
    println(io, typeof(t), ":")
    println(io, "    expected_file_size: $(Base.format_bytes(expected_file_size(t)))")
    println(io)
    println(io, "    Offsets            Length     Chunk Checksum")
    println(io, "    ------------------ ---------- --------------")
    for (offset, chunk) in zip(offsets(t), chunks(t))
        @printf(io, "    0x%016x % 10d     0x%08x\n", offset, length(chunk), crc32c(chunk))
    end
end

function isexpectedfilesize(filename, t::AbstractBinaryTemplate)
    return filesize(filename) == expected_file_size(t)
end

function backuptemplate(filename::AbstractString, t::AbstractBinaryTemplate)
    offsets, chunks =  open(filename, "r") do io
        backuptemplate(io, t)
    end
    return BinaryTemplate(filesize(filename), offsets, chunks)
end
function backuptemplate(io::IO, t::AbstractBinaryTemplate)
    _offsets = offsets(t)
    lengths = length.(chunks(t))
    _chunks = map(_offsets, lengths) do offset, length
        seek(io, offset)
        read(io, length)
    end
    # If there are extra bytes at the end, backup those up
    if position(io) < filesize(io)
        push!(_offsets, position(io))
        push!(_chunks, read(io, filesize(io) - position(io)))
    end
    return _offsets, _chunks
end

function save(t::AbstractBinaryTemplate, filename::AbstractString, mode = "w")
    mkpath(dirname(filename))
    buffer = IOBuffer()
    let io = buffer
        write(io, expected_file_size(t))
        write(io, length(offsets(t)))
        write(io, offsets(t))
        write(io, length.(chunks(t)))
        for chunk in chunks(t)
            write(io, chunk)
        end
    end
    open(filename, mode) do io
        write(io, take!(buffer))
    end
end

function load(type::Type{BinaryTemplate}, filename::AbstractString, index::Int = 1)
    template = nothing
    open(filename, "r") do io
        for i in 1:index
            template = load(type, io)
        end
    end
    return template
end

function load(::Type{BinaryTemplate}, io::IO)
    expected_file_size = read(io, Int)
    num = read(io, Int)
    offsets = Vector{Int}(undef, num)
    read!(io, offsets)
    lengths = Vector{Int}(undef, num)
    read!(io, lengths)
    chunks = map(lengths) do length
        read(io, length)
    end
    return BinaryTemplate(expected_file_size, offsets, chunks)
end

load_binary_template(filename::AbstractString, index::Int = 1) = load(BinaryTemplate, filename, index)

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
    header_size = h5open(h5_filename, "cw") do h5f
        d = create_dataset(h5f, dataset_name, dt, ds; layout = :contiguous, alloc_time = :early)
        HDF5.API.h5d_get_offset(d.id)
    end
    header = open(h5_filename, "r") do f
        read(f, header_size)
    end
    expected_file_size = filesize(h5_filename)
    return HeaderOnlyBinaryTemplate(expected_file_size, header)
end
function simple_hdf5_template(
    h5_filename::AbstractString,
    dataset_name::AbstractString,
    dt::Type,
    ds::Dims
)
    return simple_hdf5_template(h5_filename, dataset_name, datatype(dt), dataspace(ds))
end


function create_h5_uint24()
    dt = HDF5.API.h5t_copy(HDF5.API.H5T_STD_U32LE)
    HDF5.API.h5t_set_size(dt, 3)
    HDF5.API.h5t_set_precision(dt, 24)
    return HDF5.Datatype(dt)
end

function create_h5_lower_uint12()
    dt = HDF5.API.h5t_copy(HDF5.API.H5T_STD_U32LE)
    HDF5.API.h5t_set_size(dt, 3)
    HDF5.API.h5t_set_precision(dt, 12)
    return HDF5.Datatype(dt)
end

function create_h5_upper_uint12()
    dt = HDF5.API.h5t_copy(HDF5.API.H5T_STD_U32LE)
    HDF5.API.h5t_set_size(dt, 3)
    HDF5.API.h5t_set_precision(dt, 12)
    # This may require an update to HDF5.jl
    HDF5.API.h5t_set_offset(dt, 12)
    return HDF5.Datatype(dt)
end

function get_template(;
    sz::Dims = (3456, 816, 17),
    header_length::Int = 2048,
    timepoints::AbstractVector{Int} = 0:43,
    filename::String = "template.h5",
    dt::HDF5.Datatype = datatype(UInt8)
)
    if (
        sz == (3456, 816, 17) &&
        header_length == 2048 &&
        timepoints == 0:43 &&
        dt == datatype(UInt8)
    )
        template_file = joinpath(@__DIR__, "..", "templates", "uint8_3456_816_17_44_header_2048.template")
        return load_binary_template(template_file)
    elseif (
        sz == (1152, 816, 17) &&
        header_length == 2048 &&
        timepoints == 0:43 &&
        dt == create_h5_uint24()
    )
        template_file = joinpath(@__DIR__, "..", "templates", "uint24_1152_816_17_44_header_2048.template")
        return load_binary_template(template_file)
    else
        return create_template(; sz, header_length, timepoints, filename, dt)
    end
end

function get_template(metadata::MatrixMetadata; dt::Union{HDF5.Datatype,Nothing} = nothing, filename = "template.h5")
    sz = Tuple(metadata.dimensions_XYZ)
    header_length = metadata.header_size
    timepoints = 0:metadata.timepoints_per_stack-1
    if isnothing(dt)
        if metadata.bit_depth == 12
            dt = datatype(UInt8)
        elseif metadata.bit_depth == 16
            dt = datatype(UInt16)
        end
    end
    sz1 = first(sz) * metadata.bit_depth ÷ HDF5.h5t_get_size(dt) ÷ 8
    get_template(; sz = (sz1, sz[2:end]...), header_length, timepoints, filename, dt)
end

get_uint24_template(; sz::Dims = (1152, 816, 17), kwargs...) = get_template(; dt = create_h5_uint24(), sz, kwargs...)
get_uint24_template(metadata::MatrixMetadata; dt::HDF5.Datatype = create_h5_uint24(), kwargs...) = get_template(metadata; dt, kwargs...)

function create_template(;
    sz::Dims = (3456, 816, 17),
    header_length::Int = 2048,
    timepoints::AbstractVector{Int} = 0:43,
    filename::String = "template.h5",
    dt::HDF5.Datatype = datatype(UInt8)
)
    expected_length = prod(sz)*HDF5.API.h5t_get_size(dt) + header_length

    # First create a template file with the expected datasets followed by a spacer
    println("Creating Naive Template...")
    last_timepoint = last(timepoints)
    ind = h5open(filename, "w") do h5f
        for i in timepoints
            create_dataset(h5f, @sprintf("TM%07d", i), dt, sz; alloc_time = :early)
            if i != last_timepoint
                create_dataset(h5f, nothing, datatype(UInt8), (header_length,); alloc_time = :early)
            end
        end
        # Calculate the difference in the offsets of each real dataset
        d = diff([HDF5.API.h5d_get_offset(h5f[k]) for k in keys(h5f) if startswith(k, "TM")])
        # Record the indices that are not of the expected length
        ind = timepoints[1:end-1][d .!= expected_length]
        return ind
    end

    # Next create a template file with some of the spacers set to length zero
    println("Refining template for regular offsets...")
    offsets, storage, meta_offsets = h5open(filename, "w") do h5f
        datasets = HDF5.Dataset[]
        for i in timepoints
            ds = create_dataset(h5f, @sprintf("TM%07d", i), dt, sz; alloc_time = :early)
            push!(datasets, ds)
            if i != last_timepoint
                space = i in ind ? 0 : header_length
                spacer = create_dataset(h5f, nothing, datatype(UInt8), (space,); alloc_time = :early)
                push!(datasets, spacer)
            end
        end
    	offsets = [HDF5.API.h5d_get_offset(ds) for ds in datasets]
        d = diff([HDF5.API.h5d_get_offset(h5f[k]) for k in keys(h5f) if startswith(k, "TM")])
        @assert all(d .== expected_length)
    	storage = [HDF5.API.h5d_get_storage_size(ds) for ds in datasets]
        # Look for introns, the space between datasets
        meta_offsets = setdiff(offsets .+ storage, offsets)
        # Include the first header
        pushfirst!(meta_offsets, 0)
        return (offsets, storage, meta_offsets)
    end

    # Read in header_length chunks at the meta_offsets
    println("Reading in chunks.")
    meta_chunks = open(filename, "r") do template
        meta_chunks = Vector{Vector{UInt8}}()
        for mo in meta_offsets
            seek(template, mo)
            push!(meta_chunks, read(template, header_length))
        end
        return meta_chunks
    end
    println("Done.")

    lengths = length.(meta_chunks)

    return BinaryTemplate(filesize(filename), meta_offsets, meta_chunks)
end

function create_uint24_template(; 
    sz::Dims = (1152, 816, 17),
    dt::HDF5.Datatype = create_h5_uint24(),
    kwargs...
)
    create_template(; sz, dt, kwargs...)
end

function template_from_h5(h5_filename)
    #expected_length = filesize(h5_filename)

    println("Reading $h5_filename")
    offsets, storage, meta_offsets = h5open(h5_filename, "r") do h5f
        offsets = [HDF5.API.h5d_get_offset(h5f[k]) for k in keys(h5f) if startswith(k, "TM")]
        d = diff(offsets)
        @assert all(d .== first(d))
    	storage = [HDF5.API.h5d_get_storage_size(h5f[k]) for k in keys(h5f)]
        # Look for introns, the space between datasets
        meta_offsets = setdiff(offsets .+ storage, offsets)
        # Include the first header
        pushfirst!(meta_offsets, 0)
        return (offsets, storage, meta_offsets)
    end

    println("Reading in chunks.")
    header_length = offsets[1]
    meta_chunks = open(h5_filename, "r") do template
        meta_chunks = Vector{Vector{UInt8}}()
        for mo in meta_offsets
            seek(template, mo)
            push!(meta_chunks, read(template, header_length))
        end
        return meta_chunks
    end
    println("Done.")

    return BinaryTemplate(filesize(h5_filename), meta_offsets, meta_chunks)
end

function match_timestrings(meta_chunks::Vector{Vector{UInt8}})
    pattern = r"TM(\d{7})"
    matches = map(meta_chunks) do chunk
        eachmatch(pattern, String(copy(chunk)))
    end
    return matches
end

function extract_timepoints(meta_chunks::Vector{Vector{UInt8}})
    match_timestrings(meta_chunks) |> Iterators.flatten .|> (m->parse(Int, m.captures[1])) |> sort
end

function extract_timepoints(t::AbstractBinaryTemplate)
    extract_timepoints(chunks(t))
end

function translate_datasets(
    parent::Union{HDF5.File, HDF5.Group},
    in_timepoints::AbstractVector{Int},
    out_timepoints::AbstractVector{Int}
)
    foreach(in_timepoints, out_timepoints) do input, output
        move_link(parent, @sprintf("TM%07d", input), @sprintf("TM%07d", output))
    end
end

function translate_datasets(
    parent::Union{HDF5.File, HDF5.Group},
    timepoint_offset::Int
)
    for k in keys(parent)
        m = match(r"TM(\d{7})", k)
        if !isnothing(m)
            new_t = parse(Int, m.captures[1]) +  timepoint_offset
            move_link(parent, k, @sprintf("TM%07d", new_t))
        end
    end
end

function translate_datasets(filename::AbstractString, args...)
    h5open(filename, "r+") do h5f
        translate_datasets(h5f, args...)
    end
end

function group_datasets(
    parent::AbstractString,
    group
)
    return h5open(parent, "r+") do h5f
        group_datasets(h5f, group)
    end
end

function group_datasets(
    parent::Union{HDF5.File, HDF5.Group},
    group::AbstractString
)
    if haskey(parent, group)
        group = parent[group]
    else
        group = create_group(parent, group)
    end
    return group_datasets(parent, group)
end

function group_datasets(
    parent::Union{HDF5.File, HDF5.Group},
    group::HDF5.Group
)
    for k in keys(parent)
        m = match(r"TM(\d{7})", k)
        if !isnothing(m)
            move_link(parent, k, group)
        end
    end
    return group
end

function apply_template(
    stack_filename::AbstractString,
    meta_offsets::AbstractVector{Int},
    meta_chunks::Vector{Vector{UInt8}};
    truncate_to_filesize::Int = 0
)
    open(stack_filename, "r+") do f
        if truncate_to_filesize > 0
            truncate(f, truncate_to_filesize)
        end
        for (offset, chunk) in zip(meta_offsets, meta_chunks)
            seek(f, offset)
            write(f, chunk)
        end
    end
end

function apply_template(
    stack_filename::AbstractString,
    t::AbstractBinaryTemplate;
    backup_filename::AbstractString = joinpath("backup", splitext(stack_filename)[1] * "_backup.template"),
    ensure_zero::Bool = true,
    truncate::Bool = false
)
    truncate_to_filesize = 0
    if truncate
        truncate_to_filesize = expected_file_size(t)
    else
        @assert filesize(stack_filename) == expected_file_size(t) "$stack_filename is not the expected size of $(expected_file_size(t))."
    end
    backup = backuptemplate(stack_filename, t)
    if ensure_zero
        for chunk in chunks(backup)
            if !all(==(0), chunk)
                error("Non-zero value found in $stack_filename when applying template. Use keyword `ensure_zero = false` to override.")
            end
        end
    end
    save(backup, backup_filename, "a")
    apply_template(stack_filename, offsets(t), chunks(t); truncate_to_filesize)
    return backup
end

end # module BinaryTemplates
