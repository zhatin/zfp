#!/usr/bin/env sh

mkdir build
cd build

# build/test without OpenMP, with CFP (and custom namespace)
if [ $COMPILER == "msvc" ]
then
  cmake -G "${GENERATOR}" -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" -DZFP_WITH_OPENMP=OFF -DBUILD_CFP=ON -DCFP_NAMESPACE=cfp2 ..
else
  cmake -G "${GENERATOR}" -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" -DCMAKE_SH=CMAKE_SH-NOTFOUND -DZFP_WITH_OPENMP=OFF -DBUILD_CFP=ON -DCFP_NAMESPACE=cfp2 ..
fi

if [ $COMPILER == "msvc" ]
then
  cmake --build . --config "${BUILD_TYPE}"
else
  cmake --build .
fi

ctest -V -C "${BUILD_TYPE}"

rm -rf ./*

# build/test with OpenMP
if [ $COMPILER == "msvc" ]
then
  cmake -G "${GENERATOR}" -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" -DZFP_WITH_OPENMP=ON -DZFP_ENDTOEND_TESTS_ONLY=1 ..
else
  cmake -G "${GENERATOR}" -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" -DCMAKE_SH=CMAKE_SH-NOTFOUND -DZFP_WITH_OPENMP=ON -DZFP_ENDTOEND_TESTS_ONLY=1 ..
fi

if [ $COMPILER == "msvc" ]
then
  cmake --build . --config "${BUILD_TYPE}"
else
  cmake --build .
fi

# only run tests not run in previous build, due to appveyor time limit (1 hour)
ctest -V -C "${BUILD_TYPE}" -R ".*Omp.*"
