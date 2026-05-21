(function() {
    // 1. Identify context path and page name
    const path = window.location.pathname.toLowerCase();
    const isLoginPage = path.endsWith("login.jsp") || path.endsWith("login.jsp/") || path.endsWith("ojt-monitoring-system-project") || path.endsWith("ojt-monitoring-system-project/");
    const isPublicPage = isLoginPage || path.includes("captchaservlet") || path.endsWith(".css") || path.endsWith(".js") || path.includes("/css/") || path.includes("/images/");

    // 2. Validate window.name tabId
    let tabId = window.name;
    const isValidTabId = tabId && /^tab_[a-z0-9]+_\d+$/.test(tabId);

    if (isLoginPage) {
        if (!isValidTabId) {
            // Generate a fresh unique tab ID for this new login context
            tabId = "tab_" + Math.random().toString(36).substring(2, 10) + "_" + Date.now();
            window.name = tabId;
            try {
                sessionStorage.setItem("tabId", tabId);
            } catch (e) {}
        }
    } else if (!isPublicPage) {
        // We are on a protected page. Verify tabId.
        const urlParams = new URLSearchParams(window.location.search);
        const urlTabId = urlParams.get("tabId");

        // IF:
        // A) window.name does not have a valid tabId, OR
        // B) The URL has a tabId that does not match window.name (Copy-Paste / Cross-Tab Hijack)
        if (!isValidTabId || (urlTabId && urlTabId !== tabId)) {
            // Hide the document content immediately to prevent visual flashing
            document.documentElement.style.display = 'none';
            
            // Redirect to login.jsp with unauthorized flag
            const contextPath = window.location.pathname.substring(0, window.location.pathname.indexOf('/', 1));
            window.location.replace((contextPath ? contextPath : "") + "/login.jsp?err=unauthorized");
            return;
        }
        
        // C) The URL is missing tabId, but window.name is valid (e.g. typed without param or refreshed manually)
        if (!urlTabId && isValidTabId) {
            document.documentElement.style.display = 'none';
            const url = new URL(window.location.href);
            url.searchParams.set("tabId", tabId);
            window.location.replace(url.toString());
            return;
        }
    }

    // 3. Document elements interceptor (for links and forms)
    document.addEventListener("DOMContentLoaded", function() {
        if (!tabId) return;

        // Intercept link clicks
        document.body.addEventListener("click", function(e) {
            let target = e.target;
            while (target && target.tagName !== "A") {
                target = target.parentNode;
            }
            if (target && target.href) {
                // Check if target is not a javascript or anchor link
                const hrefLower = target.href.toLowerCase();
                if (hrefLower.startsWith("javascript:") || hrefLower.startsWith("#")) {
                    return;
                }
                try {
                    const url = new URL(target.href);
                    if (url.origin === window.location.origin) {
                        if (!url.searchParams.has("tabId")) {
                            url.searchParams.set("tabId", tabId);
                            target.href = url.toString();
                        }
                    }
                } catch (err) {
                    // Ignore malformed URLs
                }
            }
        });

        // Intercept form submissions
        document.body.addEventListener("submit", function(e) {
            const form = e.target;
            if (form.action) {
                try {
                    const url = new URL(form.action, window.location.href);
                    if (url.origin === window.location.origin) {
                        // Append to form action URL query parameter (critical for multipart forms)
                        if (!url.searchParams.has("tabId")) {
                            url.searchParams.set("tabId", tabId);
                            form.action = url.toString();
                        }
                        
                        // Also append hidden input field
                        let input = form.querySelector('input[name="tabId"]');
                        if (!input) {
                            input = document.createElement("input");
                            input.type = "hidden";
                            input.name = "tabId";
                            form.appendChild(input);
                        }
                        input.value = tabId;
                    }
                } catch (err) {
                    // Ignore malformed URLs
                }
            }
        });
    });

    // 4. Back-button cache-busting revalidation
    window.addEventListener("pageshow", function(event) {
        // If the page is loaded from cache (bfcache) or back-forward navigation
        if (event.persisted || (window.performance && window.performance.navigation.type === 2)) {
            // Force a reload from the server to revalidate session on server-side
            window.location.reload(true);
        }
    });
})();
