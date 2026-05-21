package controller;

import java.io.*;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.util.Random;
import javax.imageio.ImageIO;
import javax.servlet.ServletException;
import javax.servlet.http.*;

public class CaptchaServlet extends HttpServlet {
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        try {
            int width = 160, height = 50;
            BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
            Graphics2D g = image.createGraphics();
            Random r = new Random();

            // 1. Better Background (Anti-Aliasing for smoother text)
            g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
            g.setColor(new Color(240, 240, 240)); // Off-white
            g.fillRect(0, 0, width, height);

            // 2. Stronger Noise (Lines and Dots)
            for(int i=0; i<15; i++) {
                g.setColor(new Color(r.nextInt(255), r.nextInt(255), r.nextInt(255), 100));
                g.drawLine(r.nextInt(width), r.nextInt(height), r.nextInt(width), r.nextInt(height));
            }

            // 3. Generate 5-char String (Using standard characters to avoid confusing symbols)
            String chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // Removed 0, O, I, 1 to prevent user error
            StringBuilder sb = new StringBuilder();
            for(int i=0; i<5; i++) sb.append(chars.charAt(r.nextInt(chars.length())));
            String captcha = sb.toString();
            
            // Store in session per-tab if tabId is specified, else fallback to standard session attribute
            String tabId = util.TabSessionHelper.getTabId(request);
            if (tabId != null && !tabId.trim().isEmpty()) {
                util.TabSessionHelper.setAttribute(request.getSession(true), tabId, "captcha", captcha);
            } else {
                request.getSession(true).setAttribute("captcha", captcha);
            }

            // 4. Draw Characters with Random Rotation
            g.setFont(new Font("Arial", Font.BOLD, 35));
            for(int i=0; i<captcha.length(); i++) {
                g.setColor(new Color(r.nextInt(100), r.nextInt(100), r.nextInt(100))); // Dark colors for text
                int x = 20 + (i * 25);
                int y = 35;
                
                // Apply slight rotation to each letter
                g.rotate(Math.toRadians(r.nextInt(20) - 10), x, y); 
                g.drawString(String.valueOf(captcha.charAt(i)), x, y);
                g.rotate(-Math.toRadians(r.nextInt(20) - 10), x, y); // Reset rotation
            }

            g.dispose();
            response.setHeader("Cache-Control", "no-store"); // Ensure the browser doesn't cache the image
            response.setContentType("image/png");
            ImageIO.write(image, "png", response.getOutputStream());
        } catch (Exception e) {
            util.ErrorLogger.logError("SERVLET ERROR", "Failed to generate CAPTCHA image", e, request.getSession(false), getServletContext());
            if (e instanceof IOException) {
                throw (IOException) e;
            } else {
                throw new ServletException(e);
            }
        }
    }
}