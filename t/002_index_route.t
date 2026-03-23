use strict;
use warnings;

use LifeDashboard;
use Test::More tests => 5;
use Plack::Test;
use HTTP::Request::Common;
use Ref::Util qw<is_coderef>;

my $app = LifeDashboard->to_app;
ok( is_coderef($app), 'Got app' );

my $test = Plack::Test->create($app);
my $res  = $test->request( GET '/' );

is( $res->code, 302, '[GET /] redirects when not authenticated' );
is( $res->header('Location'), '/login', '[GET /] redirects to /login' );

my $login_res = $test->request( GET '/login' );

ok( $login_res->is_success, '[GET /login] successful' );
like( $login_res->content, qr/Entrar no painel/, '[GET /login] renders login screen' );
