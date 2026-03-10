package LifeDashboard;
use Dancer2;
use Crypt::Argon2 qw(argon2id_verify);
use Dancer2::Plugin::Database;

our $VERSION = '0.1';

post '/login' => sub {

    my $user = body_parameters->get('user');
    my $pass = body_parameters->get('password');

    my $dbh = database;

    my $sth = $dbh->prepare(
        "SELECT id, hash FROM accounts WHERE username = ?"
    );

    $sth->execute($user);

    my $row = $sth->fetchrow_hashref;


    return redirect '/login?error=1' unless $row;

    my $hash = $row->{password_hash};

    use Crypt::Argon2 qw(argon2id_verify);

    my $ok = argon2id_verify($hash, $pass);

    return redirect '/login?error=1' unless $ok;


    app->change_session_id;

    session user_id => $row->{id};

    redirect '/dashboard';
};


get '/accounts/account' => sub {

    template 'accounts/account' => { 'title' => 'LifeDashboard' };

};



true;
