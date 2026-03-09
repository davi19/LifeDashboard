package LifeDashboard;
use Dancer2;

our $VERSION = '0.1';

get '/' => sub {
    template 'login' => { 'title' => 'LifeDashboard' };
};



true;
