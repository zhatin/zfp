#!/usr/bin/env sh

# pass additional args in $1 (starting with whitespace character)
run_config () {
  config_cmd=(cmake -G "$GENERATOR" "-DCMAKE_BUILD_TYPE=$BUILD_TYPE" ..)

  # satisfy mingw builds
  if [ $COMPILER != "msvc" ]
  then
    config_cmd=(${config_cmd[@]} -DCMAKE_SH=CMAKE_SH-NOTFOUND)
  fi

  echo "${config_cmd[@]}"
  echo "${config_cmd[@]}$1"

  # execute command
  $(${config_cmd[@]}$1)
}

run_build () {
  build_cmd="cmake --build ."

  # msvc requires extra build args
  if [ $COMPILER == "msvc" ]
  then
    build_cmd="${build_cmd} --config $BUILD_TYPE"
  fi

  echo "${build_cmd}"

  # execute command
  $(${build_cmd})
}

# pass additional args in $1 (starting with whitespace character)
run_tests () {
  test_cmd="ctest -V -C $BUILD_TYPE"

  echo "${test_cmd}$1"

  # execute command
  $(${test_cmd}$1)
}

# create build dir for out-of-source build
mkdir build
cd build

# config without OpenMP, with CFP (and custom namespace)
run_config " -ZFP_WITH_OPENMP=OFF -DBUILD_CFP=ON -DCFP_NAMESPACE=cfp2"
run_build
run_tests

rm -rf ./*

# config with OpenMP
run_config " -DZFP_WITH_OPENMP=ON -DZFP_ENDTOEND_TESTS_ONLY=1"
run_build
# only run tests not run in previous build, due to appveyor time limit (1 hour)
run_tests " -R \".*Omp.*\""
