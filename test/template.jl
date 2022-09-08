function create_synthetic_stack(
    filename::AbstractString = tempname(),
    timepoint_data::Union{Nothing, Array} = nothing,
    bit_depth::Int = 12,
    timepoints_per_stack::Int = 0,
    header_size::Int = 2048,
)
    if isnothing(timepoint_data)
        timepoint_data = rand()
    end
    open(filename, "w") do f

    end
end
