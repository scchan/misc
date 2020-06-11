#!/usr/bin/perl
use strict;
use Cwd qw(cwd);
use File::pushd;
use File::Which;
use Getopt::Long;
use IPC::System::Simple qw(system);
use String::Util qw(trim);

# run_command(command, working_dir, dry_run)
sub run_command {
    my ($command
        , $working_dir
        , $dry_run) = @_;
    if ($dry_run) {
        print("$command \n");
    } else {
        my $dir;
        if ($working_dir) {
            $dir = pushd($working_dir);
        }
        system($command);
    }
}

my $dry_run = 0;
my $lsb_release = which "lsb_release";

# common cmake configs
my $cmake_path = "/usr/bin/cmake";
my $cmake_generator = "Ninja";
my $cmake_build_type = "Release";
my $cpack_generator = "";
my $package_contact = "AMD";
my $cmake_command = "";
my $cmake_command_return = "";

my $current_path = cwd;
my $rocm_path = "/opt/rocm";

my $components_to_build = "llvm";

# AMD llvm package
my $llvm_package_name = "llvm-amdgpu";
my $llvm_targets = "AMDGPU;X86";
my $llvm_projects = "clang;lld;clang-tools-extra;compiler-rt;openmp";
my $llvm_install_path = "$rocm_path/llvm";
my $llvm_source_path = "$current_path/llvm-project";
my $llvm_build_path = "";

# ROCm device libs
my $rocdl_install_path = "$rocm_path";
my $rocdl_source_path = "$current_path/ROCm-Device-Libs";
my $rocdl_build_path = "";

GetOptions ("build=s" => \$cmake_build_type
            ,"components=s" => \$components_to_build
            ,"dry_run" => \$dry_run
            ,"gen=s" => \$cmake_generator
            ,"llvm_source=s" => \$llvm_source_path
            ,"llvm_build=s" => \$llvm_build_path
            ,"rocdl_source=s" => \$rocdl_source_path
            ,"rocdl_build=s" => \$rocdl_build_path
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
    $cmake_command .= " -DCPACK_GENERATOR=$cpack_generator";
}


# LLVM specific
if ($components_to_build eq "llvm") {

    $cmake_command .= " -DCPACK_PACKAGE_NAME=$llvm_package_name";
    $cmake_command .= " -DCMAKE_INSTALL_PREFIX=$llvm_install_path -DCPACK_PACKAGE_INSTALL_PREFIX=$llvm_install_path";
    $cmake_command .= " -DLLVM_TARGETS_TO_BUILD=\"$llvm_targets\"";
    $cmake_command .= " -DLLVM_ENABLE_PROJECTS=\"$llvm_projects\"";

    $cmake_command .= " $llvm_source_path/llvm";

    if ($llvm_build_path eq "") {
        $llvm_build_path = $current_path."/build.".$llvm_package_name.".".$cmake_build_type;
    }
    if (not (-d $llvm_build_path)) {
        mkdir($llvm_build_path) or die "Unable to create $llvm_build_path";
    }

    run_command($cmake_command, $llvm_build_path, $dry_run);
}

# ROCDL specific
if ($components_to_build eq "rocdl") {

    # add search path for clang
    my $cmake_prefix_path = "/opt/rocm/llvm";
    if ($llvm_build_path) {
        $cmake_prefix_path = $llvm_build_path; 
    }
    $cmake_command .= " -DCMAKE_PREFIX_PATH=$cmake_prefix_path";

    $cmake_command .= " -DCMAKE_INSTALL_PREFIX=$rocdl_install_path";
    $cmake_command .= " -DCPACK_PACKAGING_INSTALL_PREFIX=$rocdl_install_path";

    $cmake_command .= " $rocdl_source_path";

    if ($rocdl_build_path eq "") {
        $rocdl_build_path = "$current_path/build.rocdl.$cmake_build_type";
    }
    if (not (-d $rocdl_build_path)) {
        mkdir($rocdl_build_path) or die "Unable to create $rocdl_build_path";
    }

    run_command($cmake_command, $rocdl_build_path, $dry_run);
}
# cmake -DCMAKE_BUILD_TYPE="Release" -DCMAKE_PREFIX_PATH=$LLVM_BUILD -DCMAKE_INSTALL_PREFIX=/opt/rocm/bitcode -DCPACK_PACKAGING_INSTALL_PREFIX=/opt/rocm/bitcode -DCPACK_GENERATOR=DEB  -DCPACK_PACKAGE_CONTACT=AMD   ../ROCm-Device-Libs/