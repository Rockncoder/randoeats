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
# Does this Drogon have PostgreSQL support compiled in? The production image
# (drogonframework/drogon) does; a stock Homebrew build does not. Detect rather
# than assume, so a machine without it still builds and tests everything else --
# and so selecting the postgres backend on such a build fails loudly instead of
# silently falling back (see CacheFactory.cc).
include(CheckCXXSourceCompiles)
set(CMAKE_REQUIRED_LIBRARIES Drogon::Drogon)
check_cxx_source_compiles("
#include <drogon/orm/DbClient.h>
int main() { auto c = drogon::orm::DbClient::newPgClient(\"\", 1); (void)c; return 0; }
" RANDOEATS_HAS_POSTGRES)
unset(CMAKE_REQUIRED_LIBRARIES)

add_library(randoeats_bff_lib OBJECT
  controllers/RestaurantController.cc
  services/GooglePlacesClient.cc
  services/PlacesService.cc
  services/InMemoryCache.cc
  services/CacheFactory.cc
  services/MetricsLogger.cc
)

if(RANDOEATS_HAS_POSTGRES)
  target_sources(randoeats_bff_lib PRIVATE services/PostgresCache.cc)
  target_compile_definitions(randoeats_bff_lib PUBLIC RANDOEATS_HAS_POSTGRES)
  message(STATUS "randoeats: PostgreSQL cache backend ENABLED")
else()
  message(STATUS "randoeats: PostgreSQL cache backend DISABLED (Drogon built without it)")
endif()
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

# Postgres-backed cache tests. Registered only when a connection string is
# provided, because they test SQL semantics against a real database and a fake
# would only test the fake. CI always sets RANDOEATS_TEST_PG_CONN, so this path
# is always graded somewhere -- it is never quietly skipped everywhere.
if(RANDOEATS_HAS_POSTGRES AND DEFINED ENV{RANDOEATS_TEST_PG_CONN})
  add_executable(randoeats_bff_pg_tests
    tests/test_main.cc
    tests/PostgresCacheTest.cc
  )
  target_link_libraries(randoeats_bff_pg_tests PRIVATE randoeats_bff_lib)
  if(ENABLE_SANITIZERS)
    target_compile_options(randoeats_bff_pg_tests PRIVATE ${SANITIZER_FLAGS})
    target_link_options(randoeats_bff_pg_tests PRIVATE ${SANITIZER_FLAGS})
  endif()
  add_test(NAME randoeats_bff_pg_tests COMMAND randoeats_bff_pg_tests)
  message(STATUS "randoeats: Postgres cache tests ENABLED")
endif()

# Runs against the built executable, which the unit suite cannot do: it is the
# only thing that proves the controllers survived the link. See the header of
# smoke_routes.sh for the production outage that motivated it.
add_test(NAME randoeats_bff_routes
         COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/tests/smoke_routes.sh $<TARGET_FILE:randoeats_bff>)

endif()
