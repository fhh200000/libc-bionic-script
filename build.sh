#!/bin/bash
export ALLOW_MISSING_DEPENDENCIES=true
export ANDROID_VERSION="android-14.0.0_r9"
export ANDROID_VERSION_MAJOR="14"

# mirror of https://android.googlesource.com in China
export AOSP_MIRROR="https://mirrors.tuna.tsinghua.edu.cn/git/AOSP"

git clone ${AOSP_MIRROR}/platform/superproject android -b ${ANDROID_VERSION} --depth=1
git clone ${AOSP_MIRROR}/platform/build android/build/make -b ${ANDROID_VERSION} --depth=1
cd android

packages=(
"build/orchestrator" "build/blueprint" "build/pesto" "build/soong" "build/bazel" "build/bazel_common_rules"

"prebuilts/go/linux-x86" "prebuilts/build-tools" "prebuilts/vndk/v29" "prebuilts/vndk/v30" "prebuilts/sdk"
"prebuilts/vndk/v31" "prebuilts/vndk/v32" "prebuilts/vndk/v33" "prebuilts/rust"
"prebuilts/jdk/jdk17" "prebuilts/bazel/common" "prebuilts/bazel/linux-x86_64" "prebuilts/clang/host/linux-x86"
"prebuilts/clang-tools" "prebuilts/abi-dumps/platform" "prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.17-4.8"
"prebuilts/module_sdk/art"

"external/golang-protobuf" "external/go-cmp" "external/spdx-tools" "external/starlark-go" "external/bazel-skylib"
"external/avb" "external/bazelbuild-rules_android" "external/bazelbuild-rules_license" "external/sqlite"
"external/python/absl-py" "external/python/apitools"  "external/python/asn1crypto" "external/python/bumble"
"external/python/cachetools" "external/python/cffi" "external/python/cpython2" "external/python/cpython3"
"external/python/cryptography" "external/python/dateutil" "external/python/enum34"  "external/python/google-auth-library-python"
"external/python/google-api-python-client"  "external/python/httplib2" "external/python/ipaddress"
"external/python/jinja" "external/python/markupsafe" "external/python/oauth2client" "external/python/parse_type"
"external/python/portpicker" "external/python/pyasn1" "external/python/pyasn1-modules" "external/python/pybind11"
"external/python/pycparser" "external/lzma" "external/python/pyee" "external/python/pyfakefs" "external/python/pyserial"
"external/python/python-api-core" "external/python/pyyaml" "external/python/rsa" "external/python/setuptools"
"external/python/six" "external/python/timeout-decorator" "external/python/typing" "external/python/uritemplates"
"external/gwp_asan" "external/scudo" "external/bazelbuild-kotlin-rules" "external/libcxxabi" "external/libcxx"
"external/compiler-rt" "external/fmtlib" "external/arm-optimized-routines" "external/pthreadpool" "external/zlib"
"external/protobuf" "external/rust/crates/rustc-demangle" "external/rust/crates/rustc-demangle-capi"
"system/sepolicy" "system/core" "system/logging" "system/libbase" "system/libziparchive" "system/unwinding"
"system/libprocinfo" "external/googletest"

"bionic"
)


for package in ${packages[@]}
do
    git clone ${AOSP_MIRROR}/platform/${package} ${package} -b ${ANDROID_VERSION} --depth=1
done

# Patch source file to allow building with incomplete dependencies

sed -i 's@$(call inherit-product, packages/modules/Virtualization/apex/product_packages.mk)@\
#$(call inherit-product, packages/modules/Virtualization/apex/product_packages.mk)@g' \
build/make/target/product/aosp_x86_64.mk 

rm system/core/trusty/stats/aidl/Android.bp
cat << EOF > system/core/trusty/stats/aidl/Android.bp 
package {
    default_applicable_licenses: ["Android-Apache-2.0"],
}
EOF

rm -rf hardware/qcom

sed -i '/# We can do the cross-build only on Linux/N;s/\n/\nifeq ($(HOST_OS),linux-disabled) #/' \
build/core/envsetup.mk

sed -i 's/jdk11/jdk17/g' build/bazel/bin/bazel

. build/envsetup.sh

lunch aosp_x86_64-eng

mkdir -p cts/tests/tests/os/assets/
echo ${ANDROID_VERSION_MAJOR} > cts/tests/tests/os/assets/platform_releases.txt
echo ${ANDROID_VERSION_MAJOR} > cts/tests/tests/os/assets/platform_versions.txt 

m -j5 libc libc++ libdl libm libstdc++ liblog libbase linker
