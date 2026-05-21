<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>404 Page Not Found | Active Learning</title>
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
            <div class="error-code">404</div>
            <h1 class="error-title">Page Not Found</h1>
            <p class="error-desc">The page you are looking for has been moved, renamed, or is temporarily unavailable.</p>
            
            <!-- Custom CSS-Animated SVG Illustration (Construction Crane lifting a 404 block) -->
            <div class="illustration-surface">
                <svg width="400" height="200" viewBox="0 0 400 200" fill="none" xmlns="http://www.w3.org/2000/svg" style="max-width: 100%;">
                    
                    <!-- Ground shadow for the crane and zone -->
                    <ellipse cx="200" cy="180" rx="140" ry="12" fill="#0c0d11" />
                    
                    <!-- Construction Zone floor lines / markers -->
                    <line x1="60" y1="180" x2="340" y2="180" stroke="#9ba1b4" stroke-width="1" opacity="0.3" />
                    
                    <!-- Tower Crane Structure (Yellow and Black) - Symmetrically Centered -->
                    <!-- Crane Base/Mount -->
                    <rect x="132" y="172" width="16" height="8" fill="#1b1c23" stroke="#f1c40f" stroke-width="1.5" />
                    
                    <!-- Main Vertical Mast -->
                    <line x1="140" y1="35" x2="140" y2="172" stroke="#f1c40f" stroke-width="4.5" />
                    <!-- Diagonal lattices inside vertical mast -->
                    <path d="M138,172 L142,150 L138,130 L142,110 L138,90 L142,70 L138,50 M142,172 L138,150 L142,130 L138,110 L142,90 L138,70 L142,50" stroke="#1b1c23" stroke-width="0.85" />
                    
                    <!-- Crane Cabin / Pivot Box -->
                    <rect x="133" y="27" width="14" height="10" rx="2.5" fill="#1b1c23" stroke="#f1c40f" stroke-width="1" />
                    <circle cx="137" cy="32" r="2" fill="#0dcaf0" /> <!-- Indicator light -->
                    
                    <!-- Counterweight & Jib Arm (Horizontal Jib extending left and right, centered) -->
                    <line x1="90" y1="29" x2="270" y2="29" stroke="#f1c40f" stroke-width="3" />
                    <!-- Diagonal trusses along the Jib -->
                    <path d="M90,29 L105,18 L120,29 M120,29 L135,18 L150,29 M150,29 L165,18 L180,29 M180,29 L195,18 L210,29 M210,29 L225,18 L240,29 M240,29 L255,18 L270,29" stroke="#f1c40f" stroke-width="1.2" fill="none" />
                    
                    <!-- Crane Counterweight Block (Left) -->
                    <rect x="92" y="29" width="12" height="15" fill="#7f8c8d" rx="1" />
                    
                    <!-- Swaying Hook Assembly & Suspended 404 Block -->
                    <!-- Sits at exact horizontal center X=200 on the Jib -->
                    <!-- Parent group handles the absolute vector translation -->
                    <g transform="translate(200, 29)">
                        <!-- Child group handles the keyframe CSS rotation/sway (pivot origin 0px 0px) -->
                        <g class="swaying-element">
                            <!-- Trolley connector -->
                            <rect x="-4" y="0" width="8" height="4" fill="#1b1c23" />
                            
                            <!-- Steel Suspension Cable -->
                            <line x1="0" y1="4" x2="0" y2="70" stroke="#9ba1b4" stroke-width="1" />
                            
                            <!-- Hook -->
                            <path d="M-2,70 L2,70 A2,2 0 0 1 2,74 C2,76 0,78 -2,78 L-3,78" stroke="#9ba1b4" stroke-width="1.5" fill="none" />
                            
                            <!-- Slings/Wires holding the 404 block -->
                            <line x1="0" y1="76" x2="-28" y2="100" stroke="#7f8c8d" stroke-width="1" />
                            <line x1="0" y1="76" x2="28" y2="100" stroke="#7f8c8d" stroke-width="1" />
                            
                            <!-- Giant "404" Concrete Block -->
                            <rect x="-38" y="100" width="76" height="36" rx="6" fill="#2c3e50" stroke="#f1c40f" stroke-width="1.5" />
                            <!-- Concrete Texture/Lines -->
                            <line x1="-32" y1="108" x2="32" y2="108" stroke="#34495e" stroke-width="1" />
                            <!-- "404" text inside the block -->
                            <text x="0" y="125" font-family="'Outfit', sans-serif" font-weight="900" font-size="20" fill="#ffffff" text-anchor="middle" letter-spacing="1">404</text>
                            <!-- Small hanging warning light on the block -->
                            <circle cx="0" cy="138" r="2.5" fill="#d63384" class="spark-element" />
                        </g>
                    </g>
                    
                    <!-- Construction cones and barriers flanking the floor - Perfectly Symmetrical -->
                    <!-- Cone Left -->
                    <g transform="translate(110, 150)">
                        <ellipse cx="10" cy="28" rx="10" ry="3.5" fill="#000" opacity="0.2" />
                        <path d="M1,26 L19,26 L10,5 Z" fill="#e67e22" />
                        <path d="M5,17 L15,17 L13,12 L7,12 Z" fill="#ffffff" />
                    </g>
                    <!-- Cone Right -->
                    <g transform="translate(270, 150)">
                        <ellipse cx="10" cy="28" rx="10" ry="3.5" fill="#000" opacity="0.2" />
                        <path d="M1,26 L19,26 L10,5 Z" fill="#e67e22" />
                        <path d="M5,17 L15,17 L13,12 L7,12 Z" fill="#ffffff" />
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
