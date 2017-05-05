#!/usr/bin/perl -w
#|----------------------------------------------|
#| Fetch Cypress FX3 streamer-in samples        |
#|----------------------------------------------|
#| Version P1A, Deyan Levski, 14.02.2017        |
#|----------------------------------------------|
#| Version P2A, Deyan Levski, 05.05.2017        |
#|----------------------------------------------|
#| Edited to fetch 128 columns after 0xCAFE has |
#| been encountered. If you want to fetch more  |
#| columns - modify constant BYTECOUNTEND       |
#|----------------------------------------------|
#| Usage: fetchSamples.pl stream.hex stream.csv |
#|----------------------------------------------|
#|-+-|
#

use strict;

use constant BYTECOUNTEND => 276; # defines number of columns fetched after header enocounter

# write subroutine

    sub wri {
	my($sample_msb, $sample_lsb) = @_;

	my $sample_8b_m = sprintf("%08b", $sample_msb);
	my $sample_8b_l = sprintf("%08b", $sample_lsb);

	my $sample_16b = $sample_8b_m . $sample_8b_l;

	# convert bin to decimal
	my $sample_16b_unsigned_dec = oct("0b".$sample_16b);

	my $out_form = sprintf("%s, ", $sample_16b_unsigned_dec);

	return $out_form;
    }

my $fname = $ARGV[0];
my $fparsename = $ARGV[1];

local $/ = \16536; # fetch byte-by-byte 8-bits

open(F, '<', $fname) or die("Unable to open file $fname, $!");
binmode(F);

my $buf;
my $ct=0;
my $byte=0;
#my $byte_old=0;
my $byte_cnt=0;
my $byte_lock=0;
my $sample_msb=0;
my $sample_lsb=0;
my $offset=0;

open(my $fh, '>', $fparsename) or die "Could not open file '$fparsename' $!";
print $fh ("Sample, Value, \n");
print $fh ($ct,", ");

while($buf = <F>){
	foreach(split(//, $buf)){

		my $byte_old = $byte;
		$byte = ord($_);	# fetch byte (in decimal)

		#printf("0x%02x ",$byte);

		if (($byte_old == 202) && ($byte == 254)) {	# CA = 202, FE = 254
			$byte_cnt = 0;
			$byte_lock = 1;
		}

		if ($byte_lock == 1) {
			$byte_cnt++;
		}

		if ($byte_cnt == 20 + $offset) {	# 20th byte after CAFE in header
			$sample_msb = $byte;
		}
		if ($byte_cnt == 20 + $offset+1) {	# 21th byte after CAFE in header
			$sample_lsb = $byte;
			my $out_form = wri($sample_msb,$sample_lsb);
			printf $fh $out_form;
			$offset++;
			$offset++;
		}

		if (($byte_cnt == BYTECOUNTEND) && ($byte_lock == 1)) {	# lock down and concatenate
			$byte_lock = 0;
			$byte_cnt = 0;
			$offset = 0;

			my $out_form = sprintf("\n%d, ", $ct++);

			printf $fh $out_form;
		}

	}

}
close(F);
close($fh);
print "done\n";
