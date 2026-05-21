<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@page import="model.User"%>
<%
    // Prevent browser caching of login page
    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    // Auto-redirect if already logged in
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser != null) {
        if ("admin".equalsIgnoreCase(loggedInUser.getRole())) {
            response.sendRedirect("admin.jsp");
            return;
        } else {
            response.sendRedirect("guest.jsp");
            return;
        }
    }
%>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Active Learning | Login</title>
        <link rel="stylesheet" type="text/css" href="${pageContext.request.contextPath}/css/login.css">
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    </head>
    <body onload="startLockoutTimer()">
        <%
            String err = request.getParameter("err");
            String status = request.getParameter("status");
            String attempts = request.getParameter("attemptsLeft");
            String lastUser = request.getParameter("lastUser");
            String until = request.getParameter("until"); 
            boolean isLocked = "locked".equals(status);
        %>

        <div class="main-container">
            <div class="login-card">
                <div class="header-section">
                    <div class="logo-container">
                        <i class="fa-solid fa-layer-group" style="color: #d63384; font-size: 2.2rem;"></i>
                        <span class="brand-text">Active Learning</span>
                    </div>
                    <p class="sub-header">Welcome to OJT Monitor.</p>
                </div>

                <div class="message-container">
                    <% if (isLocked) { %>
                        <div class="alert alert-danger">
                            <i class="fa-solid fa-user-lock"></i> 
                            <strong>Security Lockout:</strong> <span id="timerText">Calculating time...</span>
                        </div>
                    <% } else if ("1".equals(err)) { %>
                        <div class="alert alert-warning">
                            Invalid CAPTCHA. Attempts left: <%= attempts %>
                        </div>
                    <% } else if ("2".equals(err)) { %>
                        <div class="alert alert-danger">
                            Invalid Credentials. Attempts left: <%= attempts %>
                        </div>
                    <% } %>
                </div>

                <form action="LoginServlet" method="POST">
                    <div class="form-body">
                        <div class="form-group">
                            <label>Email Address</label>
                            <div class="input-with-icon">
                                <i class="fa-regular fa-envelope"></i>
                                <input type="text" name="username" placeholder="Enter your email" value="<%= (lastUser != null) ? lastUser : "" %>" required <%= isLocked ? "disabled" : "" %>>
                            </div>
                        </div>

                        <div class="form-group">
                            <label>Password</label>
                            <div class="input-with-icon">
                                <i class="fa-solid fa-lock"></i>
                                <input type="password" name="password" placeholder="Enter password" required <%= isLocked ? "disabled" : "" %>>
                            </div>
                        </div>

                        <div class="remember-me">
                            <input type="checkbox" name="remember" id="remember" <%= isLocked ? "disabled" : "" %>>
                            <label for="remember">Remember me</label>
                        </div>

                        <button type="submit" class="btn-login" <%= isLocked ? "disabled" : "" %>>
                            <strong>
                                <% if (isLocked) { %>
                                    <del style="opacity: 0.5;">Log in</del>
                                <% } else { %>
                                    Log in
                                <% } %>
                            </strong>
                            <span class="secure-text <%= isLocked ? "lockout-timer-text" : "" %>" id="btnSubText">
                                <%= isLocked ? "Account Temporary Lock" : "Secure Login" %>
                            </span>
                        </button>

                        <div class="form-footer">
                            <a href="#">Forgot password?</a>
                            <a href="#">Trouble logging in?</a>
                        </div>
                    </div>

                    <div class="security-section">
                        <div class="security-header">Security Verification</div>
                        <div class="captcha-display">
                            <img src="${pageContext.request.contextPath}/CaptchaServlet" id="captchaImg" alt="Captcha">
                            <button type="button" class="refresh-btn-small" onclick="refreshCaptcha()" <%= isLocked ? "disabled" : "" %>>
                                <i class="fa-solid fa-rotate"></i>
                            </button>
                        </div>
                        <div class="captcha-input">
                            <input type="text" name="captcha" placeholder="Enter characters" required <%= isLocked ? "disabled" : "" %>>
                        </div>
                    </div>
                </form>
            </div>
        </div>

        <script>
            function refreshCaptcha() {
                document.getElementById('captchaImg').src = '${pageContext.request.contextPath}/CaptchaServlet?' + new Date().getTime();
            }

            function startLockoutTimer() {
                const until = "<%= (until != null) ? until : "" %>";
                if (!until) return;

                const endTime = parseInt(until);
                const timerText = document.getElementById('timerText');
                const btnSubText = document.getElementById('btnSubText');

                const countdown = setInterval(function() {
                    const now = new Date().getTime();
                    const timeLeft = endTime - now;

                    if (timeLeft <= 0) {
                        clearInterval(countdown);
                        window.location.href = "login.jsp";
                    } else {
                        const mins = Math.floor((timeLeft % (1000 * 60 * 60)) / (1000 * 60));
                        const secs = Math.floor((timeLeft % (1000 * 60)) / 1000);
                        const timeStr = mins + "m " + secs + "s remaining";
                        
                        if (timerText) timerText.innerHTML = "Too many failed attempts. Try again in later.";
                        if (btnSubText) btnSubText.innerHTML = "Locked: " + timeStr;
                    }
                }, 1000);
            }
        </script>
    </body>
</html>