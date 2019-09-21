#!/usr/bin/env perl

use warnings;
use feature qw/ say /;
use Data::Dumper;
use constant FALSE => 0;
use constant TRUE => 1;
use constant TOWARDS_CALL => 2;

use FindBin;
use lib "$FindBin::Bin/local/lib/perl5";
use lib './';
use JSON::XS;
use List::Util qw / first any /;
use Carp;
use Time::HiRes qw / sleep /;

use API;
use User;
use Recommend;
use Prob;

my $server_url = 'https://wqwfrkh5k1.execute-api.ap-northeast-2.amazonaws.com/kakao-2020/';
my $problem = 1;
my $token = '60a3599526706ffe240a54188cd09d04';

my $start = API->start_api({
    server_url          => $server_url,
    problem             => $problem,
    token               => $token,
});

$token = $start->{token};

my $day = 1;

while ( $day ) {
    my @users = ();

    my $page = 1;
    my $size = 500;
    my @all_users = ();
    my $total = 0;
    while ( TRUE ) {
        my $users_api = API->users_api({
            server_url          => $server_url,
            token               => $token,
            page                => $page,
            size                => $size,
        });
        push @all_users, @{$users_api->{users}};
        $total = $users_api->{total};
        last if $total <= $size*$page;
        $page++;
    }
    say $total;
    say scalar @all_users;

    @users = map { 
        my $user = User->new($_);
        $user->flw_count( scalar @{$user->following} );
        $user
    } @all_users;

    my $probs = make_probs(\@users);
    
    @$probs = reverse sort { $a->point <=> $b->point } @$probs;

    my $recom = {};
    for my $prob ( @$probs ) {
        last if $total == 0;

        my $user = $prob->user;
        next if $user->flw_count >= 20;

        $recom->{$user->user} = [] 
            if !defined $recom->{$user->user};
        next if @{$recom->{$user->user}} >= 10;

        push @{$recom->{$user->user}}, $prob->phone;
        $user->flw_count($user->flw_count+1);
        $total--;
    }


    my $recommendations = [];
    for my $user ( keys %$recom ) {
        push @$recommendations, 
            Recommend->new({ 
                user           => $user,
                recommendation => $recom->{$user},
            });
    }

    #
    my $recommendation_api = API->recommend_api({
        server_url          => $server_url,
        token               => $token,
        recommendations     => $recommendations,
    });

    #
    my $simulation_api = API->run_simulation_api({
        server_url          => $server_url,
        token               => $token,
    });

    my $status = undef;
    while ( TRUE ) {
        $status = API->status_api({
            server_url          => $server_url,
            token               => $token,
        });
        
        say $status->{status};
        last if $status->{status} eq 'done';
    }

    $day++;
    say $day;
    
    last if $status->{status} eq 'finish'; 
}

sub find_user {
    my ($users, $phone) = @_;
    return first { $_->user eq $phone } @$users;
}

sub make_probs {
    my $users = shift;
    my $probs = [];

    for my $user_me ( @$users ) {
        next if $user_me->flw_count >= 20;
        for my $phone ( map { $_->user } @$users ) {
            next if $user_me->user eq $phone;
            next if $user_me->is_following($phone);

            my $point = 0;

            if ( $user_me->has_phone($phone) ) {
                $point += 30;
            }
            else {
                $point += 5;
            }
            
            for my $other_user_phone ( @{$user_me->{phone}} ) {
                my $other_user 
                    = find_user($users, $other_user_phone);
                next if !defined $other_user;
                if ( $other_user->is_following($phone) ) {
                    $point += 10;
                }
            }

            for my $other_user_phone ( @{$user_me->{following}} ) {
                my $other_user 
                    = find_user($users, $other_user_phone);
                next if !defined $other_user;
                if ( $other_user->is_following($phone) ) {
                    $point += 10;
                }
            }

            my $prob = Prob->new({
                point   => $point,
                user    => $user_me,
                phone   => $phone,
            });
            push @$probs, $prob;
        }
    }

    return $probs;
}

=pod

https://stackoverflow.com/questions/2329385/how-can-i-unbless-an-object-in-perl/4783486
written by brian d foy

=cut

sub UNIVERSAL::TO_JSON {
    my( $self ) = shift;

    use Storable qw(dclone);

    # https://metacpan.org/pod/Data::Structure::Util
    use Data::Structure::Util qw(unbless);

    my $unblessed_clone = unbless( dclone($self) );
    return $unblessed_clone;
}
