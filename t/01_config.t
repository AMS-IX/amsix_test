#!/usr/bin/env perl

use Test::Spec;
use Test::Exception;

use M6::App::Config;

my $app         ='m6-autoprovision';
my $site        = 'NL';
my $main_config = './t/m6-app-config/m6-app-config.yml';

describe 'new' => sub {
    it 'should create object' => sub {
        my $cfg = M6::App::Config->new($app, $site, $main_config);

        is ref $cfg, 'M6::App::Config';
    };

    it 'should die if application config does not exists in site dir' => sub {
        throws_ok
            sub { M6::App::Config->new('app', $site, $main_config) },
            qr/\'\.\/t\/m6-app-config\/NL\/app\.yml\' not found/;
    };

    it 'should die if application config does not exists in default dir' => sub {
        my $test_path = "'./t/m6-app-config/DEFAULT/app.yml'";
        throws_ok
            sub { M6::App::Config->new('app', undef, $main_config) },
            qr/$test_path not found/;
    };

    it 'should die if main_config does not exists' => sub {
        throws_ok
            sub { M6::App::Config->new($app, $site, 'fds') },
            qr/'fds' does not exists/;
    };
};

describe 'get from site' => sub {
    my $cfg;

    before all => sub {
        $cfg = M6::App::Config->new($app, $site, $main_config);
    };

    for my $key (qw/site_app site_default default_app default_default default/) {
        it "should return $key value" => sub {
            is $cfg->get($key), $key;
        }
    }

    it 'should return value via accessor' => sub {
        is $cfg->get_only_site_app, 'only_site_app';
    }
};

describe 'get from default site' => sub {
    my $cfg;

    before all => sub {
        $cfg = M6::App::Config->new($app, undef, $main_config);
    };

    for my $key (qw/default_app default_default default/) {
        it "should return $key value" => sub {
            is $cfg->get($key), $key;
        }
    }

    it 'should die if key not found' => sub {
        throws_ok
            sub { $cfg->get('only_site_app') },
            qr/config key 'only_site_app' not found/;
    };
};

describe 'get_all' => sub {
    it 'should return all config' => sub {
        is_deeply(
            scalar M6::App::Config->get_all('test-application', 'NL', $main_config),
            {
                # from root default config
                sudo_most_default => '/usr/bin/sudo_most_def',
                default           => 'default',

                # from default site default config
                default_app     => 'default_default',
                default_default => 'default_default',

                # from site default config
                sudo_default => '/usr/bin/sudo_def',
                foo          => 'default_bar',
                sudo         => '/usr/bin/sudo',
                ndisc_header => '/usr/bin/ndisc6',
                ping_header  => '$sudo /bin/ping',
                site_app     => 'site_default',
                site_default => 'site_default',

                # from site app config
                key => 'value',
                foo => 'bar',
            },
        );
    };
};

runtests unless caller;
