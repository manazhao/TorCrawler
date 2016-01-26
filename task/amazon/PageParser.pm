#!/usr/bin/perl
use strict;
use warnings;
use pQuery;
use Data::Dumper;
require Exporter;
package task::amazon::PageParser;

our @ISA = qw(Exporter);
#@EXPORT_OK = qw(munge frobnicate);  # symbols to export on request
our @EXPORT = qw(get_parser_map);  # symbols to export on request

sub trim{
	my ($s) = @_;
	$s =~ s/(^\s+)|(\s+$)//;
	return $s;
}


sub parse_list{
	my ($url, $md5, $content) = @_;
	# construct pQuery
	my $result = {
		meta => {
		},
		url => $url,
	};

	if ($url =~ /id=([\w\d]+)/) {
		$result->{id} = $1;
	}

	my $pq = ::pQuery($content);
	my $showAllUrl = $pq->find("#purchased-header a")->attr('href');
	if ($showAllUrl) {
		# change number of pages to 200
		$showAllUrl =~ s/itemsPerPage=(\d+)/itemsPerPage=200/;
	}

	$result->{url_all} = $showAllUrl;
	$result->{"meta"}->{title} = $pq->find("#reg-info > div:nth-child(1) > h1")->text();
	$result->{"meta"}->{"arrival_date"} = $pq->find("#reg-info > div.a-row.a-spacing-top-none.a-size-base.reg-meta-data > span.a-color-base")->text();
	$result->{"meta"}->{location} = $pq->find("#reg-info > div.a-row.a-spacing-top-none.a-size-base.reg-meta-data > span:nth-child(5)")->text();

	$pq->find("div.a-section.a-spacing-none")->each(sub{
			::pQuery($_)->find(".a-fixed-left-grid")->each(sub{
					my $tmpItem = {};
					my $itemId = ::pQuery($_)->attr('id');
					$itemId =~ s/item_//;
					$tmpItem = {id => $itemId};
					my $tmpPq = ::pQuery($_);
					$tmpItem->{image} = $tmpPq->find("#item-img img")->attr('src');
					$tmpItem->{title} = $tmpPq->find("#item_title_$itemId a")->attr("title");
					$tmpItem->{url} = $tmpPq->find("#item_title_$itemId a")->attr("href");
					$tmpItem->{price} = $tmpPq->find("#item_price_$itemId .a-color-price")->text();
					$tmpItem->{price} =~ s/\$//g;
					$tmpItem->{num_review} = $tmpPq->find("#item_review_$itemId a.a-size-base")->text();
					$tmpItem->{num_review} =~ s/[\(\)]//g;
					$tmpItem->{rating} = $tmpPq->find("#item_review_$itemId .a-icon-alt")->text();
					$tmpItem->{rating} =~ s/(\/\d+)?\sStars//g;
					if ($tmpItem->{url} =~ /product\/(.*?)\//) {
						$tmpItem->{asin} = $1;
					}
					push @{$result->{items}},$tmpItem;
				});
		}
	);
	return $result;
}

# only export this function
sub get_parser_map{
	return {
		"\\/gp\\/registry\\/registry.html" => \&parse_list,
		"\\/gp\\/baby-reg" => \&parse_list
	}
}

1;
