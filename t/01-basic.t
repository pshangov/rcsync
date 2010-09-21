use strict;
use warnings;

use Test::More tests => 2;
use App::Cmd::Tester;
use Test::Differences;
use File::Temp;
use File::Spec;
use File::Slurp qw(write_file);

my ( $config_fh, $config_filename ) = tempfile();
my ( $tmpl_fh, $tmpl_filename ) = tempfile();

my $tmpl_parent = File::Spec->updir( $tmpl_filename );
(undef, undef, my $tmpl_basename) = File::Spec->splitpath( $tmpl_filename );


my $config = <<"CONFIG"
base_dir $tmpl_parent
<test1>
	template $tmpl_filename
	filename doesnt_matter
	<param>
		param1 value1
		param2 value2
	</param>
</test1>
CONFIG

my $template = <<TEMPLATE
setting1 = [% param1 %]
setting2 = [% param2 %]
TEMPLATE

print $config_fh $config or die $!;
print $tmpl_fh $template or die $!;

my $output = <<OUTPUT
setting1 = value1
setting2 = value2
OUTPUT

my $result = test_app( 'App::Rcsync' => [ '--config', $config_filename, '--all', '--stdout' 'test1' ] );

eq_or_diff($result->stdout, $output, 'file parsed properly');
eq_or_diff($result->error, undef, 'threw no exceptions');

