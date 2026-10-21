FROM dart:3.13.5

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl git unzip xz-utils \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.47.7-stable.tar.xz \
      | tar -xJ -C /opt \
    && git config --global --add safe.directory /opt/flutter
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .

ENV PORT=8080
EXPOSE 8080
CMD ["dart", "run", "bin/zenith_server.dart"]
