package com.uphf.HackZone.Controller;

import com.uphf.HackZone.Entity.AttackEntity;
import com.uphf.HackZone.Entity.SolveEntity;
import com.uphf.HackZone.Entity.UserEntity;
import com.uphf.HackZone.Repository.AttackRepository;
import com.uphf.HackZone.Repository.SolveRepository;
import com.uphf.HackZone.Repository.UserRepository;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.Optional;

@Controller
public class GamificationController {
    private final AttackRepository attackRepository;
    private final SolveRepository solveRepository;
    private final UserRepository userRepository;

    public GamificationController(AttackRepository attackRepository, UserRepository userRepository, SolveRepository solveRepository) {
        this.attackRepository = attackRepository;
        this.userRepository = userRepository;
        this.solveRepository = solveRepository;
    }

    @PostMapping("/validate-flag")
    public String validateFlag(@RequestParam String flagInput, org.springframework.ui.Model model) {
        String userMail = SecurityContextHolder.getContext().getAuthentication().getName();
        Optional<UserEntity> userOpt = userRepository.findByUserMail(userMail);

        if (userOpt.isEmpty()) return "redirect:/Auth/login";
        UserEntity user = userOpt.get();

        Optional<AttackEntity> attackOpt = attackRepository.findByFlag(flagInput);

        if (attackOpt.isPresent()) {
            AttackEntity attack = attackOpt.get();

            if (solveRepository.existsByUserIdAndAttId(user.getUserId(), attack.getAttId())) {
                return "redirect:/Home?error=Déja validé ! Petit malin...";
            }

            SolveEntity solveEntity = new SolveEntity(user.getUserId(), attack.getAttId());
            solveRepository.save(solveEntity);

            int nouveauxPoints = user.getPoint() + attack.getPoints();
            user.setPoint(nouveauxPoints);

            updateLevel(user);

            userRepository.save(user);

            return "redirect:/Home?success=Bravo ! Flag correct : + " + attack.getPoints() + " points";
        } else {
            return "redirect:/Home?error=Flag incorrect. Essayer encore !";
        }
    }


    //  c'est ici on gere les niveau
    private void updateLevel(UserEntity user) {
        int p = user.getPoint();

        if (p >= 1500) {
            user.setLevel("avan"); // Avancé
            user.setUserBadge("Master Hacker");
        } else if (p >= 500) {
            user.setLevel("int"); // Intermédiaire
            user.setUserBadge("Script Kiddie");
        } else {
            user.setLevel("deb"); // Débutant
            user.setUserBadge("Novice");
        }
    }
}