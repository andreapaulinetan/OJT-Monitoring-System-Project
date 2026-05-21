<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>400 Bad Request | Active Learning</title>
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
            <div class="error-code">400</div>
            <h1 class="error-title">Sorry, bad request sent</h1>
            <p class="error-desc">The request sent by your browser was corrupted, oversized, or improperly built.</p>
            
            <!-- Custom CSS-Animated SVG Illustration (Fixed Straight Pointing Hand) -->
            <div class="illustration-surface">
                <svg width="460" height="200" viewBox="0 0 460 200" fill="none" xmlns="http://www.w3.org/2000/svg" style="max-width: 100%;">
                    
                    <!-- Portal Hole Shadow & Ground Portal -->
                    <ellipse cx="230" cy="165" rx="90" ry="25" fill="#0c0d11" />
                    <ellipse cx="230" cy="165" rx="80" ry="18" fill="#1b1c23" />
                    
                    <!-- Straight Open Hand (Premium Vector STOP Hand) -->
                    <g class="floating-hand">
                        <!-- Sleeve/Arm extending STRAIGHT up -->
                        <rect x="218" y="110" width="24" height="55" fill="#0cb9c1" />
                        <!-- Shadow on Sleeve -->
                        <rect x="230" y="110" width="12" height="55" fill="#0a9ca3" opacity="0.3" />
                        
                        <!-- Cuff line -->
                        <rect x="215" y="104" width="30" height="8" rx="3" fill="#ffffff" />
                        
                        <!-- Palm/Hand base -->
                        <path d="M214,104 L212,78 C212,74 215,72 219,72 L241,72 C245,72 248,74 248,78 L246,104 Z" fill="#f7b797" />
                        <!-- Shadow on right half of Palm -->
                        <path d="M230,72 L241,72 C245,72 248,74 248,78 L246,104 L230,104 Z" fill="#e2a07f" opacity="0.3" />
                        
                        <!-- Thumb (Extended outwards on the left) -->
                        <path d="M213,92 C201,92 195,84 198,76 C201,69 209,74 213,82 C214,84 214,88 213,92 Z" fill="#f7b797" />
                        <!-- Thumb shadow/detail -->
                        <path d="M208,82 C205,79 202,77 199,77" stroke="#be7e5f" stroke-width="1.2" stroke-linecap="round" fill="none" />
                        
                        <!-- Index finger (extended straight up) -->
                        <rect x="213" y="42" width="7" height="35" rx="3.5" fill="#f7b797" />
                        <!-- Index finger shadow -->
                        <path d="M216.5,42 L216.5,77 C218.5,77 220,75.5 220,73.5 L220,45.5 C220,43.5 218.5,42 216.5,42 Z" fill="#e2a07f" opacity="0.3" />
                        <!-- Index crease lines -->
                        <line x1="215" y1="53" x2="218" y2="53" stroke="#be7e5f" stroke-width="1" stroke-linecap="round" />
                        <line x1="215" y1="65" x2="218" y2="65" stroke="#be7e5f" stroke-width="1" stroke-linecap="round" />
                        
                        <!-- Middle finger (extended straight up) -->
                        <rect x="221.5" y="35" width="7.5" height="42" rx="3.75" fill="#f7b797" />
                        <!-- Middle finger shadow -->
                        <path d="M225.25,35 L225.25,77 C227.25,77 229,75.25 229,73.25 L229,38.75 C229,36.75 227.25,35 225.25,35 Z" fill="#e2a07f" opacity="0.3" />
                        <!-- Middle crease lines -->
                        <line x1="223" y1="48" x2="227" y2="48" stroke="#be7e5f" stroke-width="1" stroke-linecap="round" />
                        <line x1="223" y1="61" x2="227" y2="61" stroke="#be7e5f" stroke-width="1" stroke-linecap="round" />
                        
                        <!-- Ring finger (extended straight up) -->
                        <rect x="230.5" y="40" width="7" height="37" rx="3.5" fill="#f7b797" />
                        <!-- Ring finger shadow -->
                        <path d="M234,40 L234,77 C236,77 237.5,75.5 237.5,73.5 L237.5,43.5 C237.5,41.5 236,40 234,40 Z" fill="#e2a07f" opacity="0.3" />
                        <!-- Ring crease lines -->
                        <line x1="232" y1="51" x2="236" y2="51" stroke="#be7e5f" stroke-width="1" stroke-linecap="round" />
                        <line x1="232" y1="63" x2="236" y2="63" stroke="#be7e5f" stroke-width="1" stroke-linecap="round" />
                        
                        <!-- Pinky finger (extended straight up) -->
                        <rect x="239" y="49" width="6.5" height="28" rx="3.25" fill="#f7b797" />
                        <!-- Pinky finger shadow -->
                        <path d="M242.25,49 L242.25,77 C244,77 245.5,75.5 245.5,73.5 L245.5,52.25 C245.5,50.25 244,49 242.25,49 Z" fill="#e2a07f" opacity="0.3" />
                        <!-- Pinky crease lines -->
                        <line x1="240.5" y1="58" x2="244" y2="58" stroke="#be7e5f" stroke-width="1" stroke-linecap="round" />
                        <line x1="240.5" y1="67" x2="244" y2="67" stroke="#be7e5f" stroke-width="1" stroke-linecap="round" />
                    </g>
                    
                    <!-- Caution Tape in front of the hand -->
                    <!-- Caution Tape Banner Bar -->
                    <g>
                        <!-- Tape strip slanted across the front -->
                        <path d="M40,120 L420,120 L420,135 L40,135 Z" fill="#f1c40f" />
                        <!-- Caution stripes (Black slanted bars) -->
                        <path d="M60,120 L75,120 L60,135 L45,135 Z" fill="#1b1c23" />
                        <path d="M100,120 L115,120 L100,135 L85,135 Z" fill="#1b1c23" />
                        <path d="M140,120 L155,120 L140,135 L125,135 Z" fill="#1b1c23" />
                        <path d="M180,120 L195,120 L180,135 L165,135 Z" fill="#1b1c23" />
                        <path d="M220,120 L235,120 L220,135 L205,135 Z" fill="#1b1c23" />
                        <path d="M260,120 L275,120 L260,135 L245,135 Z" fill="#1b1c23" />
                        <path d="M300,120 L315,120 L300,135 L285,135 Z" fill="#1b1c23" />
                        <path d="M340,120 L355,120 L340,135 L325,135 Z" fill="#1b1c23" />
                        <path d="M380,120 L395,120 L380,135 L365,135 Z" fill="#1b1c23" />
                        
                        <!-- "ERROR" typography on the tape -->
                        <text x="75" y="131" font-family="'Outfit', sans-serif" font-weight="800" font-size="10" fill="#1b1c23" letter-spacing="1">ERROR</text>
                        <text x="155" y="131" font-family="'Outfit', sans-serif" font-weight="800" font-size="10" fill="#1b1c23" letter-spacing="1">ERROR</text>
                        <text x="235" y="131" font-family="'Outfit', sans-serif" font-weight="800" font-size="10" fill="#1b1c23" letter-spacing="1">ERROR</text>
                        <text x="315" y="131" font-family="'Outfit', sans-serif" font-weight="800" font-size="10" fill="#1b1c23" letter-spacing="1">ERROR</text>
                    </g>
                    
                    <!-- Flanking Traffic Cones (Left and Right) -->
                    <!-- Left Cone -->
                    <g transform="translate(110, 115)">
                        <!-- Oval Base shadow -->
                        <ellipse cx="20" cy="45" rx="20" ry="7" fill="#000" opacity="0.3" />
                        <!-- Cone Base block -->
                        <path d="M2,40 L38,40 C40,40 40,43 38,43 L2,43 C0,43 0,40 2,40 Z" fill="#e67e22" />
                        <!-- Cone body -->
                        <path d="M12,40 L28,40 L22,10 L18,10 Z" fill="#e67e22" />
                        <!-- White stripe -->
                        <path d="M14,30 L26,30 L24,20 L16,20 Z" fill="#ffffff" />
                        <!-- Tip shadow/tip orange -->
                        <path d="M17,15 L23,15 L22,10 L18,10 Z" fill="#d35400" />
                    </g>
                    
                    <!-- Right Cone -->
                    <g transform="translate(290, 115)">
                        <!-- Oval Base shadow -->
                        <ellipse cx="20" cy="45" rx="20" ry="7" fill="#000" opacity="0.3" />
                        <!-- Cone Base block -->
                        <path d="M2,40 L38,40 C40,40 40,43 38,43 L2,43 C0,43 0,40 2,40 Z" fill="#e67e22" />
                        <!-- Cone body -->
                        <path d="M12,40 L28,40 L22,10 L18,10 Z" fill="#e67e22" />
                        <!-- White stripe -->
                        <path d="M14,30 L26,30 L24,20 L16,20 Z" fill="#ffffff" />
                        <!-- Tip shadow/tip orange -->
                        <path d="M17,15 L23,15 L22,10 L18,10 Z" fill="#d35400" />
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
        // Intelligent routing backup check
        document.addEventListener("DOMContentLoaded", () => {
            const safetyLink = document.getElementById("safetyLink");
            const tabId = window.name || sessionStorage.getItem("tabId") || "";
            
            // If they have a tab ID and we can check their active role, we could route dynamically.
            // By default, we fall back cleanly to login page to allow re-authentication context verification.
            if (tabId) {
                safetyLink.href = "${pageContext.request.contextPath}/login.jsp?tabId=" + encodeURIComponent(tabId);
            }
        });
    </script>
</body>
</html>
