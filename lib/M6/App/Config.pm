package M6::App::Config;

=encoding utf-8

=head1 NAME

M6::App::Config - hierarchical, centralised configurations for Perl

=head1 SYNOPSIS

    use M6::App::Config;

    # Read a configuration for application 'm6-autoprovision'
    my $cfg = M6::App::Config->new( 'm6-autoprovision', 'NL' );

    # Get a value of a configuration key
    my $ping_header = $cfg->get( 'ping_header' );

    # Same thing but with nice syntactic sugar
    $ping_header = $cfg->get_ping_header;

    # Get all configuration (as a HASHREF) for specified application and site
    my $config = M6::App::Config->get_all( 'm6-autoprovision', 'NL' );

=head1 DESCRIPTION

C<M6::App::Config> class aims at centralising configuration values
used by AMS-IX's platform software (provisioning, monitoring, etc.).

=head1 CONFIGURATION

=head2 Main configuration

This module expects main configuration file. Default path for this file is
C</etc/m6-app-config/m6-app-config.yml>. You can change that path by using
C<main_config_file> parametr in constructor.

In main configuration file expeted next variables:

=over

=item config_extension

Extension for all application configuration files.

=item config_directory

Directory containing call configuration files.

=item default_config

File name (without extension) of default configuration files.
Default configuration files can exists in root of C<config_directory>, in
site default folder and in site folder. Default configuration files readed
before application configuration files.

=item fallback_order

Order in wich configuration files are readed. Default order is
C<default, site-default, site>.

If list of configuration files looks like this:

    DEFAULT/default.yml
    DEFAULT/some-app.yml
    NL/default.yml
    NL/some-app.yml
    default.yml

Then with default fallback_order this module will read files in this order:

    1. default.yml
    2. DEFAULT/default.yml
    4. DEFAULT/some-app.yml
    5. NL/default.yml
    6. NL/some-app.yml

If fallback_order is C<site-default, default, site>, then order of reading
configuration files will be this:

    1. DEFAULT/default.yml
    2. DEFAULT/some-app.yml
    3. default.yml
    4. NL/default.yml
    5. NL/some-app.yml

=back

=head2 Application configuration

All applications configuration file should be placed in specified order.
For example for application C<some-app> we should create atleas one of this
files:

    DEFAULT/default.yml
    DEFAULT/some-app.yml
    NL/default.yml
    NL/some-app.yml
    default.yml

Or all of them. Order of reading this files specified by C<fallback_order> (read
about C<fallback_order> in paragraph "Main configuration").

This module expects several variables defined in F<m6-app-config.yml>
More details description can be found in the description for each subroutine.

=cut

use Modern::Perl;
use YAML::AppConfig;
use Carp qw/confess/;
use Moo;
use strictures 2;
use namespace::clean;

our $VERSION      = '0.08';
our $DEFAULT_SITE = 'DEFAULT';

=head1 CONSTRUCTOR

=head2 new

    M6::App::Config->new(
        $app,
        $site,
        $main_config_file,
        $yaml_lib,
    );

=over

=item C<$app>

Name of application, wich configuration we are going to read.

Required atribute.

=item C<$site>

Site name of exchange (eg. NL, CHI, etc.).

Default site is 'DEFAULT'.

Can be overwriten in main configuration file.

=item C<$main_config_file>

Path to main config file.

Default path is '/etc/m6-app-config/m6-app-config.yml'.

=item C<$yaml_lib>

Lib that should be used for parsing YAML files.

Default is 'YAML::XS'.

=back

=cut

has app => (
    is       => 'ro',
    required => 1,
    isa      => sub { confess 'should not be empty' if !$_[0] },
);

has site => (
    is  => 'ro',
    isa => sub { confess 'should not be empty' if !$_[0] },
);

has main_config_file => (
    is      => 'ro',
    default => sub { '/etc/m6-app-config/m6-app-config.yml' },
    isa     => sub { confess "'$_[0]' does not exists" if !-e $_[0] },
);

has yaml_lib => (
    is      => 'ro',
    default => sub { 'YAML::XS' },
    isa     => sub {
        my $class = $_[0];

        confess 'should not be empty' if !$class;

        # Check that we can load module
        eval "
            require YAML::Syck;
            1;
        " or do {
            confess "can't load yaml lib '$class' with error: $@";
        };
    },
);

=head1 PUBLIC METHODS

=head2 get

    $cfg->get('logdir');

Return value for key.
If there is no such key - dies with error.

=head2 get_*

    $cfg->get_logdir;

Syncax shugar around C<get>.
Return value for key (key is a part of method name).
If there is no such key - dies with error.

=cut

sub get {
    my ( $self, $key ) = @_;

    my $val = $self->_app_config->get( $key )
        or confess "config key '$key' not found";

    return $val;
}

=head2 get_all

Return value for key.
If there is no such key - dies with error.

=cut

sub get_all {
    my ( $class, @params ) = @_;

    my $cfg = $class->new( @params );

    my $app_config = $cfg->_app_config->config;

    return wantarray ? %$app_config : $app_config;
}

=head1 PRIVAT METHODS

=cut

has _config_extension => (
    is      => 'rwp',
    default => sub { 'yml' },
    isa     => sub { confess 'should not be empty' if !$_[0] },
);

has _config_directory => (
    is      => 'rwp',
    default => sub { 'yml' },
    isa     => sub { confess 'should not be empty' if !$_[0] },
);

has _default_config => (
    is      => 'rwp',
    default => sub { 'default' },
    isa     => sub { confess 'should not be empty' if !$_[0] },
);

has _fallback_order => (
    is      => 'rwp',
    default => sub { [qw/default site-default site/] },
);

has _app_config => (
    is => 'rwp',
);

=head2 BUILDARGS

Convert positional params of constructor to HASHREF required by Moo.

=cut

sub BUILDARGS {
    my ( $self, $app, $site, $main_config_file, $yaml_lib ) = @_;

    my $args = {};

    $args->{app} = $app
        if defined $app;

    $args->{site} = $site
        if defined $site;

    $args->{main_config_file} = $main_config_file
        if defined $main_config_file;

    $args->{yaml_lib} = $yaml_lib
        if defined $yaml_lib;

    return $args;
}

=head2 BUILD

Read main and application configurations and create accessors
to configuration's keys.

=cut

sub BUILD {
    my ( $self, $args ) = @_;

    $self->_read_main_config;

    $self->_read_app_config;

    $self->_make_accessors_to_config_keys;
}

=head2 _read_main_config

Read main configuration and use variables from it to set object property.

=cut

sub _read_main_config {
    my ( $self ) = @_;

    # read main configuration
    my $main_config = YAML::AppConfig->new(
        file       => $self->main_config_file,
        yaml_class => $self->yaml_lib,
    );

    # use variables from config to set object property
    my @main_config_keys = qw/
        config_extension
        config_directory
        default_config
        fallback_order
    /;

    for my $main_config_key ( @main_config_keys ) {
        my $setter_name = "_set__$main_config_key";
        $self->$setter_name( $main_config->get( $main_config_key ) );
    }
}

=head2 _read_app_config

Read all application configuration files, and create C<YAML::AppConfig> object
from them for futher usage.

=cut

sub _read_app_config {
    my ( $self ) = @_;

    my $cfg = YAML::AppConfig->new(
        yaml_class => $self->yaml_lib,
    );

    for my $file ( $self->_build_paths_to_app_config_files ) {
        $cfg->merge( file => $file );
    }

    $self->_set__app_config( $cfg );
}

=head2 _build_paths_to_app_config_files

Return paths to all needed and exists configuraion files. Order of files defined by
C<falback_order>.

=cut

sub _build_paths_to_app_config_files {
    my ( $self ) = @_;

    my @possible_files;

    my $use_default_site = $self->site ? 0 : 1;

    # use fallback_order to defined in what order should we read config files
    for my $fallback_type ( @{$self->_fallback_order} ) {
        if ( $fallback_type eq 'default' ) {
            my $config_file =
                $self->_config_directory
                . '/'
                . $self->_default_config
                . '.'
                . $self->_config_extension;

            push @possible_files, $config_file,
        }
        elsif (
            $fallback_type eq 'site-default'
            || $fallback_type eq 'site'
        ) {
            my $is_site_fallback = $fallback_type eq 'site';

            # skip site config if we are using default sit
            next
                if $is_site_fallback
                && $use_default_site;

            my $config_files_dir =
                $self->_config_directory
                . '/'
                . ( $is_site_fallback ? $self->site : $DEFAULT_SITE )
                . '/';
            my $default_file_in_dir =
                $config_files_dir
                . $self->_default_config
                . '.'
                . $self->_config_extension;
            my $app_config_file_in_dir =
                $config_files_dir
                . $self->app
                . '.'
                . $self->_config_extension;

            # Application config should exists. If we use default site
            # then it should exists in default site dir. If we use not default
            # site then it should exists in site dir. Die if it not exists.
            if (
                (
                    $is_site_fallback && !$use_default_site
                    || !$is_site_fallback && $use_default_site
                )
                && !-e $app_config_file_in_dir
            ) {
                confess "'$app_config_file_in_dir' not found";
            }

            push @possible_files,
                $default_file_in_dir,
                $app_config_file_in_dir;
        }
        else {
            confess "unsupported fallback type '$fallback_type'";
        }
    }

    # keep only files that really exists
    my @files = grep { -e $_ } @possible_files;

    return @files;
}

=head2 _make_accessors_to_config_keys

Make accessors to configuration keys.

=cut

sub _make_accessors_to_config_keys {
    my ( $self ) = @_;

    for my $key ($self->_app_config->config_keys) {
        next
            if !$key
            || $key !~ /^[a-zA-Z_]\w*$/;

        no strict 'refs';
        no warnings 'redefine';
        my $method_name = ref($self) . "::get_$key";
        *{$method_name} = sub { $_[0]->_app_config->get($key, $_[1]) };
    }
}

=head1 VERSION

Version 0.08

=head1 AUTHOR

Laszlo Bogardi, <<laszlo.bogardi@ams-ix.net>>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Amsterdam Internet Exchange.

=cut

1;
