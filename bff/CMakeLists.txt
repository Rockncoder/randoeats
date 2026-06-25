cmake_minimum_required(VERSION 3.16)
project(randoeats_bff CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Drogon brings in trantor + jsoncpp and enables C++20 coroutine support.
find_package(Drogon CONFIG REQUIRED)

add_executable(randoeats_bff
  main.cc
  controllers/RestaurantController.cc
  services/GooglePlacesClient.cc
  services/PlacesService.cc
  services/InMemoryCache.cc
  services/MetricsLogger.cc
)

target_include_directories(randoeats_bff PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(randoeats_bff PRIVATE Drogon::Drogon)
