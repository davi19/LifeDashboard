package Accounts;
use Dancer2 appname => 'LifeDashboard';
use Dancer2::Plugin::Database;
use Crypt::Argon2 qw(argon2id_pass);

our $VERSION = '0.1';

get '/login' => sub {
    return redirect '/dashboard' if session('user_id');

    my $error = query_parameters->get('error') || '';
    my %messages = (
        missing  => 'Informe usuario e senha.',
        inactive => 'Seu usuario esta inativo.',
        invalid  => 'Usuario ou senha invalidos.',
    );

    template 'login' => {
        title         => 'LifeDashboard | Login',
        error_message => $messages{$error} || '',
    };
};

post '/login' => sub {
    my $user = body_parameters->get('user');
    my $pass = body_parameters->get('password');

    return redirect '/login?error=missing' unless defined $user && defined $pass;

    my $dbh = database;
    my $sth = $dbh->prepare(
        'SELECT id, name, password, salt, active FROM accounts WHERE name = ?'
    );

    $sth->execute($user);
    my $row = $sth->fetchrow_hashref;

    return redirect '/login?error=invalid' unless $row;
    return redirect '/login?error=inactive' unless $row->{active};

    my $generated_hash = argon2id_pass($pass, $row->{salt}, 3, '32M');
    return redirect '/login?error=invalid' unless $generated_hash eq $row->{password};

    app->change_session_id;
    session user_id => $row->{id};
    session user_name => $row->{name};

    return redirect '/dashboard';
};

get '/logout' => sub {
    app->destroy_session;
    redirect '/login';
};

get '/dashboard' => sub {
    return redirect '/login' unless _require_web_auth();
    redirect '/accounts/account';
};

get '/accounts/account' => sub {
    return redirect '/login' unless _require_web_auth();

    my $dbh = database;
    my $sth = $dbh->prepare(
        'SELECT id, name, active FROM accounts ORDER BY id DESC'
    );

    $sth->execute();

    my @users;
    my $current_user_id = session('user_id');
    while (my $row = $sth->fetchrow_hashref) {
        $row->{active}     = $row->{active} ? 1 : 0;
        $row->{initial}    = uc substr(($row->{name} || '?'), 0, 1);
        $row->{can_delete} = $current_user_id && $current_user_id != $row->{id} ? 1 : 0;
        push @users, $row;
    }

    template 'accounts/account' => {
        title             => 'LifeDashboard | Usuarios',
        has_users         => scalar @users,
        users             => \@users,
        current_user_id   => $current_user_id,
        current_user_name => session('user_name') || '',
    };
};

get '/accounts/get/:id' => sub {
    return _json_unauthorized() unless _require_api_auth();

    my $id = route_parameters->get('id');
    my $dbh = database;

    my $sth = $dbh->prepare(
        'SELECT id, name, active FROM accounts WHERE id = ?'
    );

    $sth->execute($id);
    my $user = $sth->fetchrow_hashref;

    unless ($user) {
        status 404;
        content_type 'application/json';
        return to_json({ error => 'Usuario nao encontrado' });
    }

    $user->{active} = $user->{active} ? 1 : 0;

    content_type 'application/json';
    return to_json($user);
};

post '/accounts/create' => sub {
    return _json_unauthorized() unless _require_api_auth();

    my $name     = body_parameters->get('name');
    my $password = body_parameters->get('password');
    my $active   = body_parameters->get('active');
    $active = defined $active ? ($active ? 1 : 0) : 1;

    unless (defined $name && length $name && defined $password && length $password) {
        status 400;
        content_type 'application/json';
        return to_json({ error => 'Nome e senha sao obrigatorios' });
    }

    my $dbh = database;
    my $check_sth = $dbh->prepare('SELECT id FROM accounts WHERE name = ?');
    $check_sth->execute($name);

    if ($check_sth->fetchrow_hashref) {
        status 400;
        content_type 'application/json';
        return to_json({ error => 'Ja existe um usuario com esse nome' });
    }

    my $salt = random_string(16);
    my $hash = argon2id_pass($password, $salt, 3, '32M');

    my $sth = $dbh->prepare(
        'INSERT INTO accounts (name, password, salt, active) VALUES (?, ?, ?, ?)'
    );

    eval { $sth->execute($name, $hash, $salt, $active); };
    if ($@) {
        status 500;
        content_type 'application/json';
        return to_json({ error => 'Erro ao criar usuario' });
    }

    my $id = $dbh->last_insert_id(undef, undef, 'accounts', 'id');

    content_type 'application/json';
    return to_json({
        success => 1,
        message => 'Usuario criado com sucesso',
        user    => {
            id      => $id,
            name    => $name,
            active  => $active,
            initial => uc substr($name, 0, 1),
        },
    });
};

post '/accounts/update/:id' => sub {
    return _json_unauthorized() unless _require_api_auth();

    my $id       = route_parameters->get('id');
    my $name     = body_parameters->get('name');
    my $password = body_parameters->get('password');
    my $active   = body_parameters->get('active');

    my $dbh = database;
    my $check_sth = $dbh->prepare('SELECT id FROM accounts WHERE id = ?');
    $check_sth->execute($id);

    unless ($check_sth->fetchrow_hashref) {
        status 404;
        content_type 'application/json';
        return to_json({ error => 'Usuario nao encontrado' });
    }

    my @fields;
    my @values;

    if (defined $name && length $name) {
        my $duplicate_sth = $dbh->prepare('SELECT id FROM accounts WHERE name = ? AND id <> ?');
        $duplicate_sth->execute($name, $id);

        if ($duplicate_sth->fetchrow_hashref) {
            status 400;
            content_type 'application/json';
            return to_json({ error => 'Ja existe um usuario com esse nome' });
        }

        push @fields, 'name = ?';
        push @values, $name;
    }

    if (defined $active && $active ne '') {
        push @fields, 'active = ?';
        push @values, ($active ? 1 : 0);
    }

    if (defined $password && length $password) {
        my $salt = random_string(16);
        my $hash = argon2id_pass($password, $salt, 3, '32M');
        push @fields, 'password = ?';
        push @values, $hash;
        push @fields, 'salt = ?';
        push @values, $salt;
    }

    unless (@fields) {
        status 400;
        content_type 'application/json';
        return to_json({ error => 'Nenhum campo para atualizar' });
    }

    push @values, $id;

    my $sql = 'UPDATE accounts SET ' . join(', ', @fields) . ' WHERE id = ?';
    my $sth = $dbh->prepare($sql);

    eval { $sth->execute(@values); };
    if ($@) {
        status 500;
        content_type 'application/json';
        return to_json({ error => 'Erro ao atualizar usuario' });
    }

    my $user_sth = $dbh->prepare('SELECT id, name, active FROM accounts WHERE id = ?');
    $user_sth->execute($id);
    my $user = $user_sth->fetchrow_hashref;
    $user->{active}  = $user->{active} ? 1 : 0;
    $user->{initial} = uc substr(($user->{name} || '?'), 0, 1);

    if (session('user_id') && session('user_id') == $id && defined $name && length $name) {
        session user_name => $name;
    }

    content_type 'application/json';
    return to_json({
        success => 1,
        message => 'Usuario atualizado com sucesso',
        user    => $user,
    });
};

post '/accounts/delete/:id' => sub {
    return _json_unauthorized() unless _require_api_auth();

    my $id = route_parameters->get('id');
    my $dbh = database;

    my $check_sth = $dbh->prepare('SELECT id FROM accounts WHERE id = ?');
    $check_sth->execute($id);

    unless ($check_sth->fetchrow_hashref) {
        status 404;
        content_type 'application/json';
        return to_json({ error => 'Usuario nao encontrado' });
    }

    my $current_user_id = session('user_id');
    if (defined $current_user_id && $current_user_id == $id) {
        status 400;
        content_type 'application/json';
        return to_json({ error => 'Voce nao pode excluir seu proprio usuario' });
    }

    my $sth = $dbh->prepare('DELETE FROM accounts WHERE id = ?');
    eval { $sth->execute($id); };

    if ($@) {
        status 500;
        content_type 'application/json';
        return to_json({ error => 'Erro ao excluir usuario' });
    }

    content_type 'application/json';
    return to_json({
        success => 1,
        message => 'Usuario excluido com sucesso',
    });
};

sub _require_web_auth {
    return session('user_id') ? 1 : 0;
}

sub _require_api_auth {
    return session('user_id') ? 1 : 0;
}

sub _json_unauthorized {
    status 401;
    content_type 'application/json';
    return to_json({ error => 'Sessao expirada. Faca login novamente.' });
}

sub random_string {
    my $length = shift || 16;
    my @chars = ('A' .. 'Z', 'a' .. 'z', '0' .. '9');
    my $string = '';
    $string .= $chars[ rand @chars ] for 1 .. $length;
    return $string;
}

true;
