#!/usr/bin/perl
# sendmail.pl - Send email from shell. Use your default editor for typing it or read from file.
# Copyright (C) 2010 Joachim "Joe" Stiegler <blablabla@trullowitsch.de>
# 
# This program is free software; you can redistribute it and/or modify it under the terms
# of the GNU General Public License as published by the Free Software Foundation; either
# version 3 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program;
# if not, see <http://www.gnu.org/licenses/>.

use warnings;
use strict;
use Net::SMTP;
use Getopt::Std;
use File::Temp;

our ($opt_r, $opt_t, $opt_f, $opt_s, $opt_h, $opt_H);

my $mailhost = 'mail.yourhost.de';

my $user = undef; 
my $from = undef;
my $subject = "";
my @text = undef;
my $file = undef;
my $tmpfile = "";

sub usage {
	print "usage: $0 -r rcpt [-t textfile] [-f from] [-s subject] [-H mailhost]\n";
	exit(1);
}

if ( (!getopts("r:t:f:s:hH:")) or (defined($opt_h)) or (!defined($opt_r)) ) {
	usage();
}

if (defined($opt_t)) {
	$file = $opt_t;
}
else {
	$tmpfile = File::Temp->new(UNLINK => 0); # otherwise $tmpfile is unlinked after $EDITOR. Don't know why :-)
	$file = $tmpfile->filename;
	
	die "EDITOR not set\n" if ($ENV{'EDITOR'} eq "");

	system($ENV{'EDITOR'}, $file) == 0 || die "$file not accessible!\n";
}

if (defined($opt_f)) {
	$user = $opt_f;
	
	# The following will only work properly with adresses like james.hacker@gnu.org
	($from, my $waste) = split('@', $user);
	$from =~ s/\.|-|_/\ /g;
	my ($pname, $aname) = split(' ', $from);
	$from = ucfirst($pname)." ".ucfirst($aname);
}
else {
	$user = $ENV{USER};
}

if (defined($opt_s)) {
	$subject = $opt_s;
}

open(FILE, '<', $file) or die "$file: $!\n";
while(<FILE>) {
	push @text, $_;
}
close(FILE);

if (!defined($opt_t)) {
	unlink($tmpfile);
}

$mailhost = $opt_H if (defined($opt_H));

my $smtp = Net::SMTP->new($mailhost, Hello => '');

$smtp->mail($user);
$smtp->to($opt_r);

$smtp->data();

$smtp->datasend("To: $opt_r\n");
$smtp->datasend("From: $from\n") if ($from);
$smtp->datasend("Subject: $subject\n");
$smtp->datasend("\n");

foreach my $line (@text) {
	$smtp->datasend($line);
}

$smtp->dataend();

$smtp->quit;
