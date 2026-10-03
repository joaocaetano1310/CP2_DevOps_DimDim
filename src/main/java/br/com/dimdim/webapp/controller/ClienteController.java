package br.com.dimdim.webapp.controller;

import br.com.dimdim.webapp.model.Cliente;
import br.com.dimdim.webapp.model.Transacao;
import br.com.dimdim.webapp.repository.ClienteRepository;
import br.com.dimdim.webapp.repository.TransacaoRepository;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/clientes")
public class ClienteController {

    private final ClienteRepository clienteRepository;
    private final TransacaoRepository transacaoRepository;

    public ClienteController(ClienteRepository clienteRepository, TransacaoRepository transacaoRepository) {
        this.clienteRepository = clienteRepository;
        this.transacaoRepository = transacaoRepository;
    }

    // GET /clientes
    @GetMapping
    public List<Cliente> listar() {
        return clienteRepository.findAll();
    }

    // GET /clientes/{id}
    @GetMapping("/{id}")
    public Cliente buscar(@PathVariable Long id) {
        return clienteRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Cliente nao encontrado"));
    }

    // GET /clientes/{id}/transacoes
    @GetMapping("/{id}/transacoes")
    public List<Transacao> listarTransacoes(@PathVariable Long id) {
        buscar(id); // garante 404 se o cliente nao existir
        return transacaoRepository.findByClienteId(id);
    }

    // POST /clientes
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Cliente criar(@Valid @RequestBody Cliente cliente) {
        cliente.setId(null); // garante que o banco gere o id
        return clienteRepository.save(cliente);
    }

    // PUT /clientes/{id}
    @PutMapping("/{id}")
    public Cliente atualizar(@PathVariable Long id, @Valid @RequestBody Cliente dados) {
        Cliente existente = buscar(id);
        existente.setNome(dados.getNome());
        existente.setEmail(dados.getEmail());
        return clienteRepository.save(existente);
    }

    // DELETE /clientes/{id}
    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void apagar(@PathVariable Long id) {
        clienteRepository.delete(buscar(id));
    }
}
