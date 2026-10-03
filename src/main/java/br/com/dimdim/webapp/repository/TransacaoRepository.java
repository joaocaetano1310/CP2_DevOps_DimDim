package br.com.dimdim.webapp.repository;

import br.com.dimdim.webapp.model.Transacao;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TransacaoRepository extends JpaRepository<Transacao, Long> {

    // O Spring monta a consulta pelo nome do metodo: transacoes de um cliente.
    List<Transacao> findByClienteId(Long clienteId);
}
