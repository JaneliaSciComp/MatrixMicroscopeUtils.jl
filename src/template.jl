module MatrixBinaryTemplates # MatrixMicroscopeUtils.BinaryTemplates

using HDF5
using Printf
using CRC32c

import ..MatrixMicroscopeUtils
import ..MatrixMicroscopeUtils: MatrixMetadata

using BinaryTemplates
import BinaryTemplates: AbstractBinaryTemplate
using HDF5BinaryTemplates

export offsets, chunks, expected_file_size
export simple_hdf5_template, create_template, apply_template
export get_template, get_uint24_template
export translate

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
            #dt = datatype(UInt8)
            dt = create_h5_uint24()
        elseif metadata.bit_depth == 16
            dt = datatype(UInt16)
        end
    end
    sz1 = first(sz) * metadata.bit_depth ÷ HDF5.h5t_get_size(dt) ÷ 8
    get_template(; sz = (sz1, sz[2:end]...), header_length, timepoints, filename, dt)
end

get_uint24_template(; sz::Dims = (1152, 816, 17), kwargs...) = get_template(; dt = create_h5_uint24(), sz, kwargs...)
get_uint24_template(metadata::MatrixMetadata; dt::HDF5.Datatype = create_h5_uint24(), kwargs...) = get_template(metadata; dt, kwargs...)

get_uint8_template(metadata::MatrixMetadata; dt::HDF5.Datatype = create_h5_uint8(), kwargs...) = get_template(metadata; dt, kwargs...)



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
    backup_filename::AbstractString = backup_filename(stack_filename),
    ensure_zero::Bool = true,
    truncate::Bool = false
)
    truncate_to_filesize = 0
    if truncate
        truncate_to_filesize = expected_file_size(t)
    else
        @assert filesize(stack_filename) <= expected_file_size(t) "$stack_filename is not the expected size of $(expected_file_size(t))."
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

function backup_filename(stack_filename)
    dir = dirname(stack_filename)
    base = splitext(basename(stack_filename))[1]
    return joinpath(dir, "backup", base * "_backup.template")
end

end # module MatrixBinaryTemplates
