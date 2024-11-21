mkdir devtools

mkdir devtools/JDK

mkdir devtools/android

mkdir devtools/android/cmdline-tools

cd devtools/JDK/
wget https://builds.openlogic.com/downloadJDK/openlogic-openjdk/17.0.13+11/openlogic-openjdk-17.0.13+11-linux-x64.tar.gz
cd devtools/android/cmdline-tools
apt install unzip
wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip commandlinetools-linux-9477386_latest.zip
mv cmdline-tools tools

Set environment variables:
nano ~/.bashrc
add the code:

JAVA_HOME="/root/devtools/JDK/openlogic-openjdk-17.0.13+11-linux-x64"
ANDROID_HOME="/root/devtools/android"
export JAVA_HOME
export ANDROID_HOME
PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/tools/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"

source ~/.bashrc
Check:
java --version
sdkmanager --version

Install Android Platform and Build Tools:
sdkmanager --list
sdkmanager "platform-tools" "platforms;android-33"
sdkmanager "build-tools;33.0.2”

Add android system image:

sdkmanager --list

sdkmanager "system-images;android-33;google_apis_playstore;x86_64"

*Creating the AVD:

avdmanager create avd --name “devAvd" --package "system-images;android-33;google_apis_playstore;x86_64"

🔷 List avds:

emulator -list-avds

🔷 Running the emulator:

adb start-server

emulator -avd devAvd
