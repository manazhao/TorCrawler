#!/usr/bin/perl
# parse downloade html files and output the parsed information in json files
#

use strict;
use warnings;
use Getopt::Long;
use FindBin;

# setup the include path
use lib "$FindBin::Bin/../";
use JSON qw(encode_json decode_json);
use pQuery;
use Data::Dumper;
use Try::Tiny;
use Text::Balanced qw(extract_bracketed);
use Digest::MD5 qw(md5_hex);
use File::Basename;
use Cwd;


my $nJobs = 4;
my $workDir = ".";
my $parserMod;

GetOptions("work-dir=s" => \$workDir,"jobs=s" => \$nJobs, "parser-mod=s" => \$parserMod) or die $!;

-d $workDir or die $!;
$parserMod or die "parser module name is not present\n";

chdir $workDir;

# now go through the file
-f "url.status" or die "url.status file is not present";
print ">>> update url.status by merging with parsing reusults by previous round\n";
update_url_status();

# generate to parse file
print ">>> generate parse url list\n";
`grep -P "DL_OK|DL_EXTRACTED" url.status|cut -f1 > parse.in`;

# go through the list
my $urlCnt = `wc -l parse.in|cut -f1 -d' '`;
chomp $urlCnt;
print ">>> number of urls to parse: $urlCnt\n";
if($urlCnt == 0){
	print ">>> no more urls to parse\n";
	exit;
}

# now split into multiple jobs
my $taskCnt = $urlCnt;
if($urlCnt < $nJobs){
	$nJobs = $urlCnt;
}
my $splitSize = int($taskCnt / $nJobs);

print ">>> split the urls into $nJobs parts\n";
# print "split -dl $splitSize parse.in parse.in.\n";
`split -dl $splitSize parse.in parse.in.`;

for(my $i = 0; $i < $nJobs; $i++){
	my $inFile = sprintf("parse.in.%02d",$i);
	my $outFile = sprintf("parse.out.%02d",$i);
	my $logFile = sprintf("parse.out.%02d.log",$i);

	my $pid = fork();
	if($pid == 0){
		# call PageParser.pl
		my $cmd = "PageParser.pl --parser-mod=\"$parserMod\" <$inFile 1>$outFile 2>$logFile";
		print $cmd . "\n";
		`$cmd`;
		exit;
	} else{
		print ">>> spawn parser process: $pid\n";
	}
}
# wait for all parse threads done
1 while(wait() != -1);
print ">>> all parsers returned, update url status\n";
update_url_status();

# update status by merging with the parsing out files
sub update_url_status{
	print ">>> merge parser result\n";
	print ">> concatenate previous parsing results if there are any\n";
	`find . -type f -name "parse.out.[0-9][0-9]" |xargs -I {} cat {} >> parse.out`;
	`find . -type f -name "parse.out*.log" |xargs -I {} cat {} >> all.log`;

	my %urlStatus = ();
	open STATUS_FILE, "<url.status" or die $!;
	while(<STATUS_FILE>){
		chomp;
		my($url, $status) = split /\t/;
		$urlStatus{$url} = $status;
	}
	close STATUS_FILE;
	open PARSE_FILE, "<parse.out" or die $!;
	while(<PARSE_FILE>){
		chomp;
		my($url,$status) = split /\t/;
		$urlStatus{$url} = $status;
	}
	close PARSE_FILE;
	open STATUS_FILE, ">tmp.url.status" or die $!;
	while(my($url,$status) = each %urlStatus){
		print STATUS_FILE join("\t",($url,$status)) . "\n";
	}
	close STATUS_FILE;
	`mv tmp.url.status url.status`;
	print ">>> cleaning up\n";
	`find . -type f -name "parse.out*"|xargs -I {} rm {}`;
	# remove existing splits
	`find . -type f -name "parse.in.[0-9][0-9]"|xargs -I {} rm {}`;
}