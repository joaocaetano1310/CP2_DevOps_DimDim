package br.com.dimdim.webapp.controller;

import br.com.dimdim.webapp.model.Cliente;
import br.com.dimdim.webapp.model.Transacao;
import br.com.dimdim.webapp.repository.ClienteRepository;
import br.com.dimdim.webapp.repository.TransacaoRepository;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/transacoes")
public class TransacaoController {

    private final TransacaoRepository transacaoRepository;
    private final ClienteRepository clienteRepository;

    public TransacaoController(TransacaoRepository transacaoRepository, ClienteRepository clienteRepository) {
        this.transacaoRepository = transacaoRepository;
        this.clienteRepository = clienteRepository;
    }

    // GET /transacoes
    @GetMapping
    public List<Transacao> listar() {
        return transacaoRepository.findAll();
    }

    // GET /transacoes/{id}
    @GetMapping("/{id}")
    public Transacao buscar(@PathVariable Long id) {
        return transacaoRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Transacao nao encontrada"));
    }

    // POST /transacoes   corpo: {"descricao": "...", "valor": 10.50, "cliente": {"id": 1}}
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Transacao criar(@Valid @RequestBody Transacao transacao) {
        transacao.setId(null);
        transacao.setCliente(buscarCliente(transacao.getCliente()));
        if (transacao.getDataHora() == null) {
            transacao.setDataHora(LocalDateTime.now());
        }
        return transacaoRepository.save(transacao);
    }

    // PUT /transacoes/{id}
    @PutMapping("/{id}")
    public Transacao atualizar(@PathVariable Long id, @Valid @RequestBody Transacao dados) {
        Transacao existente = buscar(id);
        existente.setDescricao(dados.getDescricao());
        existente.setValor(dados.getValor());
        existente.setCliente(buscarCliente(dados.getCliente()));
        if (dados.getDataHora() != null) {
            existente.setDataHora(dados.getDataHora());
        }
        return transacaoRepository.save(existente);
    }

    // DELETE /transacoes/{id}
    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void apagar(@PathVariable Long id) {
        transacaoRepository.delete(buscar(id));
    }

    // Confere se o cliente informado existe no banco (senao responde 400).
    private Cliente buscarCliente(Cliente informado) {
        if (informado == null || informado.getId() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Informe cliente.id");
        }
        return clienteRepository.findById(informado.getId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "Cliente informado nao existe"));
    }
}
