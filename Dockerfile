FROM ubuntu:22.04

ENV UID=1000
ENV GID=1000
ENV USER="developer"
ENV JAVA_VERSION="17"
ENV ANDROID_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
ENV ANDROID_VERSION="34"
ENV ANDROID_BUILD_TOOLS_VERSION="34.0.0"
ENV ANDROID_ARCHITECTURE="x86_64"
ENV ANDROID_SDK_ROOT="/home/$USER/android"
ENV FLUTTER_CHANNEL="stable"
ENV FLUTTER_VERSION="3.22.0"
ENV FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/$FLUTTER_CHANNEL/linux/flutter_linux_$FLUTTER_VERSION-$FLUTTER_CHANNEL.tar.xz"
ENV FLUTTER_HOME="/home/$USER/flutter"
ENV FLUTTER_WEB_PORT="8090"
ENV FLUTTER_DEBUG_PORT="42000"
ENV FLUTTER_EMULATOR_NAME="flutter_emulator"
ENV PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/emulator:$ANDROID_SDK_ROOT/platform-tools:$FLUTTER_HOME/bin:$PATH"

# Install all dependencies
ENV DEBIAN_FRONTEND="noninteractive"
RUN apt-get update \
  && apt-get install --yes --no-install-recommends openjdk-$JAVA_VERSION-jdk curl unzip sed git bash xz-utils libglvnd0 ssh xauth x11-xserver-utils libpulse0 libxcomposite1 libgl1-mesa-glx sudo \
  && rm -rf /var/lib/{apt,dpkg,cache,log}

# Create user
RUN groupadd --gid $GID $USER \
  && useradd -s /bin/bash --uid $UID --gid $GID -m $USER \
  && echo $USER ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USER \
  && chmod 0440 /etc/sudoers.d/$USER

USER $USER
WORKDIR /home/$USER

# Android SDK
RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools/latest \
  && curl -o cmdline-tools.zip $ANDROID_TOOLS_URL \
  && unzip cmdline-tools.zip -d $ANDROID_SDK_ROOT \
  && mv $ANDROID_SDK_ROOT/cmdline-tools/NOTICE.txt $ANDROID_SDK_ROOT/cmdline-tools/latest \
  && mv $ANDROID_SDK_ROOT/cmdline-tools/bin $ANDROID_SDK_ROOT/cmdline-tools/latest \
  && mv $ANDROID_SDK_ROOT/cmdline-tools/lib $ANDROID_SDK_ROOT/cmdline-tools/latest \
  && mv $ANDROID_SDK_ROOT/cmdline-tools/source.properties $ANDROID_SDK_ROOT/cmdline-tools/latest \
  && rm cmdline-tools.zip

RUN ls $ANDROID_SDK_ROOT/cmdline-tools/latest \
  && sleep 10
RUN sdkmanager --list
RUN yes "y" | sdkmanager --licenses 
RUN yes "y" | sdkmanager "build-tools;$ANDROID_BUILD_TOOLS_VERSION" 
RUN yes "y" | sdkmanager "platforms;android-$ANDROID_VERSION" 
RUN yes "y" | sdkmanager "platform-tools" 
RUN yes "y" | sdkmanager "emulator" 
RUN yes "y" | sdkmanager "system-images;android-$ANDROID_VERSION;google_apis_playstore;$ANDROID_ARCHITECTURE"



# Flutter
RUN curl -o flutter.tar.xz $FLUTTER_URL \
  && mkdir -p $FLUTTER_HOME \
  && tar xf flutter.tar.xz -C /home/$USER \
  && rm flutter.tar.xz \
  && flutter config --no-analytics \
  && flutter precache \
  && yes "y" | flutter doctor --android-licenses \
  && flutter doctor \
  && flutter emulators --create \
  && flutter update-packages

COPY entrypoint.sh /usr/local/bin/
COPY chown.sh /usr/local/bin/
COPY flutter-android-emulator.sh /usr/local/bin/flutter-android-emulator
ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
