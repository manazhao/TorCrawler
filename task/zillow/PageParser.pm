#!/usr/bin/perl
use strict;
use warnings;
use pQuery;
use Data::Dumper;
require Exporter;
package task::zillow::PageParser;

our @ISA = qw(Exporter);
#@EXPORT_OK = qw(munge frobnicate);  # symbols to export on request
our @EXPORT = qw(get_parser_map);  # symbols to export on request

sub trim{
	my ($s) = @_;
	$s =~ s/(^\s+)|(\s+$)//;
	return $s;
}

sub parse_home_details{
	my ($url, $md5, $content) = @_;
	my $zpid= ($url =~ /(\d+)\_zpid/ and $1);
	my %result = (
		url => $url,
		hash => $md5
	);
	if($zpid){
		$result{zpid} = $zpid;
	}

	# match by regular expression
	my $metaRegMap = {
		"address" => qr /og:zillow_fb:address"\s+content="([^"]*)"/,
		"num_beds" => qr /zillow_fb:beds"\s+content="([^"]*)"/,
		"num_baths" => qr /zillow_fb:baths"\s+content="([^"]*)"/,
		"title" => qr /og:title"\s+content="([^"]*)"/,
		"image" => qr /og:image"\s+content="([^"]*)"/,
		"description" => qr /og:description"\s+content="([^"]*)"/,
		"purpose" => qr /twitter:label1"\s+content="([^"]*)"/,
		"value" => qr /twitter:data1"\s+content="\$([\d\,]+)"/,
		"chart_jsonp" => qr /(https?:\/\/[^\/]+?\/hdp_chart\/render.json[^"]*?)"/
	};

	while(my($name,$pat) = each %$metaRegMap){
		if($content =~ $pat){
			# normalize the information
			my $value = lc $1;
			$result{$name} = $1;
		}
	}

	# construct pQuery
	my $pq = ::pQuery($content);
	$result{facts} = {};
	$pq->find(".hdp-facts li")->each(sub{
		my $liText = lc ::pQuery($_)->text();
		$liText =~ s/\s+/ /;
		# try to split by :
		my ($key,$rest) = split /:/, $liText;
		if($rest){
			$rest = trim($rest);
		} else{
			$rest = "";
		}
		$key = trim($key);
		$result{facts}->{$key} = $rest;
	});
	return \%result;
}

# only export this function
sub get_parser_map{
	return {
		"/homedetails" => \&parse_home_details
	}
}

1;