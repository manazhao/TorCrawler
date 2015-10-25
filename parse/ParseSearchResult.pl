#!/usr/bin/perl
# parse search page result
# output is a list of urls for individual property pages
#!/usr/bin/perl
use strict;
use warnings;
use JSON qw(encode_json decode_json);
use pQuery;
use Data::Dumper;
use Try::Tiny;
use Text::Balanced qw(extract_bracketed);
use File::Basename;


foreach(@ARGV){
	chomp;
	my $file = $_;
	open my $fh, "<", $file or (warn "failed to open $file" and next);
	my @file_lines = <$fh>;
	#########   print Dumper(\%name_product);
	my $content = join(" ",@file_lines);
	# print $content . "\n";
	# get designer information
	my $pq = pQuery($content);

	my %result = ();
	$pq->find(".hdp-link")->each(sub{
			$result{url} = pQuery($_)->attr('href');
		});

	# pagination 
	my $maxPage = 0;
	$pq->find("ol.zsg-pagination > li")->each(sub {
			my $href = pQuery($_)->find("a")->attr('href');
			my $tmpPage;
			if($href && $href =~ /(\d+)_p/){
				$tmpPage = $1;
				if($tmpPage > $maxPage){
					$maxPage = $tmpPage;
				}
			} 
		});
	if($maxPage > 0){
		$result{maxPage} = $maxPage;
	}

	my($name, $path, $suffix) =  fileparse($file,('.html','.htm'));
	my $resFile = $path . $name . ".json";

	open RES_FILE , ">", $resFile or die $!;
	print RES_FILE encode_json(\%result) . "\n";
	close RES_FILE;
}
