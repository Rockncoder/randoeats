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

# Everything except main(), so the test binary can link the real code.
#
# OBJECT, not STATIC. Drogon controllers self-register through static
# initialisers in their translation unit. In a STATIC library the linker drops
# any object file the executable does not reference a symbol from -- main.cc
# never names RestaurantController -- so the registration disappears and Drogon
# answers 404 on every controller route while /api/v1/health (registered
# directly in main.cc) keeps working. That shipped to production on 2026-08-29.
# An OBJECT library links every object into the consumer, preserving them.
add_library(randoeats_bff_lib OBJECT
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

# Runs against the built executable, which the unit suite cannot do: it is the
# only thing that proves the controllers survived the link. See the header of
# smoke_routes.sh for the production outage that motivated it.
add_test(NAME randoeats_bff_routes
         COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/tests/smoke_routes.sh $<TARGET_FILE:randoeats_bff>)

endif()
