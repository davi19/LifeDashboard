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
    my $dbh = database;

    my $sth = $dbh->prepare(
        "SELECT id, username, name, email, active, created_at
         FROM accounts
         ORDER BY created_at DESC"
    );

    $sth->execute();

    my @users;
    while (my $row = $sth->fetchrow_hashref) {
        push @users, $row;
    }

    template 'accounts/account' => {
        'title' => 'Gerenciamento de Usuários',
        'users' => \@users
    };
};

# Get single user data
get '/accounts/get/:id' => sub {
    my $id = route_parameters->get('id');
    my $dbh = database;

    my $sth = $dbh->prepare(
        "SELECT id, username, name, email, active
         FROM accounts
         WHERE id = ?"
    );

    $sth->execute($id);
    my $user = $sth->fetchrow_hashref;

    if ($user) {
        content_type 'application/json';
        return to_json($user);
    } else {
        status 404;
        return to_json({ error => 'Usuário não encontrado' });
    }
};

# Create new user
post '/accounts/create' => sub {
    my $name = body_parameters->get('name');
    my $email = body_parameters->get('email');
    my $password = body_parameters->get('password');
    my $active = body_parameters->get('active') // 1;
    my $username = body_parameters->get('username') // $email;

    # Validate required fields
    unless ($name && $email && $password) {
        status 400;
        content_type 'application/json';
        return to_json({ error => 'Nome, email e senha são obrigatórios' });
    }

    my $dbh = database;

    # Check if email already exists
    my $check_sth = $dbh->prepare("SELECT id FROM accounts WHERE email = ?");
    $check_sth->execute($email);
    if ($check_sth->fetchrow_hashref) {
        status 400;
        content_type 'application/json';
        return to_json({ error => 'Email já cadastrado' });
    }

    # Hash password
    use Crypt::Argon2 qw(argon2id_pass);
    my $hash = argon2id_pass($password, random_string(16), 3, '32M');

    # Insert user
    my $sth = $dbh->prepare(
        "INSERT INTO accounts (username, name, email, password_hash, active, created_at)
         VALUES (?, ?, ?, ?, ?, datetime('now'))"
    );

    eval {
        $sth->execute($username, $name, $email, $hash, $active);
    };

    if ($@) {
        status 500;
        content_type 'application/json';
        return to_json({ error => 'Erro ao criar usuário: ' . $@ });
    }

    content_type 'application/json';
    return to_json({
        success => 1,
        message => 'Usuário criado com sucesso',
        id => $dbh->last_insert_id(undef, undef, 'accounts', 'id')
    });
};

# Update user
post '/accounts/update/:id' => sub {
    my $id = route_parameters->get('id');
    my $name = body_parameters->get('name');
    my $email = body_parameters->get('email');
    my $password = body_parameters->get('password');
    my $active = body_parameters->get('active');
    my $username = body_parameters->get('username');

    my $dbh = database;

    # Check if user exists
    my $check_sth = $dbh->prepare("SELECT id FROM accounts WHERE id = ?");
    $check_sth->execute($id);
    unless ($check_sth->fetchrow_hashref) {
        status 404;
        content_type 'application/json';
        return to_json({ error => 'Usuário não encontrado' });
    }

    # Build update query dynamically based on provided fields
    my @fields;
    my @values;

    if (defined $name && $name ne '') {
        push @fields, "name = ?";
        push @values, $name;
    }

    if (defined $email && $email ne '') {
        push @fields, "email = ?";
        push @values, $email;
    }

    if (defined $username && $username ne '') {
        push @fields, "username = ?";
        push @values, $username;
    }

    if (defined $active && $active ne '') {
        push @fields, "active = ?";
        push @values, $active;
    }

    if (defined $password && $password ne '') {
        use Crypt::Argon2 qw(argon2id_pass);
        my $hash = argon2id_pass($password, random_string(16), 3, '32M');
        push @fields, "password_hash = ?";
        push @values, $hash;
    }

    unless (@fields) {
        status 400;
        content_type 'application/json';
        return to_json({ error => 'Nenhum campo para atualizar' });
    }

    push @values, $id;

    my $sql = "UPDATE accounts SET " . join(', ', @fields) . " WHERE id = ?";
    my $sth = $dbh->prepare($sql);

    eval {
        $sth->execute(@values);
    };

    if ($@) {
        status 500;
        content_type 'application/json';
        return to_json({ error => 'Erro ao atualizar usuário: ' . $@ });
    }

    content_type 'application/json';
    return to_json({ success => 1, message => 'Usuário atualizado com sucesso' });
};

# Delete user
post '/accounts/delete/:id' => sub {
    my $id = route_parameters->get('id');
    my $dbh = database;

    # Check if user exists
    my $check_sth = $dbh->prepare("SELECT id FROM accounts WHERE id = ?");
    $check_sth->execute($id);
    unless ($check_sth->fetchrow_hashref) {
        status 404;
        content_type 'application/json';
        return to_json({ error => 'Usuário não encontrado' });
    }

    # Prevent deleting the current logged user
    my $current_user_id = session('user_id');
    if (defined $current_user_id && $current_user_id == $id) {
        status 400;
        content_type 'application/json';
        return to_json({ error => 'Você não pode excluir seu próprio usuário' });
    }

    my $sth = $dbh->prepare("DELETE FROM accounts WHERE id = ?");

    eval {
        $sth->execute($id);
    };

    if ($@) {
        status 500;
        content_type 'application/json';
        return to_json({ error => 'Erro ao excluir usuário: ' . $@ });
    }

    content_type 'application/json';
    return to_json({ success => 1, message => 'Usuário excluído com sucesso' });
};

# Helper function to generate random string
sub random_string {
    my $length = shift || 16;
    my @chars = ('A'..'Z', 'a'..'z', '0'..'9');
    my $string = '';
    $string .= $chars[rand @chars] for 1..$length;
    return $string;
}



true;
