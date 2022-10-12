using MatrixMicroscopeUtils: parse_info_xml, MatrixMetadata, generate_xml
using LightXML

@testset "MatrixMetadata" begin

xmlfilename_cam6_2020 = joinpath(@__DIR__, "xml/RC_20-09-24/cam6.xml")
xmlfilename_cam5_2021 = joinpath(@__DIR__, "xml/AgaroseBeads_561nm15pct_17Planes5umStep_20211011_113516/cam5.xml")
xmlfilename_cam8_2022 = joinpath(@__DIR__, "xml/RC_22-01-17/USAF_16bit_20220117_161054/cam8.xml")
xmlfilename_cam2_2022 = joinpath(@__DIR__, "xml/_20220310_110256(header 2048)/cam2.xml")
xmlfilename_cam5_per_timepoint_2022 = joinpath(@__DIR__, "xml/headers_2022_09/cam5(per timepoint).xml")
xmlfilename_cam5_single_header_2022 = joinpath(@__DIR__, "xml/headers_2022_09/cam5(single header).xml")

expected_num_children = 29
get_num_child_elements(xml::XMLDocument) = length(collect(child_elements(root(xml))))

metadata_cam6_2020_correct = MatrixMetadata()
let m = metadata_cam6_2020_correct
    m.version = "1.0"
    m.software_version ="1.0.02465"
    m.data_header = "test"
    m.specimen_name = "test"
    m.tile_XYZ_um = (X = 70.0, Y = 0.0, Z = -70.0)
    m.sampling_XYZ_um = (X = 0.34375, Y = 0.34375, Z =2.5)
    m.roi_XY = (left =0, top = 4608, width = 888, height = 1704)
    m.channel = 0
    m.wavelength_nm = 532.0
    m.laser_power = (percent = 0.0, mW = 0.0)
    m.frame_exposure_time_ms = 2.0
    m.detection_filter = "test"
    m.dimensions_XYZ = (X = 4608, Y = 816, Z = 17)
    m.stack_direction = "+Z"
    m.planes = 1:17
    m.timepoints = 128
    m.bit_depth = 12
    m.defect_correction = "off"
    m.experiment_notes = ""
    m.cam = 6
    m.metadata_file = xmlfilename_cam6_2020
    m.header_size = 0
    m.header_mode = "Per timepoint"
    m.timepoints_per_stack = 0
    m.XLong_mm = 0.0
    m.X_um = 0.0
    m.Y_um = 0.0
    m.Z_um = 0.0
    m.U_deg = 0.0
    m.V_deg = 0.0
    m.W_deg = 0.0
    m.xml = read(xmlfilename_cam6_2020, String)
end

@test parse_info_xml(xmlfilename_cam6_2020) == metadata_cam6_2020_correct
m2 = parse_info_xml(generate_xml(metadata_cam6_2020_correct))
m2.metadata_file = metadata_cam6_2020_correct.metadata_file
@test m2 == metadata_cam6_2020_correct
@test get_num_child_elements(generate_xml(m2)) == expected_num_children
@test get_num_child_elements(parse_string(read(xmlfilename_cam6_2020, String))) == 17

metadata_cam5_2021_correct = MatrixMetadata()
let m = metadata_cam5_2021_correct
    m.version = "1.0"
    m.software_version ="1.0.02590"
    m.data_header = "AgaroseBeads_561nm15pct_17Planes5umStep"
    m.specimen_name = "sample"
    m.tile_XYZ_um = (X = 0.0, Y = 0.0, Z = 0.0)
    m.sampling_XYZ_um = (X = 0.34375, Y = 0.34375, Z = 5.0)
    m.roi_XY = (left = 1152, top = 3456, width = 888, height = 1704)
    m.channel = 1
    m.wavelength_nm = 561.0
    m.laser_power = (percent = 15.0, mW = 0.0)
    m.frame_exposure_time_ms = 1.42
    m.detection_filter = "test"
    m.dimensions_XYZ = (X = 2304, Y = 816, Z = 17)
    m.stack_direction = "+Z"
    m.planes = 1:17
    m.timepoints = 446
    m.bit_depth = 12
    m.defect_correction = "off"
    m.experiment_notes = ""
    m.cam = 5
    m.metadata_file = xmlfilename_cam5_2021
    m.header_size = 0
    m.header_mode = "Per timepoint"
    m.timepoints_per_stack = 0
    m.XLong_mm = 0.0
    m.X_um = 0.0
    m.Y_um = 0.0
    m.Z_um = 0.0
    m.U_deg = 0.0
    m.V_deg = 0.0
    m.W_deg = 0.0

    m.xml = read(xmlfilename_cam5_2021, String)
end
@test parse_info_xml(xmlfilename_cam5_2021) == metadata_cam5_2021_correct
m2 = parse_info_xml(generate_xml(metadata_cam5_2021_correct))
m2.metadata_file = metadata_cam5_2021_correct.metadata_file
@test m2 == metadata_cam5_2021_correct
@test get_num_child_elements(generate_xml(m2)) == expected_num_children
@test get_num_child_elements(parse_string(read(xmlfilename_cam5_2021, String))) == 19

metadata_cam8_2022_correct = MatrixMetadata()
let m = metadata_cam8_2022_correct
    m.version = "1.0"
    m.software_version ="1.0.02614"
    m.data_header = "USAF_16bit"
    m.specimen_name = "sample"
    m.tile_XYZ_um = (X = 280.0, Y = 0.0, Z = 0.0)
    m.sampling_XYZ_um = (X = 0.34375, Y = 0.34375, Z = 3.437)
    m.roi_XY = (left = 2304, top = 4608, width = 888, height = 1704)
    m.channel = 1
    m.wavelength_nm = 488.0
    m.laser_power = (percent = 0.0, mW = 0.0)
    m.frame_exposure_time_ms = 11.6
    m.detection_filter = "test"
    m.dimensions_XYZ = (X = 2304, Y = 816, Z = 50)
    m.stack_direction = "+Z"
    m.planes = 1:50
    m.timepoints = 51
    m.bit_depth = 16
    m.defect_correction = "off"
    m.experiment_notes = ""
    m.cam = 8
    m.metadata_file = xmlfilename_cam8_2022
    m.header_size = 0
    m.header_mode = "Per timepoint"
    m.timepoints_per_stack = 0
    m.XLong_mm = 0.0
    m.X_um = 0.0
    m.Y_um = 0.0
    m.Z_um = 0.0
    m.U_deg = 0.0
    m.V_deg = 0.0
    m.W_deg = 0.0
    m.xml = read(xmlfilename_cam8_2022, String)
end
@test parse_info_xml(xmlfilename_cam8_2022) == metadata_cam8_2022_correct
m2 = parse_info_xml(generate_xml(metadata_cam8_2022_correct))
m2.metadata_file = metadata_cam8_2022_correct.metadata_file
@test m2 == metadata_cam8_2022_correct
@test get_num_child_elements(generate_xml(m2)) == expected_num_children
@test get_num_child_elements(parse_string(read(xmlfilename_cam8_2022, String))) == 19

metadata_cam2_2022_correct = MatrixMetadata()
let m = metadata_cam2_2022_correct
    m.version = "1.0"
    m.software_version = "1.0.02617"
    m.data_header = ""
    m.specimen_name = "sample"
    m.tile_XYZ_um =  (X = -280.0, Y = 0.0, Z = 0.0)
    m.sampling_XYZ_um =  (X = 0.34375, Y = 0.34375, Z = 3.437)
    m.roi_XY =  (left = 2304, top = 4608, width = 888, height = 1704)
    m.channel = 1
    m.wavelength_nm = 488.0
    m.laser_power =  (percent = 0.0, mW = 0.0)
    m.frame_exposure_time_ms = 1.33
    m.detection_filter = "test"
    m.dimensions_XYZ = (X = 2304, Y = 816, Z = 17)
    m.stack_direction = "+Z"
    m.planes =  1:17
    m.timepoints = 936
    m.bit_depth = 12
    m.defect_correction = "off"
    m.experiment_notes = ""
    m.cam = 2
    m.header_size =  2048
    m.header_mode = "Per timepoint"
    m.timepoints_per_stack = 44
    m.metadata_file = xmlfilename_cam2_2022
    m.XLong_mm = 0.0
    m.X_um = 0.0
    m.Y_um = 0.0
    m.Z_um = 0.0
    m.U_deg = 0.0
    m.V_deg = 0.0
    m.W_deg = 0.0
    m.xml = read(xmlfilename_cam2_2022, String)
end
@test parse_info_xml(xmlfilename_cam2_2022) == metadata_cam2_2022_correct
m2 = parse_info_xml(generate_xml(metadata_cam2_2022_correct))
m2.metadata_file = metadata_cam2_2022_correct.metadata_file
@test m2 == metadata_cam2_2022_correct
@test get_num_child_elements(generate_xml(m2)) == expected_num_children
@test get_num_child_elements(parse_string(read(xmlfilename_cam2_2022, String))) == 21

metadata_cam5_per_timepoint_2022_correct = MatrixMetadata()
let m = metadata_cam5_per_timepoint_2022_correct
    m.version = "1.0"
    m.software_version = "1.0.02641"
    m.data_header = ""
    m.specimen_name = "test"
    m.tile_XYZ_um =  (X = 70.0, Y = 0.0, Z = -70.0)
    m.sampling_XYZ_um =  (X = 0.34375, Y = 0.34375, Z = 5.0)
    m.roi_XY = (left = 0, top = 4608, width = 0, height = 2592)
    m.channel = 1
    m.wavelength_nm = 488.0
    m.laser_power = (percent = 20.0, mW = 0.0)
    m.frame_exposure_time_ms =  0.0
    m.detection_filter = "test1"
    m.dimensions_XYZ =  (X = 4608, Y = 2592, Z = 21)
    m.stack_direction = "+Z"
    m.planes =  1:21
    m.timepoints = 12
    m.bit_depth = 16
    m.defect_correction = "on"
    m.experiment_notes = ""
    m.cam = 5
    m.header_size = 2048
    m.header_mode = "Per timepoint"
    m.timepoints_per_stack = 4
    m.metadata_file = xmlfilename_cam5_per_timepoint_2022
    m.XLong_mm = 0.0
    m.X_um = 1.0
    m.Y_um = 2.0
    m.Z_um = 3.0
    m.U_deg = 4.0
    m.V_deg = 5.0
    m.W_deg = 6.0
    m.xml = read(xmlfilename_cam5_per_timepoint_2022, String)
end
@test parse_info_xml(xmlfilename_cam5_per_timepoint_2022) == metadata_cam5_per_timepoint_2022_correct
m2 = parse_info_xml(generate_xml(metadata_cam5_per_timepoint_2022_correct))
m2.metadata_file = metadata_cam5_per_timepoint_2022_correct.metadata_file
@test m2 == metadata_cam5_per_timepoint_2022_correct
@test get_num_child_elements(generate_xml(m2)) == expected_num_children
@test get_num_child_elements(parse_string(read(xmlfilename_cam5_per_timepoint_2022, String))) == 29

metadata_cam5_single_header_2022_correct = MatrixMetadata()
let m = metadata_cam5_single_header_2022_correct
    m.version = "1.0"
    m.software_version = "1.0.02641"
    m.data_header = ""
    m.specimen_name = "test"
    m.tile_XYZ_um =  (X = 70.0, Y = 0.0, Z = -70.0)
    m.sampling_XYZ_um =  (X = 0.34375, Y = 0.34375, Z = 5.0)
    m.roi_XY = (left = 0, top = 4608, width = 0, height = 2592)
    m.channel = 1
    m.wavelength_nm = 488.0
    m.laser_power = (percent = 20.0, mW = 0.0)
    m.frame_exposure_time_ms =  0.0
    m.detection_filter = "test1"
    m.dimensions_XYZ =  (X = 4608, Y = 2592, Z = 21)
    m.stack_direction = "+Z"
    m.planes =  1:21
    m.timepoints = 12
    m.bit_depth = 16
    m.defect_correction = "on"
    m.experiment_notes = ""
    m.cam = 5
    m.header_size = 2048
    m.header_mode = "Single header"
    m.timepoints_per_stack = 4
    m.metadata_file = xmlfilename_cam5_single_header_2022
    m.XLong_mm = 0.0
    m.X_um = 1.0
    m.Y_um = 2.0
    m.Z_um = 3.0
    m.U_deg = 4.0
    m.V_deg = 5.0
    m.W_deg = 6.0
    m.xml = read(xmlfilename_cam5_single_header_2022, String)
end
@test parse_info_xml(xmlfilename_cam5_single_header_2022) == metadata_cam5_single_header_2022_correct
m2 = parse_info_xml(generate_xml(metadata_cam5_single_header_2022_correct))
m2.metadata_file = metadata_cam5_single_header_2022_correct.metadata_file
@test m2 == metadata_cam5_single_header_2022_correct
@test get_num_child_elements(generate_xml(m2)) == expected_num_children
@test get_num_child_elements(parse_string(read(xmlfilename_cam5_single_header_2022, String))) == 29

end
