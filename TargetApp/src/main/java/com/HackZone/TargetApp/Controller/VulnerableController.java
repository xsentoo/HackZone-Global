package com.HackZone.TargetApp.Controller;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.Query;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Controller
public class VulnerableController {

    @PersistenceContext
    private EntityManager entityManager;

    // --- FIX DOCKER : Méthode utilitaire pour l'URL JDBC ---
    private String getJdbcUrl() {
        String dbHost = System.getenv("DB_HOST");
        String dbPort = System.getenv("DB_PORT");

        if (dbHost == null || dbHost.isEmpty()) dbHost = "localhost";
        if (dbPort == null || dbPort.isEmpty()) dbPort = "3308";

        return "jdbc:mysql://" + dbHost + ":" + dbPort + "/TargetDB?allowPublicKeyRetrieval=true&useSSL=false&useUnicode=true&characterEncoding=UTF-8";
    }

    // --- ROUTES BASIQUES ---
    @GetMapping("/")
    public String loginPage(){ return "login"; }

    @GetMapping("/login")
    public String showLoginForm() { return "login"; }

    @GetMapping("/ssh-challenge")
    public String showSSHChallenge() { return "ssh-challenge"; }

    @GetMapping("/vpn-challenge")
    public String showVpnChallenge() { return "vpn-challenge"; }

    // --- LOGIN VULNÉRABLE (SQLi Niveau 1) ---
    @PostMapping("/login")
    public String login(@RequestParam String username, @RequestParam String password, Model model){
        String sql = "SELECT * FROM Users WHERE username = '" + username + "' and password = '" + password + "'";
        try {
            Query query = entityManager.createNativeQuery(sql);
            List result = query.getResultList();

            if(!result.isEmpty()){
                Object[] userRow = (Object[]) result.get(0);
                String name = (String) userRow[1];
                String secret = (String) userRow[3];
                model.addAttribute("username" , name);
                model.addAttribute("secret", secret);
                return "dashboard";
            } else {
                model.addAttribute("error", "Identifiants incorrects");
                return "login";
            }
        } catch(Exception e) {
            model.addAttribute("error", "Erreur SQL : " + e.getMessage());
            return "login";
        }
    }

    // --- SHOP VULNÉRABLE (SQLi Niveau 2) ---
    @GetMapping("/shop")
    public String shopPage(@RequestParam(required = false, defaultValue = "Vêtements") String category, Model model) {
        List<Map<String, String>> products = new ArrayList<>();
        String error = null;
        String url = getJdbcUrl();

        try (Connection con = DriverManager.getConnection(url, "root", "root");
             Statement stmt = con.createStatement()) {

            String sql = "SELECT name, price FROM Products WHERE category = '" + category + "'";
            model.addAttribute("lastQuery", sql);
            ResultSet rs = stmt.executeQuery(sql);

            while (rs.next()) {
                Map<String, String> product = new HashMap<>();
                product.put("name", rs.getString(1));
                product.put("price", rs.getString(2));
                products.add(product);
            }
        } catch (Exception e) {
            error = "Erreur SQL : " + e.getMessage();
            e.printStackTrace();
        }
        model.addAttribute("products", products);
        model.addAttribute("error", error);
        return "shop";
    }

    // --- GUESTBOOK VULNÉRABLE (XSS Stocké) ---
    @GetMapping("/guestbook")
    public String guestbookPage(Model model, HttpServletResponse response, HttpSession session) {
        Cookie flagCookie = new Cookie("flag", "FLAG{XSS_MASTER_ALERT}");
        flagCookie.setHttpOnly(false);
        flagCookie.setPath("/");
        flagCookie.setMaxAge(3600);
        response.addCookie(flagCookie);

        String sessionId = session.getId();
        List<String> comments = new ArrayList<>();
        String url = getJdbcUrl();

        try (Connection con = DriverManager.getConnection(url, "root", "root")) {
            // Lecture
            try (PreparedStatement pstmtSelect = con.prepareStatement("SELECT content FROM Comments WHERE session_id = ? ORDER BY id DESC")) {
                pstmtSelect.setString(1, sessionId);
                ResultSet rs = pstmtSelect.executeQuery();
                while (rs.next()) {
                    comments.add(rs.getString("content"));
                }
            }
            // Auto-nettoyage
            try (PreparedStatement pstmtDelete = con.prepareStatement("DELETE FROM Comments WHERE session_id = ?")) {
                pstmtDelete.setString(1, sessionId);
                pstmtDelete.executeUpdate();
            }
        } catch (Exception e) { e.printStackTrace(); }

        model.addAttribute("comments", comments);
        return "guestbook";
    }

    @PostMapping("/guestbook")
    public String postComment(@RequestParam String content, HttpSession session) {
        String url = getJdbcUrl();
        String sessionId = session.getId();
        try (Connection con = DriverManager.getConnection(url, "root", "root");
             PreparedStatement pstmt = con.prepareStatement("INSERT INTO Comments (content, session_id) VALUES (?, ?)")) {
            pstmt.setString(1, content);
            pstmt.setString(2, sessionId);
            pstmt.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); }
        return "redirect:/guestbook";
    }

    // --- NOUVEAU : PROFIL VULNÉRABLE (CSRF) ---
    @GetMapping("/profile")
    public String profilePage(Model model) {
        String url = getJdbcUrl();
        String currentEmail = "Inconnu";
        try (Connection con = DriverManager.getConnection(url, "root", "root");
             PreparedStatement pstmt = con.prepareStatement("SELECT email FROM Users WHERE username = 'admin'")) {
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                currentEmail = rs.getString("email");
            }
        } catch (Exception e) { e.printStackTrace(); }

        model.addAttribute("email", currentEmail);
        return "profile";
    }

    @PostMapping("/profile/update-email")
    public String updateEmail(@RequestParam String email, Model model) {
        String url = getJdbcUrl();
        String message = "";
        String flag = "";

        try (Connection con = DriverManager.getConnection(url, "root", "root");
             PreparedStatement pstmt = con.prepareStatement("UPDATE Users SET email = ? WHERE username = 'admin'")) {
            pstmt.setString(1, email);
            pstmt.executeUpdate();
            message = "Email mis à jour avec succès : " + email;

            if ("hacker@csrf.com".equals(email)) {
                flag = "BRAVO ! Voici votre flag : FLAG{CSRF_ATTACK_SUCCESS}";
            }
        } catch (Exception e) {
            message = "Erreur : " + e.getMessage();
            e.printStackTrace();
        }
        model.addAttribute("email", email);
        model.addAttribute("message", message);
        model.addAttribute("flag", flag);
        return "profile";
    }
}