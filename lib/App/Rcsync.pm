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
		[ "config|c=s", "configuration file to use", 
			{ default => File::Spec->catfile(File::HomeDir->my_home, '.rcsync') } 
		],
		[ "all|a",      "sync all profiles"      ],
		[ "list|l",     "list all profiles"      ],
		[ "stdout|s",   "print to STDOUT" ],
	);
}

sub validate_args 
{
	my ($self, $opt, $args) = @_;

	if ( !$opt->{all} and !$opt->{list} and !@$args )
	{
		$self->usage_error("Please specify profiles to sync");
	}
}

sub execute 
{
	my ($self, $opt, $args) = @_;

	my %config = Config::General->new( $opt->{config} )->getall;	
	my @all_profiles = grep { ref $config{$_} eq 'HASH' } keys %config;

	my %profiles_config;
	@profiles_config{@all_profiles} = @config{@all_profiles};
	
	my @profiles = $opt->{all} ? @all_profiles : @$args;

	if ( $opt->{list} )
	{
		print "$_\n" for @all_profiles;
		return;
	}	

	my $tt = Template->new( INCLUDE_PATH => $config{base_dir} ) or croak Template->error;

	foreach my $profile_name (@profiles)
	{
		if (!$profiles_config{$profile_name})
		{
			warn "No such profile '$profile_name'\n";
			next;
		}

		my $profile = dao $profiles_config{$profile_name};
		
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
