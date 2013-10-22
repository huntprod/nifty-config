#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Nifty::Config' ) || print "Bail out!\n";
}

diag( "Testing Nifty::Config $Nifty::Config::VERSION, Perl $], $^X" );
