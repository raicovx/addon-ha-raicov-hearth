# ha base image
ARG BUILD_FROM

# The Hearth app image published by ha-raicov-hearth's docker-publish
# workflow. Release builds pass the matching version tag, edge builds pass the
# master image pinned by digest. Its bundle and production deps are plain JS,
# so either platform variant works on both add-on architectures.
ARG HEARTH_IMAGE=ghcr.io/raicovx/ha-raicov-hearth:latest

FROM ${HEARTH_IMAGE} AS hearth

# second stage
FROM $BUILD_FROM
WORKDIR /rootfs

# copy files to /rootfs
COPY --from=hearth /app/build ./build
COPY --from=hearth /app/node_modules ./node_modules
COPY --from=hearth /app/server.js .
COPY --from=hearth /app/package.json .

# copy run
COPY run.sh /

# install node, point the app's data directory at the supervisor volume so the
# dashboard survives updates, and chmod run
RUN apk add --no-cache nodejs-current && \
  ln -s /data /rootfs/data && \
  chmod a+x /run.sh

# set environment
ENV PORT=8099 \
  NODE_ENV=production

CMD [ "/run.sh" ]
