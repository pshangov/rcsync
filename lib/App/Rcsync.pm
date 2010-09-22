package App::Rcsync;

# ABSTRACT: Sync configuration files across machines

use strict;
use warnings;

use File::HomeDir;
use Data::AsObject qw(dao);
use Template;
use Config::General;
use File::Spec;
use Carp;

use base qw(App::Cmd::Simple);

sub opt_spec 
{
	return (
		[ "config|c=s", "configuration file to use", { default => File::HomeDir->my_home . '.rcsync.conf' } ],
		[ "all|a",      "sync all profiles"      ],
		[ "list|l",     "list all profiles"      ],
		[ "stdout|s",   "print output to STDOUT" ],
	);
}

sub validate_args 
{
	my ($self, $opt, $args) = @_;

	if ( !$opt->{all} and !@$args )
	{
		$self->usage_error("Please specify profiles to sync");
	}
	elsif ( $opt->{all} and @$args )
	{
		$self->usage_error("'all' option conflicts with individual profiles as args");
	}
}

sub execute 
{
	my ($self, $opt, $args) = @_;

	my %config = Config::General->new( $opt->{config} )->getall;	
	my @profiles = $opt->{all} ? @$args : grep { $_ ne 'base_dir' } keys %config;
	my $tt = Template->new( INCLUDE_PATH => $config{base_dir} ) or croak Template->error;

	foreach my $profile_name (@profiles)
	{
		if ( $opt->{list} )
		{
			print "$profile_name\n";
			next;
		}

		my $profile = dao $config{$profile_name};
		
		$tt->process(
			$profile->template,
			$profile->param,
			$opt->{stdout} ? \*STDOUT : $profile->filename,
		) or die $tt->error;

		

		if (!$opt->{stdout})
		{
			print "Successfully synced profile '$profile_name'\n";
		}
	}
}

1;
