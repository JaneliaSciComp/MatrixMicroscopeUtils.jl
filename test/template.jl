using Test
using MatrixMicroscopeUtils: parse_info_xml
using MatrixMicroscopeUtils.MatrixBinaryTemplates
using MatrixMicroscopeUtils.MatrixBinaryTemplates: load_template_properties
using BinaryTemplates
using HDF5

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

@testset "Templates" begin

    xmlfilenames = (
        xmlfilename_cam2_2022 = joinpath(@__DIR__, "xml/_20220310_110256(header 2048)/cam2.xml"),
        xmlfilename_cam5_per_timepoint_2022 = joinpath(@__DIR__, "xml/headers_2022_09/cam5(per timepoint).xml"),
        xmlfilename_cam5_single_header_2022 = joinpath(@__DIR__, "xml/headers_2022_09/cam5(single header).xml")
    )
    for xmlfilename in xmlfilenames
        m = parse_info_xml(xmlfilename)
        temp_hdf5_filename = tempname(; cleanup = false)
        try
            # Get or crate the template
            template = get_template(m, filename = temp_hdf5_filename)
            if isfile(temp_hdf5_filename)
                @test HDF5.isfile(temp_hdf5_filename)
                rm(temp_hdf5_filename)
            end

            # Apply the template to an empty file
            open(temp_hdf5_filename, "w") do io
                truncate(io, expected_file_size(template))
            end
            apply_template(temp_hdf5_filename, template)
            properties = load_template_properties(temp_hdf5_filename)

            expected_datatype =
                m.bit_depth == 8 ? datatype(UInt8) :
                m.bit_depth == 12 ? MatrixBinaryTemplates.create_h5_uint24() :
                m.bit_depth == 16 ? datatype(UInt16)  :
                error("Unknown bit_depth: $(m.bit_depth)")
                
            @test HDF5.ishdf5(temp_hdf5_filename)

            num_datasets, dataset_size, dataset_offset = h5open(temp_hdf5_filename) do h5f
                num_datasets = length(keys(h5f))
                dataset = first(h5f)
                dataset_size = size(dataset)
                dataset_offset = HDF5.API.h5d_get_offset(dataset)
                return num_datasets, dataset_size, dataset_offset
            end

            @test properties.dt == expected_datatype
            @test m.header_size == properties.header_size
            @test m.timepoints_per_stack == length(properties.timepoints)
            @test properties.timepoints == 0:m.timepoints_per_stack-1
            @test dataset_size[1] == m.dimensions_XYZ.X * m.bit_depth ÷ HDF5.API.h5t_get_size(expected_datatype) ÷ 8
            @test m.header_size == dataset_offset
            @test m.header_size == length(first(chunks(template)))

            if m.header_mode == "Single header"
                # Single header per file
                @test properties.header_mode == :single_header
                @test length(offsets(template)) == 1

                @test num_datasets == 1
                @test dataset_size[2:end-1] == Tuple(m.dimensions_XYZ)[2:end]
                @test dataset_size[end] == m.timepoints_per_stack
            else
                # Header per timepoint
                @test properties.header_mode == :per_timepoint
                @test length(offsets(template)) >= 1

                @test num_datasets == m.timepoints_per_stack
                @test dataset_size[2:end] == Tuple(m.dimensions_XYZ)[2:end]
            end
        finally
            if isfile(temp_hdf5_filename)
                rm(temp_hdf5_filename)
            end
        end
    end
end
