#!/usr/bin/perl
use strict;
use File::Which;
use Getopt::Long;
use String::Util qw(trim);

my $lsb_release = which "lsb_release";

# common cmake configs
my $cmake_path = "/usr/bin/cmake";
my $cmake_generator = "Ninja";
my $cmake_build_type = "Release";
my $cpack_generator = "";
my $package_contact = "AMD";
my $cmake_command = "";

my $rocm_path = "/opt/rocm";

# AMD llvm package
my $llvm_package_name = "llvm-amdgpu";
my $llvm_targets = "AMDGPU;X86";
my $llvm_projects = "clang;lld;clang-tools-extra;compiler-rt;openmp";
my $llvm_install_path = "$rocm_path/llvm";

GetOptions ('gen' => \$cmake_generator
            ,'build' => \$cmake_build_type
            );


$cmake_command = "$cmake_path -DCMAKE_BUILD_TYPE=$cmake_build_type -G $cmake_generator  -DCPACK_PACKAGE_CONTACT=$package_contact "; 

# decide on the installer package format
if ($lsb_release) {
    my $distro = trim(lc(`$lsb_release -is`));
    print "distro: $distro \n";
    if ($distro eq "ubuntu") {
        $cpack_generator = "DEB";
    } elsif ($distro eq "fedora" 
             || $distro eq "centos"
             || $distro eq "redhatenterpriseserver"
             || $distro eq "opensuse"
             || $distro eq "suse"
             || $distro eq "sles") {
        $cpack_generator = "RPM";
    }
}
if ($cpack_generator) {
    $cmake_command .= " -DCPACK_GENERATOR=$cpack_generator"
}

# LLVM specific
$cmake_command .= " -DCPACK_PACKAGE_NAME=$llvm_package_name";
$cmake_command .= " -DCMAKE_INSTALL_PREFIX=$llvm_install_path -DCPACK_PACKAGE_INSTALL_PREFIX=$llvm_install_path";
$cmake_command .= " -DLLVM_TARGETS_TO_BUILD=$llvm_targets";
$cmake_command .= " -DLLVM_ENABLE_PROJECTS=$llvm_projects";

print "cmake command: $cmake_command \n";

# cmake -DCMAKE_BUILD_TYPE="Release" -DCMAKE_PREFIX_PATH=$LLVM_BUILD -DCMAKE_INSTALL_PREFIX=/opt/rocm/bitcode -DCPACK_PACKAGING_INSTALL_PREFIX=/opt/rocm/bitcode -DCPACK_GENERATOR=DEB  -DCPACK_PACKAGE_CONTACT=AMD   ../ROCm-Device-Libs/