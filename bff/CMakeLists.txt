cmake_minimum_required(VERSION 3.16)
project(randoeats_bff CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Drogon brings in trantor + jsoncpp and enables C++20 coroutine support.
find_package(Drogon CONFIG REQUIRED)

# Build the ASan/UBSan configuration of the library and tests. OFF by default so
# the shipped binary is never accidentally an instrumented one; the sanitizer
# build lives in its own build directory (see `just bff-test-asan`).
option(ENABLE_SANITIZERS "Build with AddressSanitizer and UndefinedBehaviorSanitizer" OFF)

# Everything except main(), so the test binary can link the real code. The
# shipped executable's contents are unchanged: it is this library plus main.cc.
add_library(randoeats_bff_lib STATIC
  controllers/RestaurantController.cc
  services/GooglePlacesClient.cc
  services/PlacesService.cc
  services/InMemoryCache.cc
  services/MetricsLogger.cc
)
target_include_directories(randoeats_bff_lib PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(randoeats_bff_lib PUBLIC Drogon::Drogon)

add_executable(randoeats_bff main.cc)
target_link_libraries(randoeats_bff PRIVATE randoeats_bff_lib)

# The deployable image's build context copies only CMakeLists.txt, main.cc,
# controllers/ and services/ -- it has no tests/ directory, and no reason to
# build tests. Default ON so a normal checkout gets the suite; bff/Dockerfile
# passes -DBUILD_TESTS=OFF.
option(BUILD_TESTS "Build the unit tests" ON)

if(BUILD_TESTS)

enable_testing()

add_executable(randoeats_bff_tests
  tests/test_main.cc
  tests/InMemoryCacheTest.cc
  tests/PlacesServiceTest.cc
)
target_link_libraries(randoeats_bff_tests PRIVATE randoeats_bff_lib)

if(ENABLE_SANITIZERS)
  # Applied to the library as well as the tests: instrumenting only the test
  # sources would leave the code under test uninstrumented, which is where the
  # memory errors actually are.
  set(SANITIZER_FLAGS -fsanitize=address,undefined -fno-omit-frame-pointer -g)
  target_compile_options(randoeats_bff_lib PUBLIC ${SANITIZER_FLAGS})
  target_link_options(randoeats_bff_lib PUBLIC ${SANITIZER_FLAGS})
  target_compile_options(randoeats_bff_tests PRIVATE ${SANITIZER_FLAGS})
  target_link_options(randoeats_bff_tests PRIVATE ${SANITIZER_FLAGS})
endif()

add_test(NAME randoeats_bff_tests COMMAND randoeats_bff_tests)

endif()
