from flask import Flask, request, render_template_string, redirect, url_for

app = Flask(__name__)

# In-memory data store (id -> user dict)
users = {}
next_id = 1

# HTML template with basic CRUD interface
template = """
<!doctype html>
<title>User Management</title>
<h1>User List</h1>
<ul>
  {% for uid, user in users.items() %}
    <li>{{ user['name'] }} ({{ user['email'] }})
        <a href="/edit/{{ uid }}">Edit</a>
        <a href="/delete/{{ uid }}">Delete</a>
    </li>
  {% endfor %}
</ul>
<h2>Add New User</h2>
<form method="post" action="/add">
  Name: <input type="text" name="name" required><br>
  Email: <input type="email" name="email" required><br>
  <input type="submit" value="Add User">
</form>
{% if editing %}
<h2>Edit User</h2>
<form method="post" action="/update/{{ edit_id }}">
  Name: <input type="text" name="name" value="{{ edit_user['name'] }}" required><br>
  Email: <input type="email" name="email" value="{{ edit_user['email'] }}" required><br>
  <input type="submit" value="Update User">
</form>
{% endif %}
"""

@app.route('/')
def index():
    return render_template_string(template, users=users, editing=False)

@app.route('/add', methods=['POST'])
def add():
    global next_id
    name = request.form['name']
    email = request.form['email']
    users[next_id] = {'name': name, 'email': email}
    next_id += 1
    return redirect(url_for('index'))

@app.route('/edit/<int:user_id>')
def edit(user_id):
    user = users.get(user_id)
    if not user:
        return "User not found", 404
    return render_template_string(template, users=users, editing=True, edit_user=user, edit_id=user_id)

@app.route('/update/<int:user_id>', methods=['POST'])
def update(user_id):
    if user_id not in users:
        return "User not found", 404
    users[user_id]['name'] = request.form['name']
    users[user_id]['email'] = request.form['email']
    return redirect(url_for('index'))

@app.route('/delete/<int:user_id>')
def delete(user_id):
    users.pop(user_id, None)
    return redirect(url_for('index'))

if __name__ == '__main__':
    app.run(debug=True, port=5000)
