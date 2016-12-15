#!/usr/bin/perl
use strict;
use Sys::CpuAffinity;
use Getopt::Long;

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
print "Number of CPUs: $num_cpus  Number of build threads: $num_build_threads \n";

my $hcc_repo_url = "https://github.com/RadeonOpenCompute/HCC-Native-GCN-ISA.git";
my $hcc_git_url = "https://github.com/RadeonOpenCompute/hcc.git";
my $hcc_branch = "clang_tot_upgrade";

my $use_repo = '';
my $build_device_libs = '';

my $build_type = "Release";
my $gpu_arch = "AMD:AMDGPU:8:0:3";
my $device_lib_dir = "/opt/rocm/lib";
my $hcc_build_dir = "build.hcc";

GetOptions ("repo" => \$use_repo
           ) or die ("Error in command line arguments\n");

my $command;
my $command_result;
# get the hcc source

if ($use_repo) {
  $command = "repo init -u $hcc_repo_url -b $hcc_branch";
  run_command($command);

  $command = "repo sync";
  run_command($command);
}
else {
  $command = "git clone --recursive -b $hcc_branch $hcc_git_url";
  run_command($command);

  run_command("mkdir $hcc_build_dir");

  chdir($hcc_build_dir);
  #run_command("cd $hcc_build_dir");

  $command = "cmake -DCMAKE_BUILD_TYPE=$build_type -DHSA_AMDGPU_GPU_TARGET=$gpu_arch -DROCM_DEVICE_LIB_DIR=$device_lib_dir ../hcc";
  run_command($command);

  run_command("make -j $num_build_threads");
  run_command("make package");

  exit;
}

