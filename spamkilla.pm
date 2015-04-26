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
  $this->_init($arg_for->{config_file});
  return $this;
}

sub _init {
  my ($this, $config) = @_;
  open my $cf, '<', $config;

  #TODO....

  close $cf;
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
  #check for entirely caps words with atleast n letters and a capslocked letter
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
