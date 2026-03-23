package LifeDashboard;
use Dancer2;
use lib 'lib';
use Accounts;

our $VERSION = '0.1';

get '/' => sub {
    return redirect(session('user_id') ? '/dashboard' : '/login');
};



true;
