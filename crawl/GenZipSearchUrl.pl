#!/usr/bin/perl
#
# generate zip code and its search url
# start with CA
#
use strict;
use warnings;

my $startZip = 90001;
my $endZip = 96162;

for(my $zip = $startZip; $zip <= $endZip; $zip++){
	# up to 5 pages per zip
	for(my $page = 1; $page <= 5; $page++){
		my $url = "http://www.zillow.com/homes/${zip}_rb/${page}_p/";
		print $url . "\n";
	}
}
