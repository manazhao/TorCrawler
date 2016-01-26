#!/usr/bin/perl
# parsing a list of url provided through standard input
# the project specific parser module name should be presented through argument

use strict;
use warnings;
use Getopt::Long;
use Module::Load;
use FindBin;
use Data::Dumper;
use pQuery;
use JSON qw(encode_json decode_json);
use Digest::MD5 qw(md5_hex);
use lib "$FindBin::Bin/../";


# work dir specifices folder for saving the parsing results (json files)
my $workDir = ".";
my $parseModule;

GetOptions("work-dir=s"=>\$workDir,"parser-mod=s" => \$parseModule) or die $!;

-d $workDir or die "work directory is not present: $workDir";
$parseModule or usage();

# load the module and import the function get_parser_map
load $parseModule, qw(get_parser_map);
# autoload $parseModule;

# get_parser_map is defined the provided module
my $regexParserMap = get_parser_map();
#print Dumper($regexParserMap);

chdir $workDir;
-d "parse" or mkdir "parse";

while(<>){
	chomp;
	my $url = $_;
	my $md5 = md5_hex($url);
	my $md5File = "page/" .$md5. ".htm";
	my $jsonFile = "parse/$md5.json";
	-f $jsonFile and (print join("\t",($url,"PS_OK")) . "\n" and next);
	if(-f $md5File){
		while(my($key,$func) = each %$regexParserMap){
			my $pat = qr /${key}/;
			if($url =~ $pat){
				# read in the file and parsed it!
				open HTML_FILE, "<$md5File" or (warn $! and next);
				my $content = join("",<HTML_FILE>);
				# my $pQuery = pQuery($content);
				my $result = &$func($url, $md5, $content);
				# print Dumper $result;
				# save the result to file
				my $jsonFile = "parse/$md5.json";
				open JSON_FILE,">$jsonFile" or (warn $! and next);
				print JSON_FILE encode_json($result) . "\n";
				close JSON_FILE;
				# update the url status
				print  join("\t",($url,"PS_OK")) . "\n";
				last;
			}
		}
	}else{
		print STDERR "[WARN]: file does not exist for $url\n";
	}	
}


sub usage{
	my $usage = <<EOF;
PageParser	parsing the html pagse crawled from a website
	--work-dir			working directory, default is current directory
	--parse-mod			name of the parser module, required
EOF
	die $usage;
}
