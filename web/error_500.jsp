<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>500 Internal Server Error | Active Learning</title>
    <link rel="stylesheet" type="text/css" href="${pageContext.request.contextPath}/css/error.css?v=<%= System.currentTimeMillis() %>">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
</head>
<body>

    <!-- Header Section -->
    <header class="error-header">
        <div class="header-container">
            <a href="${pageContext.request.contextPath}/login.jsp" class="brand">
                <i class="fa-solid fa-layer-group" style="color: var(--color-pink); font-size: 1.8rem;"></i>
                <span class="brand-text">Active Learning</span>
            </a>
        </div>
    </header>

    <!-- Main Workspace -->
    <main class="error-container">
        <div class="error-card">
            <div class="error-code">500</div>
            <h1 class="error-title">Internal Server Error</h1>
            <p class="error-desc">The server encountered an unexpected condition that prevented it from fulfilling your request. Our engineers have been alerted.</p>
            
            <!-- Custom CSS-Animated SVG Illustration (Sparking Servers & Grinding Gears) -->
            <div class="illustration-surface">
                <svg width="400" height="200" viewBox="0 0 400 200" fill="none" xmlns="http://www.w3.org/2000/svg" style="max-width: 100%;">
                    
                    <!-- Ground shadow -->
                    <ellipse cx="200" cy="175" rx="90" ry="12" fill="#0c0d11" />
                    
                    <!-- Server Cabinet Chassis (Left Box) -->
                    <rect x="110" y="40" width="70" height="120" rx="6" fill="#1b1c23" stroke="#9ba1b4" stroke-width="2" />
                    <!-- Server details (Rack blades) -->
                    <g transform="translate(115, 45)">
                        <!-- Blade 1 -->
                        <rect x="0" y="5" width="60" height="15" rx="2" fill="#121318" />
                        <circle cx="10" cy="125" r="2" fill="#2ecc71" /> <!-- Blinking LED -->
                        <rect x="40" y="10" width="12" height="4" fill="#7f8c8d" />
                        <!-- Blade 2 -->
                        <rect x="0" y="25" width="60" height="15" rx="2" fill="#121318" />
                        <circle cx="10" cy="32" r="2" fill="#d63384" class="spark-element" /> <!-- Red warning LED -->
                        <!-- Blade 3 -->
                        <rect x="0" y="45" width="60" height="15" rx="2" fill="#121318" />
                        <circle cx="10" cy="52" r="2" fill="#2ecc71" />
                        <!-- Blade 4 -->
                        <rect x="0" y="65" width="60" height="15" rx="2" fill="#121318" />
                        <circle cx="10" cy="72" r="2" fill="#d63384" class="spark-element" />
                        <!-- Blade 5 -->
                        <rect x="0" y="85" width="60" height="15" rx="2" fill="#121318" />
                        <circle cx="10" cy="92" r="2" fill="#ffc107" />
                    </g>
                    
                    <!-- Mechanical Gears (Right Side representing system core engine breakdown) -->
                    <g transform="translate(235, 95)">
                        <!-- Gear 1 (Clockwise) -->
                        <g class="gear-clockwise">
                            <circle cx="0" cy="0" r="30" fill="none" stroke="#d63384" stroke-width="6" stroke-dasharray="10 6" />
                            <circle cx="0" cy="0" r="20" fill="#1b1c23" stroke="#d63384" stroke-width="2" />
                            <circle cx="0" cy="0" r="6" fill="#121318" />
                        </g>
                        
                        <!-- Gear 2 (Counter Clockwise, smaller, meshing with Gear 1) -->
                        <g transform="translate(45, -35)" class="gear-counter">
                            <circle cx="0" cy="0" r="18" fill="none" stroke="#ffc107" stroke-width="4" stroke-dasharray="6 4" />
                            <circle cx="0" cy="0" r="11" fill="#1b1c23" stroke="#ffc107" stroke-width="1.5" />
                            <circle cx="0" cy="0" r="3.5" fill="#121318" />
                        </g>
                    </g>
                    
                    <!-- Neon Electric Sparks (Lightning Overload) -->
                    <g class="spark-element">
                        <!-- Bolt 1 (Coming from server to gears) -->
                        <path d="M185,80 L205,75 L195,95 L225,90" stroke="#d63384" stroke-width="2.5" stroke-linecap="round" fill="none" />
                        <!-- Bolt 2 (Sparking off server top) -->
                        <path d="M145,35 L150,15 L140,22 L150,5" stroke="#ffc107" stroke-width="2" stroke-linecap="round" fill="none" />
                        <!-- Spark stars -->
                        <circle cx="150" cy="5" r="1.5" fill="#ffffff" />
                        <circle cx="225" cy="90" r="1.5" fill="#ffffff" />
                    </g>
                    
                </svg>
            </div>
            
            <!-- Navigation Action -->
            <a href="${pageContext.request.contextPath}/login.jsp" class="btn-safety" id="safetyLink">
                <i class="fa-solid fa-house"></i> Return to Safety
            </a>
        </div>
    </main>

    <!-- Footer Section -->
    <footer class="error-footer">
        <p class="footer-text">
            Active Learning, Inc. — Internship Learning Tracker | Confidential | Generated by ICS2609 System
        </p>
    </footer>

    <script>
        document.addEventListener("DOMContentLoaded", () => {
            const safetyLink = document.getElementById("safetyLink");
            const tabId = window.name || sessionStorage.getItem("tabId") || "";
            if (tabId) {
                safetyLink.href = "${pageContext.request.contextPath}/login.jsp?tabId=" + encodeURIComponent(tabId);
            }
        });
    </script>
</body>
</html>
