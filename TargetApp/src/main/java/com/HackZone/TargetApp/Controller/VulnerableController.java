package com.HackZone.TargetApp.Controller;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.Query;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.HashMap; // Import ajouté !
import java.util.List;
import java.util.Map;

@Controller
public class VulnerableController {

    @PersistenceContext
    private EntityManager entityManager;

    // --- PAGE DE LOGIN (Niveau 1) ---
    @GetMapping("/")
    public String loginPage(){
        return "login";
    }

    // --- TRAITEMENT LOGIN VULNÉRABLE (Niveau 1) ---
    @PostMapping("/login")
    public String login(@RequestParam String username, @RequestParam String password, Model model){

        // Faille : Concaténation directe
        String sql = "SELECT * FROM Users WHERE username = '" + username + "' and password = '" + password + "'";

        System.out.println("Requete login exécutée : " + sql);

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

    // --- CHALLENGE 3 : SQL INJECTION NIVEAU 2 (UNION BASED) ---
    @GetMapping("/shop")
    public String shopPage(@RequestParam(required = false, defaultValue = "Vêtements") String category, Model model) {

        List<Map<String, String>> products = new ArrayList<>();
        String error = null;


        String url = "jdbc:mysql://mysqldb:3306/TargetDB?allowPublicKeyRetrieval=true&useSSL=false";
        String user = "root";
        String password = "root";

        try (Connection con = DriverManager.getConnection(url, user, password);
             Statement stmt = con.createStatement()) {

            // ⚠️ LA FAILLE EST ICI : Concaténation directe de 'category'
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
        }

        model.addAttribute("products", products);
        model.addAttribute("error", error);

        return "shop";
    }
}