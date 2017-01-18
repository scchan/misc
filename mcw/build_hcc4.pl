#!/usr/bin/perl
use strict;
use Sys::CpuAffinity;
use Getopt::Long;

# requires module Syntax::Feature::Junction
use syntax 'junction';

my @supported_distros = ("ubuntu", "fedora");
my $hcc_build_dir = "build.hcc";

sub print_option {
  my ($option, $description) = @_;
  print "  $option \t\t\t $description \n";
}

sub usage {
  print "Options: \n\n";
  print_option("--help", "this help message");
  print_option("--stdlibcpp", "use libstdc++ for C++ runtime");
  print_option("--threads <int>", "specify the number of build threads, the default is 2X number of cores");
  print_option("--cloneonly", "clone the hcc source only, do not build the compiler");
  print_option("--buildonly", "build the compiler with existing source, do not clone or checkout the hcc source");
  print_option("--branch", "specify an HCC branch");
  my $distro_list = join(", ", @supported_distros); 
  print_option("--distro <name>", "specify the distro ($distro_list)");
  print_option("--package", "generate an installer package");
  print_option("--debug", "create a debug build of hcc");
  print_option("--builddir <dir>", "build directory (Default: $hcc_build_dir)");
  return 0;
}


sub print_command {
  my $separator = "##########################################################################\n";

  print "\n";
  print $separator;
  print "  ";
  print @_;
  print "\n";
  print $separator;
  print "\n";

}

sub run_command {
  my $command_result;
  my $command;

  $command = "@_";
  print_command($command);
  #$command_result = `$command`;
  system($command);
}

my $num_cpus = Sys::CpuAffinity::getNumCpus();
my $num_build_threads = $num_cpus * 2;

my $hcc_repo_url = "https://github.com/RadeonOpenCompute/HCC-Native-GCN-ISA.git";
my $hcc_git_https = "https://github.com/RadeonOpenCompute/hcc.git";
my $hcc_git_ssh = "git\@github.com:RadeonOpenCompute/hcc.git";
my $hcc_clang_git_ssh = "git\@github.com:RadeonOpenCompute/hcc-clang-upgrade.git";
my $hcc_llvm_git_ssh = "git\@github.com:RadeonOpenCompute/llvm.git";
my $hcc_lld_git_ssh = "git\@github.com:RadeonOpenCompute/lld.git";

my $use_stdlibcpp = '';

my $hcc_branch = "clang_tot_upgrade";

my $help = '';
my $use_repo = '';
my $build_device_libs = '';
my $clone_only = '';
my $build_only = '';
my $package = '';
my $debug_build = '';

my $distro = $supported_distros[0];

my $build_type = "Release";
my $gpu_arch = "AMD:AMDGPU:8:0:3";
my $device_lib_dir = "/opt/rocm/lib";
my $hcc_build_dir = "build.hcc";

GetOptions (
             "help" => \$help
            ,"stdlibcpp" => \$use_stdlibcpp 
#            , "repo" => \$use_repo
            ,"threads=i" => \$num_build_threads
            ,"cloneonly" => \$clone_only
            ,"buildonly" => \$build_only
            ,"branch=s" => \$hcc_branch
            ,"distro=s" => \$distro
            ,"package" => \$package
            ,"debug" => \$debug_build
            ,"builddir=s" => \$hcc_build_dir
           ) or (usage() and die ("Error in command line arguments\n"));

if ($help) {
  usage();
  exit(0);
}

# check the distro value against the list of supported distro
any(@supported_distros) eq $distro || die ("Unsupported distro: $distro\n");

if ($debug_build) {
  $build_type = "Debug";
}

# print the build info
print "HCC branch: $hcc_branch \n";
print "Distro: $distro\n";
print "C++ Runtime: ", ($use_stdlibcpp) ? "libstdc++" : "libc++", "\n";
print "cloneonly: ", ($clone_only) ? "true" : "false", "\n";
print "buildonly: ", ($build_only) ? "true" : "false", "\n";
print "build type: ", $build_type, "\n";
print "build directory: ", $hcc_build_dir, "\n";
print "package: " , ($package) ? "true" : "false", "\n";
print "Number of CPUs: $num_cpus  Number of build threads: $num_build_threads \n";

my $command;

if (!$build_only) {
  $command = "git clone --recursive -b $hcc_branch $hcc_git_https";
  run_command($command);

  # set SSH URL for git push
  chdir("hcc");
  $command = "git remote set-url --push origin $hcc_git_ssh";
  run_command($command);

  chdir("clang");
  $command = "git remote set-url --push origin $hcc_clang_git_ssh";
  run_command($command);

  chdir("../compiler");
  $command = "git remote set-url --push origin $hcc_llvm_git_ssh";
  run_command($command);

  chdir("../lld");
  $command = "git remote set-url --push origin $hcc_lld_git_ssh";
  run_command($command);
  chdir("../..");

  if ($clone_only) {
    exit;
  }
}


# create the build directory and start the build
run_command("mkdir $hcc_build_dir");
chdir($hcc_build_dir) || die ("Can't change to build directory $hcc_build_dir\n");
$command = "cmake -DCMAKE_BUILD_TYPE=$build_type -DHSA_AMDGPU_GPU_TARGET=$gpu_arch -DROCM_DEVICE_LIB_DIR=$device_lib_dir -DDISTRO=$distro ../hcc";

if ($use_stdlibcpp) {
  $command = "$command -DUSE_LIBCXX=OFF";
}
else {
  $command = "$command -DUSE_LIBCXX=ON";
}

run_command($command);

run_command("make -j $num_build_threads");

if ($package) {
  run_command("make package");
}

