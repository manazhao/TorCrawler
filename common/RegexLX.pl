#!/usr/bin/perl
# extract links from  downloaded html files
# rules should be provided in a file named link.regex
# the urls are read from stdin

use strict;
use warnings;
use Getopt::Long;
use Digest::MD5	 qw(md5_hex);
use HTML::LinkExtractor;
use Data::Dumper;

my $pageDir = ".";
my $regexFile = "lx.rules";

GetOptions("page-dir=s" => \$pageDir,"lx-rules=s" => \$regexFile) or die $!;

if(! -f $regexFile){
	print STDERR "[ERR]: link extraction rule file is not present, exit now";
	exit;
}

my %ruleMap = ();
if(!open FILE, "<", $regexFile){
	die "[ERR]: failed to open the extraction rule file\n";
}
while(<FILE>){
	chomp;
	my($inRegex, @outRegex) = split /\s+/;
	$ruleMap{$inRegex} = \@outRegex;
}
close FILE;

chdir $pageDir;

print STDERR Dumper(\%ruleMap);
while(<>){
	chomp;
	my $url = $_;
	my $md5file = md5_hex($url) . ".htm";
	my @inRules = grep {my $pat=$_; my $re = qr /$pat/; $url =~ $pat} keys %ruleMap;
	# print Dumper(\@inRules);
	# find all links and filter using the @rules
	if((open HTML_FILE, "<", $md5file) and (@inRules) > 0){
		my $lx = new HTML::LinkExtractor(undef,$url);
		my $html = join("",<HTML_FILE>);
		$lx->parse(\$html);
		my $outRules = $ruleMap{$inRules[0]};
		foreach my $link(@{$lx->links}){
			# go through the pattern
			exists $link->{href} or next;
			my $href = $link->{href};
#			print $href . "\n";
			if((scalar grep {$href =~ $_} @{$outRules}) > 0){
				# a good link, add base and output
				# remove everything after hashtag
				$href =~ s/\#.*$//g;
				print join("\t",($href, "DL_NEW")) . "\n";			
			}
		}
		print join("\t",($url,"DL_EXTRACTED"))  . "\n";
	}else{
			print STDERR "[ERROR]: failed to open downloaded file: $url\n";			
	}
}
