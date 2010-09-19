package App::Rcsync;

use strict;
use warnings;

use File::HomeDir;
use Data::AsObject;
use Template;
use Config::General;
use Carp;

use base qw(App::Cmd::Simple);

sub opt_spec 
{
	return (
		[ "config|c", "configuration file to use", { default => File::HomeDir->my_home . '.rcsync.conf' } ],
		[ "all|a",    "sync all profiles"      ],
		[ "stdout|s", "print output to STDOUT" ],
	);
}

sub validate_args 
{
	my ($self, $opt, $args) = @_;

	if ( !$opt->{all} and !@$args )
	{
		$self->usage_error("Please specify profiles to sync");
	}
	elsif if ( $opt->{all} and @$args )
	{
		$self->usage_error("'all' option conflicts with individual profiles as args");
	}
}

sub execute 
{
	my ($self, $opt, $args) = @_;

	my %config = Config::General->new( $opt->{config} );
	my @profiles = $opt->{all} ? @$args : keys %config;
	my $tt = Template->new or croak Template->error;

	foreach my $profile_name (@profiles)
	{
		my $profile = dao $config{$profile_name};
		
		$tt->process(
			$profile->template,
			$profile->params,
			$opt->{stdout} ? \*STDOUT : $profile->filename,
		) or croak $tt->error;

		if (!$opt->{stdout})
		{
			print "Successfully synced profile '$profile_name'\n";
		}
	}
}

1;
