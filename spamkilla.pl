#!/usr/bin/env perl
use strict;
use warnings;
use diagnostics;
use spamKilla;

print "Using version: $spamKilla::VERSION\n";

print "Do you want to use an external config file?[config.cfg] ";
my $config = <STDIN>;
chomp ($config);
$config ||= "config.cfg";
print "Using $config";

my $spamkilla = spamKilla->new({config_file=>$config});

print "Enter with email to be read[mail.txt]: ";
my $email = <STDIN>;
chomp $email;

$email ||= "mail.txt";

$spamkilla->read_mail($email);

$spamkilla->get_result();
