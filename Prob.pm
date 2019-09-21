package Prob;

use strict;
use warnings;

use constant TRUE => 1;
use constant FALSE => 0;

use User;

use Moose;

has 'point'     => ( is => 'rw', isa => "Int" );
has 'user'      => ( is => 'rw', isa => "User" );
has 'phone'     => ( is => 'rw', isa => "Str" );

1;

