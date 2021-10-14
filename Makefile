.PHONY: vendor

SHELL=/bin/bash # Use bash syntax
TF_URL=https://github.com/tensorflow/tensorflow/archive/refs/tags
TF_VERSION=2.6.0
TF_FILENAME=tensorflow-${TF_VERSION}
TF_TARBALL=${TF_FILENAME}.tar.gz

download:
	if [ ! -f ${TF_TARBALL} ]; then wget -O ${TF_TARBALL} ${TF_URL}/v${TF_VERSION}.tar.gz; fi
	tar -zxf ${TF_TARBALL}

download-arm64:
	curl -LO https://storage.googleapis.com/mirror.tensorflow.org/developer.arm.com/media/Files/downloads/gnu-a/8.3-2019.03/binrel/gcc-arm-8.3-2019.03-x86_64-aarch64-linux-gnu.tar.xz
	mkdir -p ./toolchains
	tar xvf gcc-arm-8.3-2019.03-x86_64-aarch64-linux-gnu.tar.xz -C ./toolchains

download-armhf:
	curl -LO https://storage.googleapis.com/mirror.tensorflow.org/developer.arm.com/media/Files/downloads/gnu-a/8.3-2019.03/binrel/gcc-arm-8.3-2019.03-x86_64-arm-linux-gnueabihf.tar.xz
	mkdir -p ./toolchains
	tar xvf gcc-arm-8.3-2019.03-x86_64-arm-linux-gnueabihf.tar.xz -C ./toolchains

build-lite-native:
	mkdir -p build-${ARCH}
	cd build-${ARCH}; cmake ../${TF_FILENAME}/tensorflow/lite/c; make

build-lite-amd64: ARCH=amd64
build-lite-amd64: build-lite-native

build-lite-arm64-native: ARCH=arm64
build-lite-arm64-native: build-lite-native

build-lite-armhf-native: ARCH=armhf
build-lite-armhf-native: build-lite-native

build-lite-arm64-toolchain:
	mkdir -p build-arm64
	cd build-arm64; \
	ARMCC_PREFIX=../toolchains/gcc-arm-8.3-2019.03-x86_64-aarch64-linux-gnu/bin/aarch64-linux-gnu- \
	ARMCC_FLAGS="-funsafe-math-optimizations" \
	cmake -DCMAKE_C_COMPILER=${ARMCC_PREFIX}gcc \
		    -DCMAKE_CXX_COMPILER=${ARMCC_PREFIX}g++ \
			  -DCMAKE_C_FLAGS="${ARMCC_FLAGS}" \
				-DCMAKE_CXX_FLAGS="${ARMCC_FLAGS}" \
				-DCMAKE_VERBOSE_MAKEFILE:BOOL=ON \
				-DCMAKE_SYSTEM_NAME=Linux \
				-DCMAKE_SYSTEM_PROCESSOR=aarch64 \
				../${TF_FILENAME}/tensorflow/lite/c; make

build-lite-armhf-toolchain:
	mkdir -p build-armhf
	cd build-armhf
	ARMCC_FLAGS="-march=armv7-a -mfpu=neon-vfpv4 -funsafe-math-optimizations"
	ARMCC_PREFIX=../toolchains/gcc-arm-8.3-2019.03-x86_64-arm-linux-gnueabihf/bin/arm-linux-gnueabihf-
	cmake -DCMAKE_C_COMPILER=${ARMCC_PREFIX}gcc \
   		  -DCMAKE_CXX_COMPILER=${ARMCC_PREFIX}g++ \
			  -DCMAKE_C_FLAGS="${ARMCC_FLAGS}" \
				-DCMAKE_CXX_FLAGS="${ARMCC_FLAGS}" \
				-DCMAKE_VERBOSE_MAKEFILE:BOOL=ON \
				-DCMAKE_SYSTEM_NAME=Linux \
				-DCMAKE_SYSTEM_PROCESSOR=armv7 \
				../${TF_FILENAME}/tensorflow/lite/c; make

release-lite:
	rm -rf release
	mkdir -p release/usr/local/lib
	cp build-${ARCH}/libtensorflowlite_c.so release/usr/local/lib/
	mkdir -p release/usr/local/include/tensorflow/lite/c
	cp ${TF_FILENAME}/tensorflow/lite/*.h release/usr/local/include/tensorflow/lite/
	cp ${TF_FILENAME}/tensorflow/lite/c/*.h release/usr/local/include/tensorflow/lite/c/
	mkdir release/DEBIAN
	cp control.tmpl release/DEBIAN/control
	sed -i "s/version-replace-me/${TF_VERSION}/g" release/DEBIAN/control
	sed -i "s/arch-replace-me/${ARCH}/g" release/DEBIAN/control
	dpkg-deb --build release
	mv release.deb tensorflow_${ARCH}_${TF_VERSION}.deb

release-lite-armhf: ARCH=armhf
release-lite-armhf: release-lite

release-lite-arm64: ARCH=arm64
release-lite-arm64: release-lite

release-lite-amd64: ARCH=amd64
release-lite-amd64: release-lite
