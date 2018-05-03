package M6::App::Config;
use Modern::Perl;
use YAML::AppConfig;

###############################################################################
# global variables
###############################################################################

our $VERSION  = '0.07';
our $NAME     = 'm6-app-config';
our $DEF_SITE = 'DEFAULT';
our $YAML_LIB = 'YAML::XS';
our $CONFIG   = "/etc/$NAME/$NAME.yml";

###############################################################################
# public functions
###############################################################################

sub new {
    my ( $class, $app, $site ) = @_;
    my $self = bless {}, $class;

    $self->_init( $app, $site );

    return $self;
}

sub get {
    my ( $self, $key ) = @_;
    my $app            = $self->{app};
    my $keys           = $self->_get_app_conf_keys();

    # look up the key
    if ( grep { $key eq $_ } @$keys ) {
        return $self->{$app}->get( $key );

    # merge the next yaml document, and try again
    } elsif ( ! $self->{fb_done} ) {
        my $file = $self->_select_yml_file();

        # merge the next yaml file content
        $self->{$app}->merge( file => $file );

        # finally invoke ourselves again
        $self->get( $key );

    } else {
        die "Config key: $key cannot be found!";
    }
}

sub get_all {
    my ( $class, $app, $site ) = @_;

    my $obj = M6::App::Config->new( $app, $site );
       $obj->_get_all_app_conf_keys( $app );

    my %config = map { $_ => $obj->get($_) } @{ $obj->_get_app_conf_keys };
    
    # depending on context, lets return a hash or its reference
    return wantarray ? %config : \%config;
}

# TODO:
# please comment during the code review, if we need a function to
# write the config files, too

sub put {
    my ( $self, $key ) = @_;
}

###############################################################################
# private functions
###############################################################################

sub _get_app_conf_keys {
    my ( $self ) = @_;
    my $application = $self->{app};

    return [ $self->{ $application }->config_keys() ];
}

sub _get_all_app_conf_keys {
    my ( $self ) = @_; 
    my $config_dir   = $self->{config}->get('config_directory');
    my $extension    = $self->{config}->get('config_extension');
    my $default_file = $self->{config}->get('default_config');
    my $app          = $self->{app};
    my $site         = $self->{site};
    my @files        = ();

    push @files, 
        ( "$config_dir/$DEF_SITE/$app.$extension", 
          "$config_dir/$DEF_SITE/$default_file" )
     if ( $site ne $DEF_SITE );

    push @files, ( "$config_dir/$default_file",
                   "$config_dir/$site/$default_file",
                   "$config_dir/$site/$app.$extension" );
   
    foreach ( @files ){
        ( -e $_ ) ? $self->{$app}->merge( file => $_ )
                  : next;
    }
}

sub _init {
    my ( $self, $app, $site ) = @_;

    # initializing internal variables
    $self->_fallback_init();

    $self->{app}    = $app;
    $self->{site}   = uc ( $site // $DEF_SITE );
    $self->{config} = YAML::AppConfig->new( file       => _get_config_dir(),
                                            yaml_class => $YAML_LIB );

    $self->_read_application_config( $app );
}

sub _set_config_dir {
    my ( $self, $dir ) = @_;
    $CONFIG = $dir;
}

sub _get_config_dir {
    return $CONFIG;
}

sub _read_application_config {
    my ( $self, $app ) = @_;

    my $cnf         = $self->{config};
    my $site        = $self->{site};
    my $config_dir  = $cnf->get('config_directory');
    my $extension   = $cnf->get('config_extension');

    my $config_file = "$config_dir/$site/$app.$extension";

    die "Configuration file: $config_file does not exist!"
     if ( ! -e $config_file  );

    $self->{$app} = YAML::AppConfig->new( file       => $config_file,
                                          yaml_class => $YAML_LIB );
}

sub _select_yml_file {
    my ( $self ) = @_;

    my $cnf          = $self->{config};
    my $app          = $self->{app};
    my $config_dir   = $cnf->get('config_directory');
    my $extension    = $cnf->get('config_extension');
    my $default_file = $cnf->get('default_config');
    my $site         = $self->{site};
    my $state        = $self->_fallback_state();
    my $config_file  = undef;

    if ( $state eq 'site' ){
       $config_file = "$config_dir/$site/$app.$extension";
       $self->_fallback_done();   
    } elsif ( $state eq 'site-default' ){
       $config_file = "$config_dir/$site/$default_file";

    } else { # must be the default case 
       $config_file = "$config_dir/$default_file";
    }

    return $config_file;
}

sub _fallback_init {
    my $self = shift;
    $self->{fallback} = 0;
    $self->{fb_done}  = 0;
}

sub _fallback_done {
    my $self = shift;
    $self->{fb_done} = 1;
}

sub _fallback_state {
    my ( $self )  = @_;
    my $cnf       = $self->{config};
    my @fallbacks = @{$cnf->get_fallback_order()};

    # uncoverable branch false
    return $fallbacks[ $self->{fallback}++ ]
     if $self->{fallback} <= $#fallbacks;
}

1;

=head1 NAME

M6::App::Config - hierarchical, centralised configurations for Perl

=head1 SYNOPSIS

 use M6::App::Config;
   
 # initialization of the configuration class for a specific application
 # on a specific site ( DEFAULT, when it's not specified explicitly )
 my $cnf = M6::App::Config->new( 'm6-autoprovision', 'NL' );

    # get a value of a config key:
    $cnf->get( 'ping_header' );

    # or a nice syntactic sugar:
    $cnf->get_ping_header;

=head1 DESCRIPTION

C<M6::App::Config> class aims at centralising configuration values
used by AMS-IX's platform software (provisioning, monitoring, etc.).

=head1 CONFIGURATION

This module expects several variables defined in F<m6-app-config.yml>
More details description can be found in the description for each subroutine.

=head1 CONSTRUCTOR

=over

=item B<new> ( I<APP>, I<SITE> )
X<new> invokes private method X<_init>, then returns a new C<M6::App::Config> 
object.
I<APP>: Application name as it is configured in m6-app-config.yml. eg.: 'm6-autoprovision'
I<SITE>: Site name of the exchange. eg.: 'NL', 'CHI', etc.

=back

=head1 METHODS

=over

=item B<get> ( I<KEY> )
X<get> provides access to config files for querying existing keys. When the
searched key cannot be found in the first place, it falls back to a wider level.
First, it makes a list of existing keys from the application related config 
file. It greps through this list for the searched I<KEY>, and immediately returns with the value, if it exists.
When I<KEY> does not exist, it falls back to the next configuration level, 
merges the config file, and invokes B<get> again. It falls back recursively
to the widest config level or until I<KEY> is found. If I<KEY> cannot be found,
it dies with an error message.

I<KEY>: name of the searched key. eg.: 'ping_header'.

=item B<get_all> ( I<APP>, I<SITE> )
X<get_all> is a wrapper function around B<_init> and B<_get_all_conf_keys>.
It does exectly two things: invokes the constructor of C<M6::App::Config> class,
then reads all the configuration keys and values from the first level C<YAML> 
file.
Finally, it returns either a hash or its reference, depending on the context,
the function was invoked.

=item B<put> ( I<KEY>, I<VAL> )
X<put>

To be implemented.
I<KEY>: name of the config key to be written.
I<VAL>: value of the key to be written.

=back

=head2 Private Methods

You probably should not call these outside of the module. Actually, you
are not even able to call these methods, because they are not exported.

=over

=item B<_init> ( I<APP>, I<SITE> )
X<_init> is a private method, used to initialize the inner structure of a 
C<M6::App::Config> object. 

=item B<_read_application_config> ( I<APP> )
X<_read_application_config> is a private method, used to read and parse
an application level config file. It dies when referred config file does
not exist. Otherwise, it uses C<YAML::AppConfig> package to parse a config
file.

It expects the following variables in F<m6-app-config.yml>:
C<config_directory>: path to the main level configuration files
C<config_extension>: extension of config files, eg.: 'yml'

I<APP>: Application name as it is configured in F<m6-app-config.yml>. eg.: 'm6-autoprovision'

=item B<_get_app_conf_keys>
X<_get_app_conf_keys> is wrapper method around the method 'config_keys' of 
C<YAML::AppConfig>. It returns an array reference of existing keys of an
application.
It does not expect any config variables from F<m6-app-config.yml>

=item B<_fallback_init>
X<_fallback_init> is used to initialize inner state variables.

=item B<_fallback_done>
X<_fallback_done> is to set an inner state variable, to mark
when fallback is finished, and the widest config level has been reached. 

=item B<_fallback_state>
X<_fallback_state> is to decide if we need to fall back to a wider config level.
It uses C<fallback_order> config variable from F<m6-app-config.yml>.
When fallback has not been finished yet, it returns the next level, as it is
configured by C<fallback_order>. Otherwise, it returns 0.

=item B<_select_yml_file>
X<_select_yml_files> is to decide which config file to read, based on the
actual fallback state, given by B<fallback_state>.

It expects three variables configured in F<m6-app-config.yml>:
C<config_directory>: path to the main level configuration files
C<config_extension>: extension of config files, eg.: 'yml'
C<default_config>: it identifies the widest config file, eg.: 'default.yml'

=back

=head1 VERSION

Version 0.05

=head1 AUTHOR

Laszlo Bogardi, C<< <laszlo at ams-ix.net> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Amsterdam Internet Exchange.

=cut

