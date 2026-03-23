let userToDelete = null;

function openModal() {
  const form = document.getElementById('userForm');
  document.getElementById('userModal').classList.remove('hidden');
  document.getElementById('modalTitle').textContent = 'New user';
  document.getElementById('userId').value = '';
  form.reset();

  const passwordInput = document.getElementById('userPassword');
  passwordInput.setAttribute('required', 'required');
  passwordInput.placeholder = 'Set a password';

  document.getElementById('passwordHint').textContent = 'Password is required for new users.';
}

function closeModal() {
  document.getElementById('userModal').classList.add('hidden');
}

async function editUser(userId) {
  try {
    const response = await fetch('/accounts/get/' + userId, {
      headers: { Accept: 'application/json' }
    });

    const payload = await response.json();
    if (!response.ok) {
      throw new Error(payload.error || 'Failed to load user');
    }

    document.getElementById('userModal').classList.remove('hidden');
    document.getElementById('modalTitle').textContent = 'Edit user';
    document.getElementById('userId').value = payload.id;
    document.getElementById('userName').value = payload.name || '';
    document.getElementById('userStatus').value = String(payload.active ? 1 : 0);
    document.getElementById('userPassword').value = '';
    document.getElementById('userPassword').removeAttribute('required');
    document.getElementById('userPassword').placeholder = 'Fill this only if you want to change the password';
    document.getElementById('passwordHint').textContent = 'Leave it empty to keep the current password.';
  } catch (error) {
    showFeedback(error.message, 'error');
  }
}

async function submitUser(event) {
  event.preventDefault();

  const userId = document.getElementById('userId').value;
  const data = new URLSearchParams();
  data.set('name', document.getElementById('userName').value.trim());
  data.set('active', document.getElementById('userStatus').value);

  const password = document.getElementById('userPassword').value;
  if (password) {
    data.set('password', password);
  }

  if (!userId && !password) {
    showFeedback('Set a password to create the user.', 'error');
    return;
  }

  try {
    const response = await fetch(userId ? '/accounts/update/' + userId : '/accounts/create', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        Accept: 'application/json'
      },
      body: data.toString()
    });

    const payload = await response.json();
    if (!response.ok) {
      throw new Error(payload.error || 'Failed to save user');
    }

    closeModal();

    if (userId) {
      updateUserRow(payload.user);
    } else {
      prependUserRow(payload.user);
    }

    showFeedback(payload.message || 'User saved successfully.', 'success');
  } catch (error) {
    showFeedback(error.message, 'error');
  }
}

function deleteUser(userId, userName) {
  userToDelete = userId;
  document.getElementById('deleteUserName').textContent = userName;
  document.getElementById('deleteModal').classList.remove('hidden');
}

function closeDeleteModal() {
  userToDelete = null;
  document.getElementById('deleteModal').classList.add('hidden');
}

async function confirmDelete() {
  if (!userToDelete) {
    return;
  }

  try {
    const response = await fetch('/accounts/delete/' + userToDelete, {
      method: 'POST',
      headers: { Accept: 'application/json' }
    });

    const payload = await response.json();
    if (!response.ok) {
      throw new Error(payload.error || 'Failed to delete user');
    }

    const row = document.getElementById('user-row-' + userToDelete);
    if (row) {
      row.remove();
    }

    ensureEmptyState();
    closeDeleteModal();
    showFeedback(payload.message || 'User deleted successfully.', 'success');
  } catch (error) {
    closeDeleteModal();
    showFeedback(error.message, 'error');
  }
}

function updateUserRow(user) {
  const row = document.getElementById('user-row-' + user.id);
  if (!row) {
    prependUserRow(user);
    return;
  }

  const nextRow = buildUserRow(user);
  row.replaceWith(nextRow);
}

function prependUserRow(user) {
  const tbody = document.getElementById('usersTableBody');
  const emptyState = document.getElementById('emptyState');
  if (emptyState) {
    emptyState.remove();
  }

  tbody.prepend(buildUserRow(user));
}

function buildUserRow(user) {
  const currentUserId = document.getElementById('accountsPage')?.dataset.currentUserId;
  const canDelete = String(user.id) !== String(currentUserId);
  const row = document.createElement('tr');
  row.id = 'user-row-' + user.id;
  row.className = 'user-row transition hover:bg-slate-50';
  row.dataset.userId = user.id;
  row.dataset.userName = user.name;
  row.dataset.userActive = user.active ? '1' : '0';

  const statusClass = user.active
    ? 'inline-flex rounded-full bg-emerald-100 px-3 py-1 text-xs font-semibold text-emerald-700'
    : 'inline-flex rounded-full bg-slate-200 px-3 py-1 text-xs font-semibold text-slate-600';
  const statusLabel = user.active ? 'Active' : 'Inactive';
  const initial = user.initial || (user.name || '?').slice(0, 1).toUpperCase();

  const deleteButton = canDelete ? `
        <button
          type="button"
          onclick="deleteUser(${user.id}, '${escapeJs(user.name)}')"
          class="rounded-xl border border-rose-200 px-3 py-2 text-xs font-semibold uppercase tracking-[0.2em] text-rose-600 transition hover:bg-rose-50"
        >
          Delete
        </button>
  ` : '';

  row.innerHTML = `
    <td class="px-6 py-5">
      <div class="flex items-center gap-4">
        <div class="flex h-11 w-11 items-center justify-center rounded-2xl bg-slate-950 text-sm font-bold text-white">${escapeHtml(initial)}</div>
        <div>
          <p class="text-sm font-semibold text-slate-900">${escapeHtml(user.name)}</p>
          <p class="text-xs uppercase tracking-[0.22em] text-slate-400">Internal account</p>
        </div>
      </div>
    </td>
    <td class="px-6 py-5 text-sm text-slate-500">#${user.id}</td>
    <td class="px-6 py-5">
      <span class="${statusClass}">${statusLabel}</span>
    </td>
    <td class="px-6 py-5">
      <div class="flex justify-end gap-3">
        <button
          type="button"
          onclick="editUser(${user.id})"
          class="rounded-xl border border-slate-200 px-3 py-2 text-xs font-semibold uppercase tracking-[0.2em] text-slate-600 transition hover:border-cyan-500 hover:text-cyan-600"
        >
          Edit
        </button>
        ${deleteButton}
      </div>
    </td>
  `;

  return row;
}

function ensureEmptyState() {
  const tbody = document.getElementById('usersTableBody');
  const rows = tbody.querySelectorAll('.user-row');

  if (rows.length > 0 || document.getElementById('emptyState')) {
    return;
  }

  const empty = document.createElement('tr');
  empty.id = 'emptyState';
  empty.innerHTML = '<td colspan="4" class="px-6 py-12 text-center text-sm text-slate-500">No users found.</td>';
  tbody.appendChild(empty);
}

function showFeedback(message, type) {
  const feedback = document.getElementById('feedback');
  feedback.textContent = message;
  feedback.classList.remove('hidden', 'bg-emerald-50', 'text-emerald-700', 'border', 'border-emerald-200', 'bg-rose-50', 'text-rose-700', 'border-rose-200');

  if (type === 'success') {
    feedback.classList.add('border', 'border-emerald-200', 'bg-emerald-50', 'text-emerald-700');
  } else {
    feedback.classList.add('border', 'border-rose-200', 'bg-rose-50', 'text-rose-700');
  }

  clearTimeout(showFeedback.timeoutId);
  showFeedback.timeoutId = window.setTimeout(() => {
    feedback.classList.add('hidden');
  }, 5000);
}

function escapeHtml(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

function escapeJs(value) {
  return String(value).replaceAll('\\', '\\\\').replaceAll("'", "\\'");
}

document.addEventListener('DOMContentLoaded', () => {
  document.getElementById('userForm')?.addEventListener('submit', submitUser);

  const searchInput = document.getElementById('searchInput');
  if (searchInput) {
    searchInput.addEventListener('input', event => {
      const term = event.target.value.trim().toLowerCase();
      const rows = document.querySelectorAll('.user-row');

      rows.forEach(row => {
        const name = (row.dataset.userName || '').toLowerCase();
        row.style.display = !term || name.includes(term) ? '' : 'none';
      });
    });
  }

  window.addEventListener('click', event => {
    const userModal = document.getElementById('userModal');
    const deleteModal = document.getElementById('deleteModal');

    if (event.target === userModal) {
      closeModal();
    }

    if (event.target === deleteModal) {
      closeDeleteModal();
    }
  });
});
