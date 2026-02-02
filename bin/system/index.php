<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Luhut - Local Development</title>
    <link rel="stylesheet" href="assets/css/style.css">
</head>

<body>
    <div class="container">
        <h1>It Works!</h1>
        <p>Your local development environment is ready.</p>

        <div class="status-badge">
            <?php echo "PHP " . phpversion(); ?>
        </div>

        <p style="margin-top: 2rem; font-size: 0.9rem;">
            To get started, create a folder in <br>
            <code><?php echo __DIR__; ?></code>
        </p>

        <div class="footer">
            Luhut Manager &bull; Local Development Environment
        </div>
    </div>
</body>

</html>