# RandoEats BFF — multi-stage build.
#
# The Linode is x86-64 while dev Macs are ARM, so always build for amd64:
#   docker buildx build --platform linux/amd64 -t randoeats-bff:latest .
#
# Uses the official Drogon image (Drogon + deps prebuilt) so we don't recompile
# the framework. config.json is never baked into the image — mount it at runtime.

FROM drogonframework/drogon:latest AS build
WORKDIR /src
COPY CMakeLists.txt main.cc ./
COPY controllers/ controllers/
COPY services/ services/
RUN cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && \
    cmake --build build -j"$(nproc)"

FROM drogonframework/drogon:latest AS runtime
WORKDIR /app
COPY --from=build /src/build/randoeats_bff /app/randoeats_bff
EXPOSE 8848
# config.json (with the API key) and the log dir are mounted at runtime:
#   docker run -d --name randoeats-bff -p 8848:8848 \
#     -v /etc/randoeats/config.json:/app/config.json:ro \
#     -v /var/log/randoeats:/var/log/randoeats \
#     randoeats-bff:latest
ENTRYPOINT ["/app/randoeats_bff", "/app/config.json"]
