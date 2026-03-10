/**
 * Accounts Management JavaScript
 * Handles user CRUD operations
 */

// Modal functions
function openModal() {
  document.getElementById('userModal').classList.remove('hidden');
  document.getElementById('modalTitle').textContent = 'Novo Usuário';
  document.getElementById('userForm').reset();
  document.getElementById('userId').value = '';

  // Make password required for new users
  document.getElementById('userPassword').setAttribute('required', 'required');
  document.getElementById('userPassword').placeholder = '••••••••';
}

function closeModal() {
  document.getElementById('userModal').classList.add('hidden');
}

function editUser(userId) {
  // Load user data from server
  $.ajax({
    url: '/accounts/get/' + userId,
    method: 'GET',
    success: function(user) {
      document.getElementById('userModal').classList.remove('hidden');
      document.getElementById('modalTitle').textContent = 'Editar Usuário';
      document.getElementById('userId').value = user.id;
      document.getElementById('userName').value = user.name;
      document.getElementById('userEmail').value = user.email;
      document.getElementById('userStatus').value = user.active;

      // Make password optional for editing
      document.getElementById('userPassword').removeAttribute('required');
      document.getElementById('userPassword').placeholder = 'Deixe em branco para manter a senha atual';
    },
    error: function(xhr) {
      var errorMsg = xhr.responseJSON?.error || 'Erro ao carregar dados do usuário';
      alert(errorMsg);
    }
  });
}

function submitUser(event) {
  event.preventDefault();
  const formData = new FormData(event.target);
  const userId = document.getElementById('userId').value;

  // Convert FormData to object
  const data = Object.fromEntries(formData);

  // Remove password from data if it's empty (for edit mode)
  if (userId && !data.password) {
    delete data.password;
  }

  $.ajax({
    url: userId ? '/accounts/update/' + userId : '/accounts/create',
    method: 'POST',
    data: data,
    success: function(response) {
      alert(response.message || 'Usuário salvo com sucesso!');
      closeModal();
      location.reload();
    },
    error: function(xhr) {
      var errorMsg = xhr.responseJSON?.error || 'Erro ao salvar usuário';
      alert(errorMsg);
    }
  });
}

// Delete functions
let userToDelete = null;

function deleteUser(userId, userName) {
  userToDelete = userId;
  document.getElementById('deleteUserName').textContent = userName;
  document.getElementById('deleteModal').classList.remove('hidden');
}

function closeDeleteModal() {
  document.getElementById('deleteModal').classList.add('hidden');
  userToDelete = null;
}

function confirmDelete() {
  if (userToDelete) {
    $.ajax({
      url: '/accounts/delete/' + userToDelete,
      method: 'POST',
      success: function(response) {
        alert(response.message || 'Usuário excluído com sucesso!');
        closeDeleteModal();
        location.reload();
      },
      error: function(xhr) {
        var errorMsg = xhr.responseJSON?.error || 'Erro ao excluir usuário';
        alert(errorMsg);
        closeDeleteModal();
      }
    });
  }
}

// Search functionality
document.addEventListener('DOMContentLoaded', function() {
  const searchInput = document.getElementById('searchInput');

  if (searchInput) {
    searchInput.addEventListener('input', function(e) {
      const searchTerm = e.target.value.toLowerCase();
      const rows = document.querySelectorAll('.user-row');

      rows.forEach(row => {
        const name = row.getAttribute('data-user-name').toLowerCase();
        const email = row.getAttribute('data-user-email').toLowerCase();

        if (name.includes(searchTerm) || email.includes(searchTerm)) {
          row.style.display = '';
        } else {
          row.style.display = 'none';
        }
      });
    });
  }

  // Close modal when clicking outside
  window.onclick = function(event) {
    const userModal = document.getElementById('userModal');
    const deleteModal = document.getElementById('deleteModal');

    if (event.target === userModal) {
      closeModal();
    }
    if (event.target === deleteModal) {
      closeDeleteModal();
    }
  }
});
