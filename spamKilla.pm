package spamKilla;

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

sub read_mail {
  my ($this, $mail) = @_;
  open my $mf, '<', $mail;
  while(<$mf>){
    $this->_eval_urls($_);
    $this->_eval_subject($_);
    $this->_eval_capslock($_);
    $this->_eval_blacklist($_);
    $this->_eval_keywords($_);
  }
  close $mf;
}

sub get_result {
  my ($this) = @_;
  my $points = $this->{keyword_points};
  $points += $this->{url_count}*$this->{url_points};
  $points += $this->{blacklisted_sender}*$this->{blacklist_points};
  $points += $this->{caps_count}*$this->{caps_points}/$this->{word_count};
  $points += $this->{empty_subject}*$this->{empty_subject_points};

  if($points > $this->{threshold}){
    print "This mail was considered spam!, Score: $points/$this->{threshold}\n";
  }
}

sub _init {
  my ($this, $config) = @_;
  $this->_init_vars();
  open my $cf, '<', $config;
  while (<$cf>){
    next if (/^\s*(#.*)?$/);
    if (/^\s*(\S+)\s*=>\s*(\S+)\s*$/){
      my $param = lc($1);
      if (!_is_valid_param($param)){
        die "Invalid parameter in configuration file: $param in $config.";
      }
      $this->{$param} = $2;
    }
  }
  close $cf;
  $this->_populate_blacklist();
  $this->_populate_keywords();
}

sub _init_vars {
  my($this) = @_;
  foreach(qw(
      keyword_points
      url_count
      word_count
      caps_count
      empty_subject
      blacklisted_sender
    )){
    $this->{$_} = 0;
  }
  $this->{keywords_regex} = "";
  $this->{blacklist} = [];
  $this->{keywords_hash} = {};
}

sub _is_valid_param {
  my ($param) = @_;
  return grep /^$param$/,
  qw(
    threshold
    blacklist_file
    blacklist_points
    keywords_file
    caps_sensitivity
    caps_points
    url_points
    empty_subject_points
  );
}

sub _populate_blacklist {
  my($this) = @_;
  open my $bl, '<', $this->{blacklist_file};
  while (<$bl>){
    next if (/^\s*(#.*)?$/);
    push @{$this->{blacklist}}, $1 if ( /^\s*(\S+)\s*/);
  }
  close $bl;
}

sub _populate_keywords {
  my ($this) = @_;
  open my $kf, '<', $this->{keywords_file};
  while (<$kf>){
    next if (/^\s*(#.*)?$/);
    $this->{keywords_hash}->{lc($1)} = $2 if (/^\s*(\w+)\s*(\d+)\s*$/);
  }
  close $kf;
  $this->{keywords_regex} = join ("|", keys %{$this->{keywords_hash}});
}

#count keyword value
sub _eval_keywords {
  my ($this, $line) = @_;
  while($line =~ /($this->{keywords_regex})/gi){
    $this->{keyword_points} += $this->{keywords_hash}{lc($1)};
  }
}

#count total words and total capslocked words
sub _eval_capslock {
  my ($this, $line) = @_;
  $this->{word_count} += scalar (() = $line =~ /\w+/g);
  $this->{caps_count} += scalar (() = $line =~
    /\b(?=.*[A-Z])[A-Z0-9_]{$this->{caps_sensitivity},}\b/g);
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
  if ($line =~ /^from:.*<(.+)>.*/i) {
    $this->{blacklisted_sender} = 1 if grep ($_ eq $1, @{$this->{blacklist}});
  }
  return;
}

#check if empty subject
sub _eval_subject {
  my ($this, $line) = @_;
  $this->{empty_subject} = 1 if (!$this->{empty_subject} && $line =~/^subject:(?:(?:re|fwd):?\s*)*\s*$/i);
}

#sum points from rules
sub _sum_points {
  my ($this, $line) = @_;
  $this->{points} += $this->{blacklisted_sender}*$this->{blacklist_points};
}
