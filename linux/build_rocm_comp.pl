#!/usr/bin/perl
use strict;
use Cwd qw(cwd);
use File::pushd;
use File::Which;
use Getopt::Long;
use IPC::System::Simple qw(system);
use String::Trim;

# run_cmake_command(command, build_dir, dry_run)
sub run_cmake_command {
    my ($command
        , $build_dir
        , $dry_run) = @_;

    $command = qq{$command};
    if ($dry_run) {
        print("$command \n");
    } else {
        my $dir;
        if ($build_dir) {
            if (not (-d $build_dir)) {
                mkdir($build_dir) or die "Unable to create $build_dir";
            }
            $dir = pushd($build_dir);
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

# comgr
my $comgr_install_path = "$rocm_path";
my $comgr_source_path = "$current_path/support/lib/comgr";
my $comgr_build_path = "";

# ROCclr
my $rocclr_repo_name = "ROCclr";
my $rocclr_install_path = "$rocm_path/rocclr";
my $rocclr_source_path = "$current_path/$rocclr_repo_name";
my $rocclr_build_path = "";
my $opencl_source_path = "$current_path/opencl";

# HIP
my $hip_repo_name = "HIP";
my $hip_install_path = "";
my $hip_source_path = "$current_path/$hip_repo_name";
my $hip_build_path = "";

GetOptions ("build=s" => \$cmake_build_type
            ,"components=s" => \$components_to_build
            ,"dry_run" => \$dry_run
            ,"gen=s" => \$cmake_generator
            ,"llvm_source=s" => \$llvm_source_path
            ,"llvm_build=s" => \$llvm_build_path
            ,"rocdl_source=s" => \$rocdl_source_path
            ,"rocdl_build=s" => \$rocdl_build_path
            ,"comgr_source=s" => \$comgr_source_path
            ,"comgr_build_path=s" => \$comgr_build_path
            ,"rocclr_source=s" => \$rocclr_source_path
            ,"rocclr_build_path=s" => \$rocclr_build_path
            ,"opencl_source=s" => \$opencl_source_path
            ,""
            );


$cmake_command = "$cmake_path -DCMAKE_BUILD_TYPE=$cmake_build_type";
if ($components_to_build ne "hip") {
    $cmake_command .= " -G $cmake_generator";
}
$cmake_command .= " -DCPACK_PACKAGE_CONTACT=$package_contact "; 

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
if ($llvm_build_path eq "") {
    $llvm_build_path = $current_path."/build.".$llvm_package_name.".".$cmake_build_type;
}
if ($components_to_build eq "llvm") {

    $cmake_command .= " -DCPACK_PACKAGE_NAME=$llvm_package_name";
    $cmake_command .= " -DCMAKE_INSTALL_PREFIX=$llvm_install_path -DCPACK_PACKAGING_INSTALL_PREFIX=$llvm_install_path";
    $cmake_command .= " -DLLVM_TARGETS_TO_BUILD=\"$llvm_targets\"";
    $cmake_command .= " -DLLVM_ENABLE_PROJECTS=\"$llvm_projects\"";
    $cmake_command .= " $llvm_source_path/llvm";

    run_cmake_command($cmake_command, $llvm_build_path, $dry_run);
}

# ROCDL specific
if ($rocdl_build_path eq "") {
    $rocdl_build_path = "$current_path/build.rocdl.$cmake_build_type";
}
if ($components_to_build eq "rocdl") {

    # add search path for clang
    my $clang_search_path = "/opt/rocm/llvm";
    if (-d $llvm_build_path) {
        $clang_search_path = "$llvm_build_path\;$clang_search_path"; 
    }
    $cmake_command .= " -DCMAKE_PREFIX_PATH=\"$clang_search_path\"";
    $cmake_command .= " -DCMAKE_INSTALL_PREFIX=$rocdl_install_path";
    $cmake_command .= " -DCPACK_PACKAGING_INSTALL_PREFIX=$rocdl_install_path";
    $cmake_command .= " $rocdl_source_path";

    run_cmake_command($cmake_command, $rocdl_build_path, $dry_run);
}

# comgr specific
if ($comgr_build_path eq "") {
    $comgr_build_path = "$current_path/build.comgr.$cmake_build_type";
}
if ($components_to_build eq "comgr") {
    $cmake_command .= " -DCMAKE_PREFIX_PATH=\"$llvm_build_path\;$rocdl_build_path\"";
    $cmake_command .= " -DCMAKE_INSTALL_PREFIX=$comgr_install_path";
    $cmake_command .= " -DCPACK_PACKAGING_INSTALL_PREFIX=$comgr_install_path";
    $cmake_command .= " $comgr_source_path";
    
    run_cmake_command($cmake_command, $comgr_build_path, $dry_run);
}

# ROCclr specific
if ($rocclr_build_path eq "") {
    $rocclr_build_path = "$current_path/build.$rocclr_repo_name.$cmake_build_type";
}
if ($components_to_build eq "rocclr") {

    $cmake_command .= " -DOPENCL_DIR=$opencl_source_path -DCMAKE_INSTALL_PREFIX=$rocclr_install_path";
    $cmake_command .= " $rocclr_source_path";
    run_cmake_command($cmake_command, $rocclr_build_path, $dry_run);
}

# HIP
# sudo cmake -DCMAKE_BUILD_TYPE=Release  -DHIP_COMPILER=clang -DHIP_PLATFORM=rocclr -DCMAKE_PREFIX_PATH=/home/scchan/code/build.rocclr/ -DROCM_PATH=/opt/rocm -DCMAKE_BUILD_WITH_INSTALL_RPATH=TRUE -DCMAKE_SKIP_BUILD_RPATH=TRUE  ../HIP/

if ($components_to_build eq "hip") {

    $cmake_command .= " -DHIP_COMPILER=clang -DHIP_PLATFORM=rocclr";
    $cmake_command .= " -DCMAKE_PREFIX_PATH=$rocclr_build_path";
    $cmake_command .= " -DROCclr_DIR=$rocclr_source_path";
    $cmake_command .= " -DROCM_PATH=$rocm_path";
    $cmake_command .= " -DCMAKE_BUILD_WITH_INSTALL_RPATH=TRUE -DCMAKE_SKIP_BUILD_RPATH=TRUE";
    $cmake_command .= " $hip_source_path";
    if ($hip_build_path eq "") {
        $hip_build_path = "$current_path/build.$hip_repo_name.$cmake_build_type";
    }
    run_cmake_command($cmake_command, $hip_build_path, $dry_run);
}
    
