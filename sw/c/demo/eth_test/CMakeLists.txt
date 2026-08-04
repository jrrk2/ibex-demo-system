add_executable(eth_test main.c)
target_include_directories(eth_test PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(eth_test common)
