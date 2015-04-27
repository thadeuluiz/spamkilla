package SpamKilla;

use strict;
use warnings;
use diagnostics;
use autodie;

our $VERSION = 0.1;

#TODO rules to implement
#keyword matching
#capslocks
#blacklist sender
#too many urls
#blank subject

sub new {
  my ($class, $arg_for) = @_;
  my $this = bless {}, $class;
  $this->_init($arg_for->{config_file}, $arg_for->{blacklist_file});
  return $this;
}

sub _init {
  my ($this, $config, $blacklist) = @_;
  $this->{points} = 0;
  $this->{url_count} = 0;
  $this->{word_count} = 0;
  $this->{caps_count} = 0;
  $this->{empty_subject} = 0;
  $this->{keywords_regex} = "";
  $this->{blacklisted_sender} = 0;
  open my $cf, '<', $config;
  while (<$cf>){
    next if (/^\s*#/);
    foreach (/\s+(\w+)\s+(\d+[,\.]?\d*)\s*$/gi){
      $this->{keywords_regex} = $this->{keywords_regex}." ";
      $this->{keywords_regex} = $this->{keywords_regex}.$1;
      $this->{keywords_hash}->{lc($1)} = $2;
    }
    $this->{caps_sensitivity} = $1 if (/^caps\s*sensitivity:\s+(\d+)\s*$/i);
    $this->{caps_points} = $1 if (/^caps\s*points:\s+(\d+[,\.]?\d*)\s*$/i);
    $this->{points_threshold} = $1 if (/^points\s*threshold:\s+(\d+)\s*$/i);
  close $cf;
  open my $bl, '<', $blacklist;
  while (<$bl>){
    next if (/^\s*#/);
    push @$this->{blacklist}, lc($1) if ( /^\s*(\S+)\s*/);
  }
  close $bl;
}

#count keyword value
sub _eval_keywords {
  my ($this, $line) = @_;
  foreach($line =~ m/$this->{keywords_regex}/i){
    $this->{points} += $this->{keywords_hash}->{lc($_)};
  }
}

#count total words and total capslocked words
sub _eval_capslock {
  my ($this, $line) = @_;
  $this->{word_count} += scalar (() = $line =~ /\w+/g);
  $this->{caps_count} += scalar (() = $line =~
    /\b(?=.*[A-Z])[A-Z0-9_]{$this->{caps_sensitivity}, }\b/g);
  #check for entirely caps words with at least n letters and a capslocked letter
}

#check for https, sshs and ftps
sub _eval_urls {
  my ($this, $line) = @_;
  $this->{url_count}++ if $line =~ /(?:http[s]?|[s]?ftp|ssh):\/\//i;
}

#check if sender is blacklisted
sub _eval_blacklist {
  my ($this, $line) = @_;
  return if $this->{blacklisted_sender};
  if ($line =~ /^from:.*<(.+)>.*/) {
    $this->{blacklisted_sender} = 1 if grep ($_ == $1, @$this->{blacklist});
  }
  return;
}

#check if empty subject
sub _eval_subject {
  my ($this, $line) = @_;
  if (!$this->{empty_subject} && $line =~/^subject:(?:(?:re|fwd):?\s*)+(.*)$/i){
    if (!$1) {
      $this->{empty_subject} = 1;
    }
  }
}
