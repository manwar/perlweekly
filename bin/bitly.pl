use strict;
use warnings;
use autodie;
use 5.010;

use JSON       qw(from_json to_json);
use Path::Tiny qw(path);
use WWW::Shorten::Bitly;
use Data::Dumper qw(Dumper);
use Encode       qw(decode encode);

my $bitly_file = '/home/gabor/.bitly';
open my $fh, '<', $bitly_file;
chomp( my $line = <$fh> );
close $fh;
my ( $user, $apikey ) = split /:/, $line;

my $json_file = shift or die "Usage: $0 src/ddd.json\n";

#binmode(STDOUT, ":encoding(UTF-8)");
#binmode(STDERR, ":encoding(UTF-8)");

my $src_json = encode( 'utf-8', scalar path($json_file)->slurp_utf8 );
my $data     = from_json $src_json, { utf8 => 1 };

for my $ch ( @{ $data->{chapters} } ) {
	for my $e ( @{ $ch->{entries} } ) {
		$e->{text} //= '';
		my (@urls) = $e->{text} =~ m{<a href=(https?://[^>]*)>}g;
		push @urls, $e->{text} =~ m{<a href="(https?://[^>]*)">}g;

		#warn Dumper \@urls;
		foreach my $url (@urls) {
			if ( not $e->{map}{$url} ) {
				my $bitly = WWW::Shorten::Bitly->new(
					URL    => $url,
					USER   => $user,
					APIKEY => $apikey
				);
				$e->{map}{$url} = $bitly->shorten( URL => $url );
			}
		}

		#warn Dumper $e->{map};

		next if $e->{link};
		next if not $e->{url};
		say $e->{url};

	 #$e->{url} .= "&utm_medium=email&utm_campaign=PerlWeekly_$self->{issue}";
		my $bitly = WWW::Shorten::Bitly->new(
			URL    => $e->{url},
			USER   => $user,
			APIKEY => $apikey
		);
		$e->{link} = $bitly->shorten( URL => $e->{url} );
		say $e->{link};
	}
}

path($json_file)->spew_utf8(
	decode(
		'utf-8', to_json( $data, { utf8 => 1, pretty => 1, canonical => 1 } )
	)
);
