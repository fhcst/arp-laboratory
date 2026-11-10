<?php
session_start();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $user = $_POST['username'] ?? null;
    $password = $_POST['password'] ?? null;
    if (!is_string($user) || !is_string($password)
        || !hash_equals((string) getenv('LAB_WEB_USER'), $user)
        || !hash_equals((string) getenv('LAB_WEB_PASSWORD'), $password)) {
        http_response_code(403);
        exit('Login failed');
    }

    session_regenerate_id(true);
    $_SESSION = ['admin' => $user, 'actions' => 0];
    header('Location: /admin/panel.php', true, 303);
    exit;
}
?>
<!doctype html>
<html lang="zh-Hant">
<meta charset="utf-8">
<title>管理員登入</title>
<h1>管理員登入</h1>
<form method="post">
    <label>帳號 <input name="username" autocomplete="username" required></label>
    <label>密碼 <input name="password" type="password" autocomplete="current-password" required></label>
    <button>登入</button>
</form>
</html>
