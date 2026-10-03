package br.com.dimdim.webapp.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

// Rota simples para testar se a aplicacao subiu: GET /
@RestController
public class HomeController {

    @GetMapping("/")
    public Map<String, String> home() {
        return Map.of("app", "DimDim API", "status", "ok", "rotas", "/clientes  /transacoes");
    }
}
