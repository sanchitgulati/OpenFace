# Local libraries
include_directories(${LandmarkDetector_SOURCE_DIR}/include)
	
# Define the functions in a separate source file
add_library(FeatureExtractionLib SHARED FeatureExtractionLib.cpp)
# Define the executable target and add the source files containing the main function
add_executable(FeatureExtractionModified FeatureExtractionLib.cpp)
target_link_libraries(FeatureExtractionLib LandmarkDetector)
target_link_libraries(FeatureExtractionLib FaceAnalyser)
target_link_libraries(FeatureExtractionLib GazeAnalyser)
target_link_libraries(FeatureExtractionLib Utilities)
target_link_libraries(FeatureExtractionModified LandmarkDetector)
target_link_libraries(FeatureExtractionModified FaceAnalyser)
target_link_libraries(FeatureExtractionModified GazeAnalyser)
target_link_libraries(FeatureExtractionModified Utilities)
add_compile_options(-fPIC)
add_compile_options(-fPIE)
install (TARGETS FeatureExtractionLib DESTINATION lib)
install(TARGETS FeatureExtractionModified DESTINATION bin)