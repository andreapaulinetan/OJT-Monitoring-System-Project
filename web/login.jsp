<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@page import="model.User"%>
<%@ page import="util.HtmlUtil" %>
<%@ page import="util.CsrfUtil" %>
<%@ page import="util.TabSessionHelper" %>
<%
    // Prevent browser caching of login page
    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    // Auto-redirect if already logged in
    String tabId = request.getParameter("tabId");
    User loggedInUser = TabSessionHelper.getUser(session, tabId);
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
        <script src="${pageContext.request.contextPath}/js/tabSession.js"></script>
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
                            Invalid CAPTCHA. Attempts left: <%= HtmlUtil.escape(attempts) %>
                        </div>
                    <% } else if ("2".equals(err)) { %>
                        <div class="alert alert-danger">
                            Invalid Credentials. Attempts left: <%= HtmlUtil.escape(attempts) %>
                        </div>
                    <% } else if ("empty".equals(err)) { %>
                        <div class="alert alert-danger">
                            Email and password cannot be empty.
                        </div>
                    <% } else if ("invalid_input".equals(err)) { %>
                        <div class="alert alert-danger">
                            Invalid input length or format.
                        </div>
                    <% } %>
                </div>

                <form action="LoginServlet" method="POST" id="loginForm">
                    <input type="hidden" name="csrfToken" value="<%= CsrfUtil.getToken(session) %>"/>
                    <div class="form-body">
                        <div class="form-group">
                            <label>Email Address</label>
                            <div class="input-with-icon">
                                <i class="fa-regular fa-envelope"></i>
                                <input type="email" name="username" placeholder="Enter your email" value="<%= HtmlUtil.escape((lastUser != null) ? lastUser : "") %>" maxlength="255" required <%= isLocked ? "disabled" : "" %>>
                                <div class="invalid-feedback">Please enter a valid email address (max 255 characters).</div>
                            </div>
                        </div>

                        <div class="form-group">
                            <label>Password</label>
                            <div class="input-with-icon">
                                <i class="fa-solid fa-lock"></i>
                                <input type="password" name="password" placeholder="Enter password" maxlength="100" required <%= isLocked ? "disabled" : "" %>>
                                <div class="invalid-feedback">Password cannot be empty (max 100 characters).</div>
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
                            <input type="text" name="captcha" placeholder="Enter characters" maxlength="5" autocomplete="off" required <%= isLocked ? "disabled" : "" %>>
                            <div class="invalid-feedback">CAPTCHA must be exactly 5 characters.</div>
                        </div>
                    </div>
                </form>
            </div>
        </div>

        <script>
            function refreshCaptcha() {
                const tabId = window.name || sessionStorage.getItem("tabId") || "";
                document.getElementById('captchaImg').src = '${pageContext.request.contextPath}/CaptchaServlet?tabId=' + tabId + '&' + new Date().getTime();
            }

            document.addEventListener("DOMContentLoaded", function() {
                refreshCaptcha();
                
                const form = document.getElementById("loginForm");
                if (form) {
                    const emailInput = document.querySelector('input[name="username"]');
                    const passwordInput = document.querySelector('input[name="password"]');
                    const captchaInput = document.querySelector('input[name="captcha"]');

                    // Setup real-time input event listeners to clear invalid states
                    const inputs = [emailInput, passwordInput, captchaInput];
                    inputs.forEach(input => {
                        if (input) {
                            input.addEventListener("input", function() {
                                this.classList.remove("is-invalid");
                            });
                        }
                    });

                    form.addEventListener("submit", function(event) {
                        let isValid = true;

                        // Email validation
                        if (emailInput) {
                            const email = emailInput.value.trim();
                            const emailRegex = /^[\w.+%-]+@[\w.-]+\.[a-zA-Z]{2,}$/;
                            if (!emailRegex.test(email) || email.length > 255) {
                                emailInput.classList.add("is-invalid");
                                emailInput.focus();
                                isValid = false;
                            } else {
                                emailInput.classList.remove("is-invalid");
                            }
                        }

                        // Password validation
                        if (passwordInput) {
                            const password = passwordInput.value.trim();
                            if (password.length === 0 || password.length > 100) {
                                passwordInput.classList.add("is-invalid");
                                if (isValid) {
                                    passwordInput.focus();
                                    isValid = false;
                                }
                            } else {
                                passwordInput.classList.remove("is-invalid");
                            }
                        }

                        // CAPTCHA validation
                        if (captchaInput) {
                            const captcha = captchaInput.value.trim();
                            if (captcha.length !== 5) {
                                captchaInput.classList.add("is-invalid");
                                if (isValid) {
                                    captchaInput.focus();
                                    isValid = false;
                                }
                            } else {
                                captchaInput.classList.remove("is-invalid");
                            }
                        }

                        if (!isValid) {
                            event.preventDefault();
                        }
                    });
                }
            });

            function startLockoutTimer() {
                const until = "<%= HtmlUtil.escapeJs((until != null) ? until : "") %>";
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
                        
                        if (timerText) timerText.textContent = "Too many failed attempts. Try again in later.";
                        if (btnSubText) btnSubText.textContent = "Locked: " + timeStr;
                    }
                }, 1000);
            }
        </script>


    </body>
</html>