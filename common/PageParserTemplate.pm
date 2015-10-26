#!/usr/bin/perl
use strict;
use warnings;
require Exporter;
#package task::myproj::PageParser;

our @ISA = qw(Exporter);
#@EXPORT_OK = qw(munge frobnicate);  # symbols to export on request
our @EXPORT = qw(get_parser_map);  # symbols to export on request

sub parse_url1{
	my ($pq) = @_;
	my %result = ();
	return \%result;
}

# only export this function
sub get_parser_map{
	return {
		"/url1" => \&parse_url1
	};
}

1;
