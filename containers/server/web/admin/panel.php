<?php
session_start();

if (!isset($_SESSION['admin'])) {
    header('Location: /admin/login.php', true, 303);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    switch ($_POST['action'] ?? '') {
        case 'increment':
            $_SESSION['actions']++;
            break;
        case 'logout':
            $_SESSION = [];
            session_destroy();
            header('Location: /admin/login.php', true, 303);
            exit;
        default:
            http_response_code(400);
            exit('Unknown action');
    }
}
?>
<!doctype html>
<html lang="zh-Hant">
<meta charset="utf-8">
<title>管理面板</title>
<h1>管理面板</h1>
<p>操作次數 <output id="actions"><?= $_SESSION['actions'] ?></output></p>
<form method="post">
    <button name="action" value="increment">記錄一次操作</button>
    <button name="action" value="logout">登出</button>
</form>
</html>
