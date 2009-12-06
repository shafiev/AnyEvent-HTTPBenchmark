#!/usr/bin/perl
use common::sense;
use AnyEvent::HTTP;
use Time::HiRes;
use Getopt::Long;
use DateTime;
use Data::Dumper;
#$AnyEvent::VERBOSE = 10;

my $timeout = 60;
my %timeofreq;

my $count = 100;
my $concurency = 10;

my $method = 'GET';

$AnyEvent::HTTP::MAX_PER_HOST = $concurency*$concurency;

my $done = 0;
my $url =  'http://ya.ru';



sub file_open
{
my $file = $ARGV[0];

die "invalid file "
    unless -e $file
    and -s _ and -f _;

my @scenario;

open FH, '<', $file;
while ( <FH> ) {
    my ( $method, $url ) = split( / /, $_, 2 );

    if ( $method !~ /get|post/io ) {
        warn "bad method [$method]\n";
        next;
    }

    push( @scenario, [ $method, $url ] );
}
close FH;

}

#file_open();


my $cv = AnyEvent->condvar;

my $start_time = Time::HiRes::time;
my $dt = DateTime->from_epoch( epoch => $start_time  );
say 'Started at ' .
($dt->hms). '.' .($dt->millisecond);


$SIG{'INT'} = 'end_bench';

for ( 1 .. $concurency ) 
{
    add_request($_, $url);
}

$cv->recv;

sub add_request 
{
    my ($id, $url) = @_;
    my $req_time = Time::HiRes::time;
    http_request $method => $url, timeout => $timeout, sub 
    {
        my $completed = Time::HiRes::time;
        my $dtin = DateTime->from_epoch( epoch => ($completed-$req_time)  );
        say 'Got answer in ' . ($dtin->second) . '.' . ($dtin->millisecond) . ' seconds'  ;
        $done++;

        my ($body, $hdr) = @_;
        print "finished request $id, done $done\n";
        
        return add_request($done, $url) if $done < $count;
        
        $cv->send;
    };
    
}

sub end_bench
{
my $end_time = Time::HiRes::time;
my $end_dt = DateTime->from_epoch( epoch => ($end_time - $start_time) );
say 'It\'s takes the '  . ($end_dt->second) .':' .($end_dt->millisecond);
say 'Requests per second  is ' . ( $count /($end_dt->second) ); 
exit;
}

end_bench();
1;
