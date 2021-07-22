#!/usr/bin/env perl
#===============================================================================
#
#         FILE: paf2delta.pl
#
#        USAGE: ./paf2delta.pl  
#
#  DESCRIPTION: convert paf to delta format
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Hainan Zhao
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 07/09/2021 06:01:46 PM
#     REVISION: 0.1
#===============================================================================

use strict;
use warnings;
use utf8;
my %delta_aln;
my $aln_num;
my %seq_len;
print "file1 file2\nNUCMER\n";

open F,$ARGV[0] or die("cannot find file\n");
while (<F>) {
	next if /^\@/;
	chomp;
	my @tem=split /\t/,$_;
	my ($str,$ref,$ref_len,$ref_st,$ref_ed,$sbj,$sbj_len,$sbj_st,$sbj_ed)=@tem[4,5..8,0..3];
	$aln_num++;

	$seq_len{$ref}=$ref_len;
	$seq_len{$sbj}=$sbj_len;
	$ref_st++;
	$sbj_st++;
	my ($cs)=$_=~/cs:Z:(\S+)/;
	my ($diff,$delta)=read_cs($cs,$str);
	if($str eq "+"){
		$delta_aln{"$ref $sbj"}{$aln_num}=[$ref_st,$ref_ed,$sbj_st,$sbj_ed,$diff,$delta,$str];
	}
	else{
		$delta_aln{"$ref $sbj"}{$aln_num}=[$ref_st,$ref_ed,$sbj_ed,$sbj_st,$diff,$delta,$str];
	}
}

foreach my $pair(keys %delta_aln){
	my ($diff,$delta,$str)=$delta_aln{$pair};
	my @seqs=split /\s+/,$pair;
	print join " ",(">$pair", $seq_len{$seqs[0]},$seq_len{$seqs[1]});
	print "\n";

	foreach my $aln_num(keys %{$delta_aln{$pair}}){
		my @aln=@{$delta_aln{$pair}{$aln_num}};
		print join " ",(@aln[0..4],$aln[4],0);
		print "\n";
		foreach my $ad(@{$aln[5]}){
			print "$ad\n";
		}
	}
}


sub read_cs {
	my $cs=shift @_;
	my $str=shift @_;
	my @code=$cs=~/(\W)(\w+)/g;
	my $pos_ins=0;
	my $pos_del=0;
	my $diff=0;
	my @delta;
	#120*ct:174*ta:212-aat:315+tttt:410*gc:457
	my $nn=@code;
	my $x;
	my $x_m;
	my $up;
	if($str eq "+"){
		$x=0;
		$x_m=2;
		$up=$nn-1;
	}
	else{
		$x=$nn-2;
		$x_m=-2;
		$up=-4;
	}
	while($code[$x]){
		if($code[$x] eq ":"){# matches, add to pos
			$pos_ins+=$code[$x+1];
			$pos_del+=$code[$x+1];
		}
		elsif($code[$x] eq "*"){# mismatches, add to diff
			$diff++;
			$pos_ins++;
			$pos_del++;
		}
		elsif($code[$x] eq "-"){# insertion in ref, add to delta
			push @delta,($pos_ins+1);
			my $ins_len=length $code[$x+1];
			$pos_ins+=$ins_len;
			for(my $y=1;$y<$ins_len;$y++){
				push @delta,"1";
			}
			$diff+=$ins_len;
			$pos_ins=0;
			$pos_del=0;

		}
		elsif($code[$x] eq "+"){# deletion in  ref, add to delta
			push @delta,-1*($pos_del+1);
			my $del_len=length $code[$x+1];
			for(my $y=1;$y<$del_len;$y++){
				push @delta, "-1";
			}
			$diff+=$del_len;
			$pos_ins=0;
			$pos_del=0;
		}
		else{
			print "unkown cs\n";
			exit;
		}
		$x+=$x_m;
		if( $x-$up ==2){
			last;
		}
	}
	push @delta,0;
	my $dl=@delta;
	return ($diff,\@delta)
}


