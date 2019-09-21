package Recommend;

use strict;
use warnings;

use constant TRUE => 1;
use constant FALSE => 0;

use User;

use Moose;

has 'user'              => ( is => 'rw', isa => "Str" );
has 'recommendation'    => ( is => 'rw', isa => "ArrayRef[Str]" );

1;
