#!/usr/bin/env perl
#Yet another http benchmark ;)
use common::sense; 
use AnyEvent::HTTP;
use Time::HiRes;
use Getopt::Long; 
use DateTime;
use Data::Dumper;
my $DEBUG = 0; #Debug mode. Default is false (0)
my $timeout = 60;
my $count = 30000; #number of requests
my $concurency = 20; # number of parralle requests
my $done = 0; 
my $url = 'http://elementa.su/';# url to test
my $method = 'GET'; #http method

my $cv = AnyEvent->condvar;
#arrays
my @reqs_time; # the times of requests
my @scenario;  #used for  script scenario file . Not yet implemented (: 

$AnyEvent::VERBOSE = 10 if $DEBUG;
$AnyEvent::HTTP::MAX_PER_HOST = $concurency;

#on ctrl-c break run the end_bench sub.
$SIG{'INT'} = 'end_bench';

my $start_time = Time::HiRes::time;
my $dt = DateTime->from_epoch( epoch => $start_time  );
say 'Started at ' .($dt->hms). '.' .($dt->millisecond);

#read_script_file(); #read the url script file

#starting requests
for ( 1 .. $concurency ) 
{
    add_request($_, $url);
}

$cv->recv; # begin receiving message and make callbacks magic ;)
end_bench(); # call the end

#subs 
sub add_request 
{
    my ($id, $url) = @_;

    my $req_time = Time::HiRes::time;
    http_request $method => $url, timeout => $timeout, sub 
    {
        my $completed = Time::HiRes::time;
        my $dtin = DateTime->from_epoch( epoch => ($completed-$req_time)  );
        say 'Got answer in '. $dtin->second . '.' . $dtin->millisecond .' seconds';
        push( @reqs_time , ( ($dtin->second) .'.'. ($dtin->millisecond) ) );
        $done++;
        
        my $hdr = @_[1];
       
        if ( $hdr->{Status} =~ /^2/ )
        {
            say "done $done\n";
        }
        else
        {
            say "Oops we get problem in  request  . $done  . ($hdr->{Status}) . ($hdr->{Reason}) ";
        }    
          
        return add_request($done, $url) if $done < $count;

        $cv->send;
    }
}


#sub read_script_file under test
sub read_script_file
{
    my $file = $ARGV[0];

    warn "invalid file "
    unless -e $file and -s _ and -f _;


    open FH, '<', $file;
    while ( <FH> ) 
    {
        chomp;
        my ($method, $url) = split( / /, $_, 2 );

        if ( $method !~ /get|post/io ) 
        {
            warn "bad method [$method]\n";
            next;
        }


        push( @scenario, [ $method, $url ] );
    }

  close FH;

}


sub end_bench
{
    my $end_time = Time::HiRes::time;
    my $end_dt = DateTime->from_epoch( epoch => ($end_time - $start_time) );
    say;
    say 'It\'s takes the '  . ($end_dt->second) .'.' .($end_dt->millisecond) .' seconds';
    my $sum;
    
    #dirty hack to avoid division by zero ;)
    if ( ($end_dt->second) ==0 )
    { 
        say 'Requests per second  is ' . ( $count /($end_dt->millisecond) ); 
    }
    else
    {   
        say 'Requests per second  is ' . ( $count /( ($end_dt->minute)*60 + ($end_dt->second) ));
    }       
    #sort by time
    @reqs_time = sort (@reqs_time);
    
    for my $i(0..scalar(@reqs_time) )
    {
        #calculate average time
        $sum +=$reqs_time[$i];
    }
    say ;#new line
    say 'Shortest is : '. $reqs_time[0] . ' sec.';
    say 'Average time is : '. ($sum/$count) . ' sec.';
    say 'Longest is : '. $reqs_time[scalar(@reqs_time)-1] . ' sec.';
    exit;
}

1;