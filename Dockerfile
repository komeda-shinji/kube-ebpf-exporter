FROM centos:7.6.1810
MAINTAINER huaizongfujian@gmail.com
RUN yum install -y epel-release kernel kernel-devel
RUN yum install -y golang
RUN yum groupinstall -y "Development tools"
RUN yum install -y centos-release-scl
RUN yum-config-manager --enable rhel-server-rhscl-7-rpms
RUN yum install -y wget libxml2-devel python2-devel elfutils-libelf-devel elfutils-libelf-devel-static cmake cmake3 git bison flex ncurses-devel
RUN mv /usr/bin/cmake /usr/bin/cmake2 && ln -s cmake3 /usr/bin/cmake
RUN yum install -y devtoolset-7 llvm-toolset-7 llvm-toolset-7-llvm-devel llvm-toolset-7-llvm-static llvm-toolset-7-clang-devel llvm-toolset-7-cmake

RUN git clone https://github.com/iovisor/bcc.git
RUN sed -i '/^find_package(LibDebuginfod)/s/^/#/' /bcc/CMakeLists.txt
RUN sed -i '/^wget/s/^/#/' /bcc/scripts/build-release-rpm.sh
RUN sed -i '/^Source[12]:/d; /%setup -T -b 1 -n llvm-%{llvmver}.src/,/tar -xvvJf /d; /^export LD_LIBRARY_PATH=/s/"$/:${LD_LIBRARY_PATH}&/; /^# build llvm/,/^$/d' /bcc/SPECS/bcc+clang.spec 

RUN source scl_source enable devtoolset-7 llvm-toolset-7 && \
    export LLVM_DIR="/opt/rh/llvm-toolset-7/root" && \
    export CMAKE_PREFIX_PATH="$LLVM_DIR" \
           CFLAGS="-I$LLVM_DIR/usr/include" \
           CXXFLAGS="-I$LLVM_DIR/usr/include" \
           LDFLAGS="-L$LLVM_DIR/usr/lib64 -Wl,-rpath,$LLVM_DIR/lib64" && \
    printenv && \
    cd /bcc && bash /bcc/scripts/build-release-rpm.sh
RUN cd /bcc && rpm -iv libbcc-*.x86_64.rpm

COPY ./ /go/ebpf-exporter

RUN cd /go/ebpf-exporter && GOPATH="" GOPROXY="off" GOFLAGS="-mod=vendor" CGO_LDFLAGS="-L/opt/rh/llvm-toolset-7/root/lib64 -Wl,-rpath,/opt/rh/llvm-toolset-7/root/lib64" go install -v ./...
