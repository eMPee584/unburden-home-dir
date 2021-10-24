#!perl

use strict;
use warnings;

use File::Copy;

use lib qw(t/lib lib);
use Test::UBH;

my $t = Test::UBH->new;

my $BINDIR = $t->BASE."/bin";
my $XSESSIOND = $t->BASE."/Xsession.d";
my $RPSCRIPT = "25unburden-home-dir-xdg";

my ($cmd, $wanted, $output, $stderr);

# Set a debug environment: /bin needed for sed, /usr/bin for run-parts
# thanks to braindead usrmerge.
$ENV{PATH} = "$BINDIR:/bin:/usr/bin";
$ENV{UNBURDEN_BASENAME} = $t->BASENAME;
delete $ENV{XDG_CACHE_HOME};

$t->setup_test_environment_without_target('');

ok( mkpath($XSESSIOND, $BINDIR, {}), "Create test environment (directories)" );
dir_exists_ok( "$BINDIR", "Script directory has been created" );
dir_exists_ok( "$XSESSIOND", "Xsession.d directory has been created" );

ok( copy( (($ENV{AUTOPKGTEST_TMP} || $ENV{ADTTMP}) ? '/etc/X11/' : '').
          "Xsession.d/$RPSCRIPT","$XSESSIOND/" ),
    "Install Xsession.d script" );
ok( $t->write_file("$BINDIR/unburden-home-dir", "#!/bin/sh\necho \$0 called\n"), "Create test script" );
ok( chmod( 0755, "$BINDIR/unburden-home-dir" ), "Set executable bit on testscript" );
ok( $t->write_file($t->HOME.'/.'.$t->BASENAME,
               "FILELAYOUT=".$t->TARGET."/%s\nUNBURDEN_HOME=yes\nTARGETDIR=.\n"),
    "Configure Xsession.d script to run unburden-home-dir" );

$t->call_cmd("run-parts --list $XSESSIOND");
$t->eq_or_diff_stderr('', "run-parts STDERR");
$t->eq_or_diff_stdout("$XSESSIOND/$RPSCRIPT\n", "run-parts STDOUT");

$t->call_cmd("sh -c '. $XSESSIOND/$RPSCRIPT; echo \$XDG_CACHE_HOME'");
$t->eq_or_diff_stderr('', "Xsession.d STDERR is empty");
$t->eq_or_diff_stdout('./'.$t->TARGET."/cache\n", "XDG_CACHE_HOME is set");

ok( $t->write_file($t->HOME.'/.'.$t->BASENAME, "UNBURDEN_HOME=no\nTARGETDIR=.\n"), "Configure Xsession.d script to NOT run unburden-home-dir" );

$t->call_cmd("sh -c '. $XSESSIOND/$RPSCRIPT; echo \$XDG_CACHE_HOME'");
$t->eq_or_diff_stderr('', "Xsession.d STDERR is empty");
$t->eq_or_diff_stdout('', "XDG_CACHE_HOME is not set");

$t->done;
