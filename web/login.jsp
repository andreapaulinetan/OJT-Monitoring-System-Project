<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Active Learning | Login</title>
        
        <link rel="stylesheet" type="text/css" href="${pageContext.request.contextPath}/css/login.css">
        
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    </head>
    <body>
        <div class="main-container">
            <div class="login-card">
                
                <div class="header-section">
                    <div class="logo-container">
                        <i class="fa-solid fa-layer-group" style="color: #d63384; font-size: 2.2rem;"></i>
                        <span class="brand-text">Active Learning</span>
                    </div>
                    <p class="sub-header">Welcome to OJT Monitor.</p>
                </div>

                <div class="access-toggle">
                    <button type="button" id="internBtn" class="toggle-btn active" onclick="setRole('Intern')">Intern Access</button>
                    <button type="button" id="adminBtn" class="toggle-btn" onclick="setRole('Admin')">Admin Access</button>
                </div>

                <form action="LoginServlet" method="POST">
                    <div class="form-body">
                        <input type="hidden" name="role" id="roleInput" value="Intern">

                        <div class="form-group">
                            <label>Username</label>
                            <div class="input-with-icon">
                                <i class="fa-regular fa-user"></i>
                                <input type="text" name="username" placeholder="Enter username" required>
                            </div>
                        </div>

                        <div class="form-group">
                            <label>Password</label>
                            <div class="input-with-icon">
                                <i class="fa-solid fa-lock"></i>
                                <input type="password" name="password" placeholder="Enter password" required>
                            </div>
                        </div>

                        <p class="instruction-text">Enter your credentials to manage your OJT program.</p>
                        
                        <div class="remember-me">
                            <input type="checkbox" name="remember" id="remember">
                            <label for="remember">Remember me</label>
                        </div>

                        <button type="submit" class="btn-login">
                            <strong>Log in</strong><br>
                            <span class="secure-text">Secure Login</span>
                        </button>

                        <div class="form-footer">
                            <a href="#">Forgot password?</a>
                            <a href="#">Trouble logging in?</a>
                        </div>
                    </div>

                    <div class="security-section">
                        <div class="security-header">
                            <span>Security Verification (Required)</span>
                        </div>
                        
                        <div class="captcha-display">
                            <img src="${pageContext.request.contextPath}/CaptchaServlet" id="captchaImg" alt="Captcha Image">
                            <button type="button" class="refresh-btn-small" onclick="refreshCaptcha()">
                                <i class="fa-solid fa-rotate"></i>
                            </button>
                        </div>

                        <div class="captcha-input">
                            <input type="text" name="captcha" placeholder="Enter characters above" required>
                        </div>
                    </div>
                </form>
            </div>
        </div>

        <script>
            /**
             * Handles switching between Intern and Admin UI
             */
            function setRole(role) {
                // Update the hidden input field
                document.getElementById('roleInput').value = role;

                // Update Button Highlighting
                const internBtn = document.getElementById('internBtn');
                const adminBtn = document.getElementById('adminBtn');

                if (role === 'Intern') {
                    internBtn.classList.add('active');
                    adminBtn.classList.remove('active');
                } else {
                    adminBtn.classList.add('active');
                    internBtn.classList.remove('active');
                }
            }

            /**
             * Refreshes the Captcha image without reloading the whole page
             */
            function refreshCaptcha() {
                var captchaUrl = '${pageContext.request.contextPath}/CaptchaServlet?' + new Date().getTime();
                document.getElementById('captchaImg').src = captchaUrl;
            }
        </script>
    </body>
</html>
