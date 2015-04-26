#!/usr/bin/env perl

use strict;
use diagnostics;
use warnings;
use autodie;
use Data::Dumper;
use feature "say";


#hash containing important stuff
my %config = (
  config_file => undef,
  blacklist_file => undef,
  keywords_file => undef,
  points_threshold => undef,
  keywords_regex => undef,
  blacklist => [],
  keywords_points => { }
);

#open my $fh, '<', $config{'config_file'} or die "Cannot open ‘$config{'config_file'}’ for reading: $!";
#close $fh or die "Cannot close $config{'config_file'}: $!";


#parse ARGV
#initialize_configs
#populate regexes
#iterate file
#respond

initialize();
print Dumper(\%config);

sub initialize {
  initialize_configs();
  populate_keywords();
  populate_blacklist();
}

sub initialize_configs {
  while( my $config_line = <DATA>){
    if($config_line =~ /^\s*#.*$/) { next; }
    if ($config_line =~ /(\S+)\s*=>\s*(\S+)/){
      $config{lc($1)} = $2;
    }
  }
}

sub populate_keywords {
  open my $keyword_handle, '<', $config{keywords_file};
  while (<$keyword_handle>) {
    next if (/^\s*#/);
    my ($keyword, $value) = extract_keyword_points($_);
    $config{keywords_points}->{$keyword} = $value;
  }
  close $keyword_handle;
  $config{keywords_regex} = join '|', keys $config{keywords_points};
}


sub populate_blacklist {
  open my $blacklist_handle, '<', $config{blacklist_file};
  while(<$blacklist_handle>) {
    next if /^\s*#/;
    if ( /^\s*(\S+)\s*/) {
      push $config{blacklist}, lc($1);
    }
  }
  close $blacklist_handle;
}

sub extract_keyword_points {
  my ($line) = shift;
  my ($keyword, $value) = ("", 0);
  if($line =~ /^(\w+)\s+(\d+[,\.]?\d*)\s*$/){
    ($keyword, $value) = ($1, $2);
    $value =~ s/,/./;
    $keyword = lc $keyword;
  }
  return ($keyword , $value);
}

sub keywords_points {
  my $line = shift;
  my $points = 0;
  foreach ($line =~ m/$config{keywords_regex}/gi) {
    $points += $config{keywords_points}{lc($_)};
  }
  return $points;
}

sub find_sender {
  my ($line) = @_;
  if ($line =~ /^from:.*<(.*@.*)>$/gi) {
    return $1;
  }
  return;
}


__DATA__
#formatted as key => value pairs
keywords_file => keywords.cfg
blacklist_file => blacklist.cfg
points_threshold => 1000
caps_length_threshold => 3
caps_points => 20
