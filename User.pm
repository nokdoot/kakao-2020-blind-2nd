package User;

use strict;
use warnings;

use constant TRUE => 1;
use constant FALSE => 0;

use List::Util qw/ any /;
use Moose;

has 'user'      => ( is => 'rw', isa => "Str" );
has 'following' => ( is => 'rw', isa => "ArrayRef[Str]" );
has 'phone'     => ( is => 'rw', isa => "ArrayRef[Str]" );
has 'flw_count' => ( is => 'rw', isa => "Int" );

sub has_phone {
    my $self = shift;
    my $phone = shift;
    return TRUE if any { $_ eq $phone } @{$self->{phone}};
    return FALSE;
}

sub is_following {
    my $self = shift;
    my $phone = shift;
    return TRUE 
        if any { $_ eq $phone } @{$self->{following}};
    return FALSE;
}

1;
