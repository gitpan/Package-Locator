
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "FindBin" => 0,
    "Module::Build" => "0.3601",
    "Test::Exception" => 0,
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Find the distribution that provides a given package",
  "dist_author" => [
    "Jeffrey Ryan Thalhammer <jeff\@imaginative-software.com>"
  ],
  "dist_name" => "Package-Locator",
  "dist_version" => "0.002",
  "license" => "perl",
  "module_name" => "Package::Locator",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "File::Temp" => 0,
    "LWP::UserAgent" => 0,
    "Moose" => 0,
    "MooseX::Types::Path::Class" => 0,
    "MooseX::Types::URI" => 0,
    "Parse::CPAN::Packages::Fast" => 0,
    "Path::Class" => 0,
    "URI" => 0,
    "URI::Escape" => 0,
    "namespace::autoclean" => 0,
    "perl" => "5.006",
    "version" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
