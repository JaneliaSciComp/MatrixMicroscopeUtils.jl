using Pkg
Pkg.activate(dirname(@__DIR__))

using ArgParse

s = ArgParseSettings(
    prog="scripts/get_template_for_acquisition.jl",
    description="Obtain a HDF5 template to be used during acquisition"
)

@add_arg_table! s begin
    "xml_metadata_file"
        help = "XML metadata file"
        arg_type = String
        required = false
        default = ""
    "hdf5_template_file"
        help = "HDF5 template file to create"
        arg_type = String
        required = false
        default = ""
end

a = parse_args(ARGS, s)
xml_metadata_file = a["xml_metadata_file"]
# If no XML file is given, find the single XML file in the current working directory.
if isempty(xml_metadata_file)
    local_xml_files = filter(endswith(".xml"), readdir())
    if length(local_xml_files) == 0
        error("No XML files found in $(pwd())")
    elseif length(local_xml_files) != 1
        error("More than one XML file found in $(pwd())")
    end
    xml_metadata_file = joinpath(pwd(), first(local_xml_files))
elseif !isfile(xml_metadata_file)
    error("Could not find XML file: $xml_metadata_file")
end

# If no template file is given, default to a "template.hdf5" file in the same directory as the XML file
if isempty(a["hdf5_template_file"])
    hdf5_template_file = joinpath(dirname(xml_metadata_file), "template.hdf5")
elseif !isabspath(a["hdf5_template_file"])
    # If a relative path is given, it is relative to the current working directory
    hdf5_template_file = abspath(a["hdf5_template_file"])
else
    hdf5_template_file = a["hdf5_template_file"]
end
@info "Detected argument values" xml_metadata_file hdf5_template_file

using MatrixMicroscopeUtils
metadata = MatrixMicroscopeUtils.parse_info_xml(xml_metadata_file)
MatrixMicroscopeUtils.MatrixBinaryTemplates.get_template(metadata; filename = hdf5_template_file)
