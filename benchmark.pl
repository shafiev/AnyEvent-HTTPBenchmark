#!/usr/bin/env perl
use common::sense; #new features in perl(not for 5.8.8 and older (; )
use AnyEvent::HTTP; # main module
use Getopt::Long; # to command line parsing
use POSIX;
use Data::Dumper; # to see the date in debug
my $DEBUG = 0; #Debug mode. Default is false (0)
my $verbose = 0; #to view the each connection result 
my $timeout = 60; 
my $count = 30000; #number of requests
my $concurency = 20; # number of parralle requests
my $done = 0; 
my $url = 'http://elementa.su/';# default url to test
my $method = 'GET'; #http method
my $proxy; # proxy server
my $file; #scenario file
my $max_recurse = 10; # the default recurse number;
my $useragent = 'Mozilla/5.0 (compatible; U; AnyEvent::HTTPBenchmark/0.05; +http://github.com/shafiev/AnyEvent-HTTPBenchmark)';

#arrays
my @reqs_time; # the times of requests

parse_command_line(); #parsing the command line arguments

$AnyEvent::VERBOSE = 10 if $DEBUG;
$AnyEvent::HTTP::MAX_PER_HOST = $concurency;
$AnyEvent::HTTP::set_proxy = $proxy;
$AnyEvent::HTTP::USERAGENT = $useragent; 

#on ctrl-c break run the end_bench sub.
$SIG{'INT'} = 'end_bench';

my $cv = AnyEvent->condvar; 

#start measuring time
my $start_time = AnyEvent->time;


print 'Started at ' .format_time( $start_time ) . "\n";

#starting requests
for ( 1 .. $concurency ) 
{
    add_request($_, $url);
}

$cv->recv; # begin receiving message and make callbacks magic ;)
end_bench(); # call the end

#subs 
sub parse_command_line
{
    #get options which ovveride the default values
    my $result = GetOptions ("url=s" => \$url,
                             "n=i"   => \$count,
                             "c=i"   => \$concurency,
                             "verbose!" => \$verbose,
                             "debug" => \$DEBUG,
                             "proxy=s" => \$proxy,
                             "useragent=s" => \$useragent );    
}

sub add_request 
{
    my ($id, $url) = @_;

    my $req_time = AnyEvent->time;
    http_request $method => $url, timeout => $timeout, sub 
    {
        my $completed = AnyEvent->time;
	my $req_time = format_seconds( $completed - $req_time );
        print "Got answer in $req_time seconds\n" if $verbose;
        push @reqs_time , $req_time;
        $done++;
        
        my $hdr = @_[1];
       
        if ( $hdr->{Status} =~ /^2/ )
        {
            print "done $done\n" if $verbose;
        }
        else
        {
            print STDERR "Oops we get problem in  request  . $done  . ($hdr->{Status}) . ($hdr->{Reason}) \n";
        }    
          
        return add_request($done, $url) if $done < $count;

        $cv->send;
    }
}


sub end_bench
{
    my $end_time = AnyEvent->time;
    my $overall_time = format_seconds( $end_time - $start_time );
    print "It takes the $overall_time seconds\n";
    my $sum;
    
    print 'Requests per second: '.sprintf( "%.2f", $count / $overall_time )."\n";

    #sort by time
    @reqs_time = sort (@reqs_time);
    
    for my $i(0..scalar(@reqs_time) )
    {
        #calculate average time
        $sum +=$reqs_time[$i];
    }
    
    print "\nShortest is :  $reqs_time[0]  sec. \n";
    print "Average time is : ". format_seconds($sum/$count) . " sec. \n";
    print "Longest is :  $reqs_time[scalar(@reqs_time)-1] sec. \n";
    exit;
}

sub format_time {
    my ($microsec, $seconds) = modf( shift );

    my ($sec, $min, $hour) = localtime( $seconds );

    return sprintf "%02d:%02d:%02d.%04d", $hour, $min, $sec, int( $microsec * 10000 );
}

sub format_seconds {
    return sprintf "%.4f", shift;
}

1;