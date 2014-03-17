#!/usr/bin/perl
use CGI;

my $query = CGI->new;
my $val = $query->param('sendData0');

print $query->header;

print "Your Entered:: $val\n";
print "Result from server sadf\n";

sub getUpperCase{

	return "result";
}
my $output = &getUpperCase($query);

print "$output asdasg";

print "ksdaflaslgj";