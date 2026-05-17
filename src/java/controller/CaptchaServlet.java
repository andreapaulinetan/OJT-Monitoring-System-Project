package controller;

import java.io.*;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.util.Random;
import javax.imageio.ImageIO;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

public class CaptchaServlet extends HttpServlet {
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        int width = 150, height = 50;
        BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = image.createGraphics();
        
        // Background and Noise
        g.setColor(Color.WHITE);
        g.fillRect(0, 0, width, height);
        g.setColor(Color.GRAY);
        Random r = new Random();
        for(int i=0; i<10; i++) g.drawLine(r.nextInt(width), r.nextInt(height), r.nextInt(width), r.nextInt(height));

        // Generate 5-char String
        String captcha = Long.toHexString(Double.doubleToLongBits(Math.random())).substring(0, 5).toUpperCase();
        request.getSession().setAttribute("captcha", captcha);

        // Draw Text
        g.setFont(new Font("Arial", Font.BOLD, 30));
        g.setColor(Color.BLACK);
        g.drawString(captcha, 20, 35);
        g.dispose();

        response.setContentType("image/png");
        ImageIO.write(image, "png", response.getOutputStream());
    }
}