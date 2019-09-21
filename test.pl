#!/usr/bin/env perl

use strict;
use warnings;
use feature qw/ say /;

use FindBin;
use lib "$FindBin::Bin/local/lib/perl5";
use lib './';

use API;


my $a = API->test_api;


sal $a;
