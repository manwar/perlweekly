package PerlWeekly;
use strict;
use warnings;

use Data::Dumper qw(Dumper);
use Exporter     qw(import);
use JSON         qw(from_json);
use Path::Tiny   qw(path);

our @EXPORT_OK = qw(get_authors);

sub get_authors {
	my $authors
		= eval { from_json scalar( path("src/authors.json")->slurp_utf8 ) };
	die "Could not read src/authors.json\n\n$@" if $@;
	foreach my $author ( keys %$authors ) {
		die
			"Name missing from author '$author' in the src/authors.json file\n"
			if not exists $authors->{$author}{name};
		$authors->{$author}{key} = $author;
		( $authors->{$author}{handler} = $author ) =~ s/_/-/g;
	}
	return $authors;
}

1;

