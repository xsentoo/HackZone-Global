package com.HackZone.TargetApp.Config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity; // <--- IMPORT IMPORTANT
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity // <--- C'EST L'ANNOTATION QUI MANQUAIT !
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                // On désactive la protection CSRF pour que le challenge soit faisable
                .csrf(csrf -> csrf.disable())
                .authorizeHttpRequests(auth -> auth
                        // On autorise l'accès à tout le site sans connexion Spring Security
                        // (Car on gère notre propre login vulnérable)
                        .anyRequest().permitAll()
                );

        return http.build();
    }
}