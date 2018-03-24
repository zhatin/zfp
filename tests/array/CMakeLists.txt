add_executable(testArray1d testArray1d.cpp)
target_link_libraries(testArray1d gtest gtest_main zfp hash64Lib genSmoothRandNumsLib)
add_test(NAME testArray1d COMMAND testArray1d)

add_executable(testArray2dRefs testArray2dRefs.cpp)
target_link_libraries(testArray2dRefs gtest gtest_main zfp hash64Lib rand64Lib)
add_test(NAME testArray2dRefs COMMAND testArray2dRefs)

add_executable(testArray3dPtrs testArray3dPtrs.cpp)
target_link_libraries(testArray3dPtrs gtest gtest_main zfp)
add_test(NAME testArray3dPtrs COMMAND testArray3dPtrs)

add_executable(testArray3dIters testArray3dIters.cpp)
target_link_libraries(testArray3dIters gtest gtest_main zfp)
add_test(NAME testArray3dIters COMMAND testArray3dIters)

# float
add_executable(testArray3f testArray3f.cpp)
target_link_libraries(testArray3f gtest gtest_main zfp hash32Lib genSmoothRandNumsLib)
add_test(NAME testArray3f COMMAND testArray3f)

add_executable(testArray3fRefs testArray3fRefs.cpp)
target_link_libraries(testArray3fRefs gtest gtest_main zfp hash32Lib rand32Lib)
add_test(NAME testArray3fRefs COMMAND testArray3fRefs)

add_executable(testArray2fPtrs testArray2fPtrs.cpp)
target_link_libraries(testArray2fPtrs gtest gtest_main zfp)
add_test(NAME testArray2fPtrs COMMAND testArray2fPtrs)

add_executable(testArray2fIters testArray2fIters.cpp)
target_link_libraries(testArray2fIters gtest gtest_main zfp)
add_test(NAME testArray2fIters COMMAND testArray2fIters)
