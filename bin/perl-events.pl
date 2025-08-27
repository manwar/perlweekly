#!/usr/bin/perl
use strict;
use warnings;
use 5.010;

# Checking the list of events in https://github.com/yapceurope/perl-events
# and comparing to my own list
#
# Needs git clone https://github.com/yapceurope/perl-events.git in a directory
# next to the perlweekly working directory

use YAML;
use JSON            qw(from_json);
use Path::Tiny      qw(path);
use Data::Dumper    qw(Dumper);
use Cwd             qw(abs_path cwd);
use File::Basename  qw(dirname);
use List::MoreUtils qw(any);

my $cwd = cwd;

my $file = dirname( dirname( dirname( abs_path($0) ) ) )
	. '/perl-events/conferences.yml';
chdir dirname $file;
system 'git pull';
chdir $cwd;

my ( $current_day, $current_month, $current_year ) = (gmtime)[ 3, 4, 5 ];
$current_day++;
$current_month++;
$current_year += 1900;

my $yef       = YAML::LoadFile($file);
my $pw_events = from_json scalar path("src/events.json")->slurp_utf8;
my @out;
print "----------------------------------\n";
print "From YEF site:\n";
print "----------------------------------\n";
foreach my $e (@$yef) {
	my ( $day, $month, $year )
		= $e->{begin} =~ /(\d\d|xx).(\d\d|xx).(\d\d\d\d)$/;
	next if $current_year > $year;
	if ( $current_year == $year and $month ne 'xx' ) {
		next if $month < $current_month;
		next if $month == $current_month and $day < $current_day;
	}
	$e->{url} //= '';

	#say $_->{url} for @{ $pw_events->{entries} };
	my $found  = any { $e->{url} eq $_->{url} } @{ $pw_events->{entries} };
	my $prefix = $found ? 'OK        ' : 'Missing:  ';
	if ( not $e->{url} ) {
		$prefix = 'NO URL:   ';
	}
	push @out, sprintf "$prefix$year - $month - $day - %-30s %s\n",
		$e->{name}, $e->{url};
}
print sort @out;
@out = map { sprintf "NO URL:    %-30s\n", $_->{title} }
	grep { $_->{url} eq '' } @{ $pw_events->{entries} };
if (@out) {
	print "----------------------------------\n";
	print "Form Perl Weekly\n";
	print "----------------------------------\n";
	print @out;
}

